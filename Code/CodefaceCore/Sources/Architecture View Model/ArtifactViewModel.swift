import SwiftLSP
import Foundation
import SwiftyToolz

extension ArtifactViewModel: Hashable
{
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
}

@MainActor
public class ArtifactViewModel: Identifiable, ObservableObject, Equatable
{
    public nonisolated static func == (lhs: ArtifactViewModel,
                                       rhs: ArtifactViewModel) -> Bool
    {
        lhs === rhs
    }
    
    // MARK: - Initialization
    
    public init(folderArtifact: CodeFolderArtifact, isPackage: Bool)
    {
        // create child presentations for parts recursively
        self.parts = folderArtifact.partGraph.values.map
        {
            switch $0.kind
            {
            case .file(let file): return .init(fileArtifact: file)
            case .subfolder(let subfolder): return .init(folderArtifact: subfolder,
                                                         isPackage: false)
            }
        }
        
        if isPackage
        {
            iconSystemImageName = "shippingbox.fill"
            iconFillColor = .dynamic(.in(light: .bytes(167, 129, 79),
                                         darkness: .bytes(193, 156, 106)))
        }
        else
        {
            iconSystemImageName = "folder.fill"
            iconFillColor = .dynamic(.in(light: .bytes(19, 165, 235),
                                         darkness: .bytes(83, 168, 209)))
        }
        
        linesOfCodeColor = .system(.gray)
        
        kind = .folder(folderArtifact)
    }
    
    private init(fileArtifact: CodeFileArtifact)
    {
        // create child presentations for symbols recursively
        self.parts = fileArtifact.symbolGraph.values.map
        {
            ArtifactViewModel(symbolArtifact: $0)
        }
        
        if fileArtifact.name.hasSuffix(".swift")
        {
            iconSystemImageName = "swift"
            iconFillColor = .rgba(.bytes(251, 139, 57))
        }
        else
        {
            iconSystemImageName = "doc.fill"
            iconFillColor = .rgba(.white)
        }
            
        linesOfCodeColor = .system(systemColor(forLinesOfCode: fileArtifact.linesOfCode))
        
        kind = .file(fileArtifact)
    }
    
    private init(symbolArtifact: CodeSymbolArtifact)
    {
        // create child presentations for subsymbols recursively
        self.parts = symbolArtifact.subsymbolGraph.values.map
        {
            ArtifactViewModel(symbolArtifact: $0)
        }
        
        self.iconSystemImageName = symbolIconSystemImageName(for: symbolArtifact.kind)
        self.iconFillColor = symbolIconFillColor(for: symbolArtifact.kind)
        linesOfCodeColor = .system(.gray)
        
        kind = .symbol(symbolArtifact)
    }
    
    // MARK: - Search
    
    @Published public var passesSearchFilter = true
    
    public var containsSearchTermRegardlessOfParts: Bool?
    var partsContainSearchTerm: Bool?
    
    // MARK: - Name
    
    public var displayName: String
    {
        collapseHorizontally ? "" : codeArtifact.name
    }
    
    // MARK: - Geometry
    
    public var headerFrame: Frame
    {
        .init(centerX: frameInScopeContent.width / 2 + (extraSpaceForTitles / 2),
              centerY: collapseVertically ? frameInScopeContent.height / 2 : Self.padding + fontSize / 2,
              width: frameInScopeContent.width - 2 * Self.padding + extraSpaceForTitles,
              height: collapseVertically ? frameInScopeContent.height - 2 * Self.padding : fontSize)
    }
    
    public var extraSpaceForTitles: Double { collapseHorizontally ? 0 : 6.0 }
    
    public var showsName: Bool
    {
        frameInScopeContent.width - (2 * Self.padding + fontSize) >= 3 * fontSize
    }
    
    public var collapseHorizontally: Bool { frameInScopeContent.width <= fontSize + (2 * Self.padding) }
    
    public var collapseVertically: Bool { frameInScopeContent.height <= fontSize + (2 * Self.padding) }
    
    public var fontSize: Double
    {
        let viewSurface = frameInScopeContent.height * frameInScopeContent.width
        return 3 * pow(viewSurface, (1 / 6.0))
    }
    
    public static var padding: Double = 16
    public static var minWidth: Double = 30
    public static var minHeight: Double = 30
    
    @Published public var frameInScopeContent = Frame.zero
    
    public var showsContent = true
    public var contentFrame = Frame.zero
    
    public var gapBetweenParts: Double = 0
    
    // MARK: - Colors & Symbols
    
    @Published public var isInFocus = false
    
    public let iconSystemImageName: String
    public let iconFillColor: UXColor
    public let linesOfCodeColor: UXColor
    
    // MARK: - Basics
    
    public var partDependencies = [DependencyVM]()
    public let parts: [ArtifactViewModel]
    
    public nonisolated var id: String { codeArtifact.id }
    
    public nonisolated var codeArtifact: any SearchableCodeArtifact
    {
        switch kind
        {
        case .file(let file): return file
        case .folder(let folder): return folder
        case .symbol(let symbol): return symbol
        }
    }
    
    public let kind: Kind
    
    public enum Kind
    {
        case folder(CodeFolderArtifact),
             file(CodeFileArtifact),
             symbol(CodeSymbolArtifact)
    }
}

public class DependencyVM: ObservableObject, Identifiable
{
    internal init(sourcePart: ArtifactViewModel,
                  targetPart: ArtifactViewModel,
                  weight: Int) {
        self.sourcePart = sourcePart
        self.targetPart = targetPart
        self.weight = weight
    }
    
    public let id = UUID()
    
    public let sourcePart: ArtifactViewModel
    @Published public var sourcePoint: Point = .zero
    
    public let targetPart: ArtifactViewModel
    @Published public var targetPoint: Point = .zero
    
    public let weight: Int
}

private func symbolIconSystemImageName(for symbolKind: LSPDocumentSymbol.SymbolKind?) -> String
{
    guard let symbolKind = symbolKind else
    {
        return "questionmark.square.fill"
    }
    
    switch symbolKind
    {
    case .File:
        return "doc.fill"
    case .Module, .Package:
        return "shippingbox.fill"
    case .Null:
        return "square.fill"
    default:
        if let firstCharacter = symbolKind.name.first?.lowercased()
        {
            return firstCharacter + ".square.fill"
        }
        else
        {
            return "questionmark.square.fill"
        }
    }
}

private func symbolIconFillColor(for symbolKind: LSPDocumentSymbol.SymbolKind?) -> UXColor
{
    guard let symbolKind = symbolKind else
    {
        return .system(.secondaryLabel)
    }
    
    switch symbolKind
    {
    case .File, .Module, .Package:
        return .rgba(.white)
    case .Class, .Interface, .Struct:
        return .system(.purple)
    case .Namespace, .Enum:
        return .system(.orange)
    case .Method, .Constructor:
        return .system(.blue)
    case .Property, .Field, .EnumMember:
        return .system(.teal)
    case .Variable, .Constant, .Function, .Operator:
        return .system(.green)
    case .Number, .Boolean, .Array, .Object, .Key, .Null, .Event, .TypeParameter, .String:
        return .system(.secondaryLabel)
    }
}

private func systemColor(forLinesOfCode linesOfCode: Int) -> UXColor.System
{
    if linesOfCode < 100 { return .green }
    else if linesOfCode < 200 { return .yellow }
    else if linesOfCode < 300 { return .orange }
    else { return .red }
}