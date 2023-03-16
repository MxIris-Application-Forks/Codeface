import SwiftUI
import SwiftyToolz

struct LogView: View
{
    var body: some View
    {
        VStack(alignment: .leading, spacing: 0)
        {
            ZStack
            {
                List
                {
                    Text("Internal Logs")
                        .font(.title2)
                    
                    ForEach(logViewModel.logEntries.indices, id: \.self)
                    {
                        let entry = logViewModel.logEntries[$0]
                        
                        Label
                        {
                            VStack(alignment: .leading)
                            {
                                Text(entry.message)
                                
                                Text(entry.context)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: Self.systemImageName(for: entry))
                                .foregroundColor(Self.imageColor(for: entry))
                        }
                    }
                }
                
                VStack
                {
                    Spacer()
                    
                    HStack
                    {
                        Spacer()
                        
                        Button {
                            logViewModel.clear()
                        } label: {
                            Label("Clear", systemImage: "trash")
                        }
                        .padding()
                    }
                }
            }
        }
    }
    
    private static func systemImageName(for entry: Log.Entry) -> String
    {
        switch entry.level
        {
        case .error: return "xmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .verbose: return "info.circle"
        }
    }
    
    private static func imageColor(for entry: Log.Entry) -> SwiftUI.Color
    {
        switch entry.level
        {
        case .error: return .red
        case .warning: return .yellow
        case .info: return .green
        case .verbose: return .secondary
        }
    }
    
    @StateObject private var logViewModel = LogViewModel()
}

@MainActor
class LogViewModel: ObservableObject
{
    init()
    {
        Log.shared.add(observer: self)
        {
            [weak self] entry in
            
            Task
            {
                await MainActor.run
                {
                    self?.logEntries.append(entry)
                }
            }
        }
    }
    
    func clear()
    {
        logEntries.removeAll()
    }
    
    @Published var logEntries = [Log.Entry]()
}
