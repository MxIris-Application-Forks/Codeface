import SwiftUI

struct TreeMap: View
{
    var body: some View
    {        
        RootArtifactContentView(artifact: analysis.selectedArtifact,
                                analysis: analysis)
            .padding(ArtifactViewModel.padding)
            .frame(minWidth: 300, minHeight: 300)
            .background(Color(white: colorScheme == .dark ? 0 : 0.6))
    }
    
    @ObservedObject var analysis: CodebaseAnalysis
    @Environment(\.colorScheme) var colorScheme
}