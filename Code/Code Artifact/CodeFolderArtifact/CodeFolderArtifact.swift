import Foundation

extension CodeFolderArtifact: CodeArtifact
{
    var name: String { codeFolderURL.lastPathComponent }
    var kindName: String { "Folder" }
    var code: String? { nil }
}

@MainActor
class CodeFolderArtifact: Identifiable, ObservableObject
{
    init(codeFolder: CodeFolder, scope: CodeFolderArtifact?)
    {
        self.codeFolderURL = codeFolder.url
        self.scope = scope
        
        self.subfolders = codeFolder.subfolders.map
        {
            CodeFolderArtifact(codeFolder: $0, scope: self)
        }
        
        self.files = codeFolder.files.map
        {
            CodeFileArtifact(codeFile: $0, scope: self)
        }
    }
    
    // Mark: - Metrics
    
    var metrics = Metrics()
    
    // Mark: - Tree Structure
    
    weak var scope: CodeFolderArtifact?
    
    var subfolders = [CodeFolderArtifact]()
    var files = [CodeFileArtifact]()
    
    // Mark: - Basics
    
    let id = UUID().uuidString
    let codeFolderURL: URL
}
