import SwiftUI
import CodefaceCore

struct CodefaceDocumentContentView: View
{
    var body: some View
    {
        if let processorVM = codefaceDocument.projectProcessorVM
        {
            ContentNavigationView(codefaceDocument: codefaceDocument,
                                  processorVM: processorVM)
        }
        else
        {
            VStack
            {
                Spacer()
                HStack
                {
                    Spacer()
                    Text("This is an empty codebase file.\nImport a code folder via the Edit menu.")
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
                LSPServiceHint()
                    .padding()
                Spacer()
            }
        }
    }
    
    @ObservedObject var codefaceDocument: CodefaceDocument
}
