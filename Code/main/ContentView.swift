import SwiftUI
import AppKit
import SwiftObserver
import SwiftLSP

struct Preview: PreviewProvider
{
    static var previews: some View
    {
        ContentView().previewDisplayName("ContentView")
    }
}

struct ContentView: View
{
    var body: some View
    {
        NavigationView
        {
            List(viewModel.artifacts,
                 children: \.parts,
                 selection: $selectedArtifact)
            {
                artifact in
                
                NavigationLink(tag: artifact,
                               selection: $selectedArtifact)
                {
                    Group
                    {
                        
                        ArtifactContentView(artifact: artifact)
                            .padding(.top)
                        
//                        switch artifact.kind
//                        {
//                        case .file(let codeFile):
//                            TextEditor(text: .constant(codeFile.content))
//                                .font(.system(.body, design: .monospaced))
//                        default:
//                            Text(artifact.displayName)
//                        }
                    }
                    .navigationTitle(artifact.displayName)
                }
                label:
                {
                    Image(systemName: systemImageName(for: artifact.kind))
                        .foregroundColor(iconColor(for: artifact.kind))
                    
                    Text(artifact.displayName)
                        .fixedSize()
                        .font(.system(.title3, design: .for(artifact)))
                    
                    Spacer()
                    
                    if let loc = artifact.metrics?.linesOfCode
                    {
                        Text("\(loc)")
                            .fixedSize()
                            .foregroundColor(locColor(for: artifact))
                            .font(.system(.title3, design: .monospaced))
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }
    
    private func locColor(for artifact: CodeArtifact) -> Color {
        switch artifact.kind {
        case .file:
            return warningColor(for: artifact.metrics?.linesOfCode ?? 0)
        default:
            return Color(NSColor.systemGray)
        }
    }
    
    @StateObject private var viewModel = ContentViewModel()
    @State var selectedArtifact: CodeArtifact?
}

extension Font.Design {
    static func `for`(_ artifact: CodeArtifact) -> Font.Design {
        switch artifact.kind {
        case .symbol: return .monospaced
        default: return .default
        }
    }
}
