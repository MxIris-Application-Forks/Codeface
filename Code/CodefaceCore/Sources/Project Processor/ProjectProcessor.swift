import LSPServiceKit
import Foundation
import Combine
import SwiftyToolz

public actor ProjectProcessor: ObservableObject
{
    // MARK: - Initialize
    
    public init(projectLocation: ProjectLocation) throws
    {
        guard FileManager.default.itemExists(projectLocation.folder) else
        {
            throw "Project folder does not exist: " + projectLocation.folder.absoluteString
        }
        
        self.projectLocation = projectLocation
    }
    
    // MARK: - Run Processing
    
    public func run() async
    {
        state = .running(.readFolder)
        guard let projectData = readRootFolder() else { return }
        
        do
        {
            state = .running(.connectToLSPServer)
            let server = try await LSPServerManager.shared.getServer(for: projectLocation)
            
            state = .running(.retrieveSymbols)
            try await projectData.retrieveSymbolData(from: server)
            
            state = .running(.retrieveReferences)
            try await projectData.retrieveSymbolReferences(from: server)
        }
        catch
        {
            log(warning: "Cannot talk to LSP server: " + error.readable.message)
            LSPServerManager.shared.serverIsWorking = false
        }
        
        // we have the project data. now we build a project-/architecture description
        let projectArchitecture = generateProjectArchitecture(from: projectData)
        
        // arguably, here begins the project analysis
        state = .running(.calculateCrossScopeDependencies)
        projectArchitecture.addCrossScopeDependencies()
        
        state = .running(.calculateMetrics)
        projectArchitecture.calculateSizeMetricsRecursively()
        projectArchitecture.recursivelyPruneDependenciesAndCalculateDependencyMetrics()
        projectArchitecture.calculateCycleMetricsRecursively()
        
        // here begins the project visualization
        state = .running(.sortCodeArtifacts)
        projectArchitecture.traverseDepthFirst { $0.sort() }
        
        state = .running(.createViewModels)
        
        let rootVM = await ArtifactViewModel(folderArtifact: projectArchitecture,
                                             isPackage: projectData.looksLikeAPackage).addDependencies()
        
        state = .succeeded(rootVM)
    }
    
    private func readRootFolder() -> CodeFolder?
    {
        do
        {
            return try projectLocation.folder.mapSecurityScoped
            {
                guard let codeFolder = try CodeFolder($0, codeFileEndings: projectLocation.codeFileEndings) else
                {
                    throw "Project folder contains no code files with the specified file endings\nFolder: \($0.absoluteString)\nFile endings: \(projectLocation.codeFileEndings)"
                }
                
                return codeFolder
            }
        }
        catch
        {
            log(error.readable.message)
            state = .failed(error.readable.message)
            return nil
        }
    }
    
    private func generateProjectArchitecture(from projectData: CodeFolder) -> CodeFolderArtifact
    {
        state = .running(.generateArchitecture)
        
        var symbolDataHash = [CodeSymbolArtifact: CodeSymbolData]()
        
        let rootArtifact = CodeFolderArtifact(codeFolder: projectData,
                                              scope: nil,
                                              symbolDataHash: &symbolDataHash)
        
        rootArtifact.addSymbolDependencies(symbolDataHash: symbolDataHash)
        
        symbolDataHash.removeAll()
        
        return rootArtifact
    }
    
    // MARK: - Publish State
    
    @Published public private(set) var state: State = .stopped
    
    public enum State: Equatable
    {
        case stopped,
             running(Step),
             succeeded(ArtifactViewModel),
             failed(String)
        
        public enum Step: String, Equatable
        {
            case readFolder = "Reading raw data drom project folder",
                 connectToLSPServer = "Connecting to LSP server",
                 retrieveSymbols = "Retrieving symbols from LSP server",
                 retrieveReferences = "Retrieving symbol references from LSP server",
                 generateArchitecture = "Generating project architecture",
                 calculateCrossScopeDependencies = "Calculating dependencies across scopes",
                 calculateMetrics = "Calculating metrics",
                 sortCodeArtifacts = "Sorting code artifacts",
                 createViewModels = "Generating code artifact view models"
        }
    }
    
    // MARK: - Configure
    
    public let projectLocation: ProjectLocation
}
