import SwiftUIToolz
import SwiftUI
import AppKit
import CodefaceCore
import SwiftObserver
import SwiftLSP

struct ProjectAnalysisView: View
{
    var body: some View
    {
        NavigationView
        {
            Sidebar(viewModel: viewModel)
                .toolbar
            {
                ToolbarItemGroup(placement: .primaryAction)
                {
                    Button(action: toggleSidebar)
                    {
                        Image(systemName: "sidebar.leading")
                    }
                    
                    if case .succeeded = viewModel.analysisState
                    {
                        Spacer()
                        
                        Button(action: { viewModel.loadLastActiveProject() })
                        {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .searchable(text: $searchTerm,
                        placement: .toolbar,
                        prompt: searchPrompt)
            .onSubmit(of: .search)
            {
                viewModel.submitSearch()
            }
            
            switch viewModel.analysisState
            {
            case .failed, .stopped, .running:
                EmptyView()
            case .succeeded(let rootArtifactPresentation):
                Label("Select a code artifact from \(rootArtifactPresentation.codeArtifact.name)",
                      systemImage: "arrow.left")
                .padding()
                .font(.system(.title))
                .foregroundColor(.secondary)
            }
        }
        .onReceive(viewModel.$isSearching)
        {
            if $0 { searchTerm = viewModel.appliedSearchTerm ?? "" }
        }
        .onChange(of: searchTerm)
        {
            newSearchTerm in
            
            withAnimation(.easeInOut)
            {
                viewModel.userChanged(searchTerm: newSearchTerm)
            }
        }
    }
    
    private var searchPrompt: String
    {
        "Search in \(viewModel.selectedArtifact?.codeArtifact.name ?? "Selected Artifact")"
    }
    
    @State var searchTerm = ""
    
    @ObservedObject var viewModel: ProjectAnalysisViewModel
}
