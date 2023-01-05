import Foundation
import SwiftNodes

final class CodeFolderArtifact: Identifiable, Sendable
{
    init(name: String, scope: (any CodeArtifact)?)
    {
        self.name = name
        self.scope = scope
    }

    // MARK: - Graph Structure
    
    weak var scope: (any CodeArtifact)?
    var partGraph = Graph<CodeArtifact.ID, Part>()
    
    class Part: CodeArtifact, Identifiable, Hashable
    {
        // MARK: Hashability
        
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
        static func == (lhs: Part, rhs: Part) -> Bool { lhs.id == rhs.id }
        
        // MARK: CodeArtifact Protocol
        
        var metrics: Metrics
        {
            get { codeArtifact.metrics }
            set { codeArtifact.metrics = newValue }
        }
        
        func addPartDependency(from sourceID: ID, to targetID: ID)
        {
            codeArtifact.addPartDependency(from: sourceID, to: targetID)
        }
        
        var intrinsicSizeInLinesOfCode: Int?
        {
            codeArtifact.intrinsicSizeInLinesOfCode
        }
        
        func sort() { codeArtifact.sort() }
        var parts: [any CodeArtifact] { codeArtifact.parts }
        var scope: (any CodeArtifact)? { codeArtifact.scope }
        var name: String { codeArtifact.name }
        var kindName: String { codeArtifact.kindName }
        var code: String? { codeArtifact.code }
        var id: String { codeArtifact.id }
        
        // MARK: Actual Artifact
        
        var codeArtifact: any CodeArtifact
        {
            switch kind
            {
            case .file(let file): return file
            case .subfolder(let subfolder): return subfolder
            }
        }
        
        init(kind: Kind) { self.kind = kind }
        
        let kind: Kind
        
        enum Kind
        {
            case subfolder(CodeFolderArtifact), file(CodeFileArtifact)
        }
    }
    
    // MARK: - Basics
    
    let id = UUID().uuidString
    let name: String
}
