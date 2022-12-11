import SwiftUI

struct ProofOfConceptView: View
{
    var body: some View
    {
        NavigationSplitView(columnVisibility: $columnVisibility)
        {
            List(Item.all, selection: $selectedItem)
            {
                NavigationLink($0.name, value: $0)
            }
        }
        detail:
        {
            InspectorView(showsInspector: $showsInspector)
                .animation(.default, value: selectedItem)
        }
        .onAppear {
            Task {
                selectedItem = .all.first
            }
        }
    }

    @State var selectedItem: Item? = nil
    
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var showsInspector: Bool
}

struct InspectorView: View {

    var body: some View {
        
        GeometryReader { geo in
            
            HStack(spacing: 0) {
                
                //Main
                VStack {
                    Spacer()
                    
                    Text("Content goes here")
                        .font(.title)
                        .padding()
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Inspector
                HStack(spacing: 0) {
                    Divider()
                        .frame(minWidth: 0)
                    
                    List {
                        Text("Inspector Element 1")
                        Text("Inspector Element 2")
                        Text("Inspector Element 3")
                        Text("Inspector Element 4")
                        Text("Inspector Element 5")
                    }
                    .focusable(false)
                    .listStyle(.sidebar)
                }
                .frame(width: showsInspector ? max(250, geo.size.width / 4) : 0)
                .opacity(showsInspector ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                // TODO: fext field in toolbar does not recognize its focus ...
                SearchField()
                
                Button {
                    withAnimation {
                        showsInspector.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.right")
                }
            }
        }
    }
    
    @Binding var showsInspector: Bool
}

struct Item: Hashable, Identifiable
{
    static let all: [Item] =
    [
        .init(name: "Item 1",
              text: "If you select Item 2, then this content will animate into ...",
             subitems: [0, 1, 3, 4, 6, 7, 9, 10, 12]),
        .init(name: "Item 2",
              text: "... this one because both are in a structurally identical view.",
             subitems: [0, 2, 3, 5, 6, 8, 9, 11, 12])
    ]
    
    let id = UUID()
    let name: String
    let text: String
    let subitems: [Int]
}