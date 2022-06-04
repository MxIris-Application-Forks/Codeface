import LSPServiceKit
import SwiftLSP
import FoundationToolz
import Foundation
import SwiftObserver
import SwiftyToolz

@MainActor
class Project
{
    // MARK: - Initialization
    
    init(config: Configuration) throws
    {
        guard FileManager.default.itemExists(config.folder) else
        {
            throw "Project folder does not exist: " + config.folder.absoluteString
        }
        
        self.config = config
    }
    
    // MARK: - Data Analysis
    
    func startAnalysis() throws
    {
        Task
        {
            self.analysisResult = .isAnalyzing
            
            do
            {
                let rootFolder = try createRootFolder()
                let rootArtifact = CodeArtifact(codeFolder: rootFolder, scope: nil)
                await tryToAddSymbolArtifacts(to: rootArtifact)
                rootArtifact.generateMetrics()
                rootArtifact.sort()
                self.analysisResult = .success(rootArtifact)
            }
            catch
            {
                self.analysisResult = .failure(error.readable.message)
                throw error
            }
        }
    }
    
    private func createRootFolder() throws -> CodeFolder
    {
        try config.folder.mapSecurityScoped
        {
            guard let codeFolder = try CodeFolder($0, codeFileEndings: config.codeFileEndings) else
            {
                throw "Project folder contains no code files with the specified file endings\nFolder: \($0.absoluteString)\nFile endings: \(config.codeFileEndings)"
            }
            
            return codeFolder
        }
    }
    
    private func tryToAddSymbolArtifacts(to artifact: CodeArtifact) async
    {
        do
        {
            let (server, initialization) = try getServerAndServerInitialization()
            try await initialization.assumeSuccess()
            try await artifact.addSymbolArtifacts(using: server)
        }
        catch
        {
            log(warning: "Cannot retrieve code file symbols from LSP server:\n" + error.readable.message)
        }
    }
    
    @Observable private(set) var analysisResult: AnalysisResult = .none
    
    enum AnalysisResult: Equatable
    {
        static func == (lhs: Project.AnalysisResult, rhs: Project.AnalysisResult) -> Bool
        {
            if case .none = lhs, case .none = rhs { return true }
            
            if case .isAnalyzing = lhs, case .isAnalyzing = rhs { return true }
            
            if case .success(let artifact1) = lhs,
                case .success(let artifact2) = rhs { return artifact1 == artifact2 }
            
            if case .failure(let message1) = lhs,
                case .failure(let message2) = rhs { return message1 == message2 }
            
            return false
        }
        
        // success: artifact hierarchy, each artifact with code content, kind, dependencies & metrics
        case none, isAnalyzing, success(CodeArtifact), failure(String)
    }
    
    // MARK: - Language Server
    
    private func getServerAndServerInitialization() throws -> (LSP.ServerCommunicationHandler, Task<Void, Error>)
    {
        if let server = server, let initialization = serverInitialization
        {
            return (server, initialization)
        }
        
        let createdServer = try Self.createServer(language: config.language)
        server = createdServer
        
        let createdInitialization = Self.initialize(createdServer, for: config)
        serverInitialization = createdInitialization
        
        return (createdServer, createdInitialization)
    }
    
    private static func createServer(language: String) throws -> LSP.ServerCommunicationHandler
    {
        let server = try LSPService.api.language(language.lowercased()).connectToLSPServer()
        
        server.serverDidSendNotification =
        {
            notification in
            
//            log("Server sent notification:\n\(notification.method)\n\(notification.params?.description ?? "nil params")")
        }

        server.serverDidSendErrorOutput =
        {
            _ in // log(warning: "Language server sent error string:\n\($0)")
        }
        
        return server
    }
    
    private static func initialize(_ server: LSP.ServerCommunicationHandler,
                                   for project: Configuration) -> Task<Void, Error>
    {
        Task
        {
            let processID = try await LSPService.api.processID.get()
            
            let _ = try await server.request(.initialize(folder: project.folder,
                                                         clientProcessID: processID))
            
//            try log(initializeResult: initializeResult)
            
            try server.notify(.initialized)
        }
    }
    
    private var serverInitialization: Task<Void, Error>? = nil
    private var server: LSP.ServerCommunicationHandler? = nil
    
    // MARK: - Configuration
    
    private let config: Configuration
    
    struct Configuration: Codable
    {
        var folder: URL
        let language: String
        let codeFileEndings: [String]
    }
}

extension Task where Success == Void
{
    func assumeSuccess() async throws { try await value }
}
