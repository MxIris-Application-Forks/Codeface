import SwiftUIToolzOLD
import SwiftUI
import CodefaceCore
import LSPServiceKit
import SwiftLSP
import SwiftyToolz

@main
struct CodefaceApp: App
{
    init()
    {
        ReadableError.readableMessageForError = { $0.localizedDescription }
    }
    
    var body: some Scene
    {
        DocumentGroup(newDocument: CodebaseFileDocument())
        {
            CodefaceDocumentView(codebaseFile: $0.$document,
                                 sidebarViewModel: sidebarViewModel)
                .sheet(isPresented: $isPresentingCodebaseLocator)
                {
                    CodebaseLocatorView(isBeingPresented: $isPresentingCodebaseLocator)
                    {
                        focusedDocument?.loadNewProcessor(forCodebaseFrom: $0)
                    }
                    .padding()
                }
                .toolbar
                {
                    ToolbarItemGroup(placement: ToolbarItemPlacement.secondaryAction)
                    {
                        Button
                        {
                            withAnimation(.easeInOut(duration: SearchVM.toggleAnimationDuration))
                            {
                                focusedDocument?.projectProcessorVM?.toggleSearchBar()
                            }
                        }
                        label:
                        {
                            Image(systemName: "magnifyingglass")
                        }
                        .help("Toggle the search filter (⇧⌘F)")
                        .focusable(false)
                        
                        DisplayModePicker(displayMode: .init(get: {
                            focusedDocument?.projectProcessorVM?.displayMode ?? .code
                        }, set: { newValue in
                            focusedDocument?.projectProcessorVM?.displayMode = newValue
                        }))
                    }
                }
        }
        .commands
        {
            SidebarCommands()

            CommandGroup(replacing: .sidebar)
            {
                Button("Switch to Next Display Mode")
                {
                    focusedDocument?.switchDisplayMode()
                }
                .disabled(focusedDocument?.projectProcessorVM == nil)
                .keyboardShortcut(.rightArrow, modifiers: .command)
                
                Button("Switch to Previous Display Mode")
                {
                    focusedDocument?.switchDisplayMode()
                }
                .disabled(focusedDocument?.projectProcessorVM == nil)
                .keyboardShortcut(.leftArrow, modifiers: .command)
                
                Divider()

                Button("\(sidebarViewModel.showsLeftSidebar ? "Hide" : "Show") Navigator")
                {
                    withAnimation
                    {
                        sidebarViewModel.showsLeftSidebar.toggle()
                    }
                }
                .keyboardShortcut("0", modifiers: .command)
                
                // FIXME: the following commands are only available when there is a projectProcessorVM, i.e. when some artifact is selected, but apparently focusedDocument as a @FocusedValue is not being observed! so the button disabling does not work.
                
                Button("\(sidebarViewModel.showsRightSidebar ? "Hide" : "Show") Inspector")
                {
                    withAnimation
                    {
                        sidebarViewModel.showsRightSidebar.toggle()
                    }
                }
//                .disabled(focusedDocument?.projectProcessorVM == nil)
                .keyboardShortcut("0", modifiers: [.option, .command])
                
                Divider()
                
                Button("Find and filter")
                {
                    withAnimation(.easeInOut(duration: SearchVM.toggleAnimationDuration))
                    {
                        focusedDocument?.projectProcessorVM?.startTypingSearchTerm()
                    }
                }
//                .disabled(focusedDocument?.projectProcessorVM == nil)
                .keyboardShortcut("f", modifiers: .command)
                
                Button("Toggle the search filter")
                {
                    withAnimation(.easeInOut(duration: SearchVM.toggleAnimationDuration))
                    {
                        focusedDocument?.projectProcessorVM?.toggleSearchBar()
                    }
                }
//                .disabled(focusedDocument?.projectProcessorVM == nil)
                .keyboardShortcut("f", modifiers: [.shift, .command])
                
                Divider()
            }
            
            CommandGroup(replacing: .help)
            {
                HelpLink.lspService
                
                HelpLink.documentation
            }
            
            CommandGroup(replacing: .newItem)
            {
                Button("New Empty Codebase File") {
                    NSDocumentController.shared.newDocument(nil)
                }
                .keyboardShortcut("n")
                
                Button("Open a Codebase File ...") {
                    NSDocumentController.shared.openDocument(nil)
                }
                .keyboardShortcut("o")
                
                // TODO: Bring back menu item "Open Recent" programmatically!
            }
            
            CommandGroup(before: .undoRedo)
            {
                Button("Import Code Folder...")
                {
                    isPresentingCodebaseLocator = true
                }
                .disabled(focusedDocument == nil)
                
                Button("Import Swift Package Folder...")
                {
                    isPresentingFolderImporter = true
                }
                .disabled(focusedDocument == nil)
                .fileImporter(isPresented: $isPresentingFolderImporter,
                              allowedContentTypes: [.directory],
                              allowsMultipleSelection: false)
                {
                    guard let folderURL = (try? $0.get())?.first else
                    {
                        return log(error: "Could not select code folder")
                    }
                    
                    focusedDocument?.loadProcessorForSwiftPackage(from: folderURL)
                }
                
                Button("Import \(lastFolderName) Again")
                {
                    focusedDocument?.loadProcessorForLastCodebase()
                }
                .keyboardShortcut("r")
                .disabled(focusedDocument == nil || !CodebaseLocationPersister.hasPersistedLastCodebaseLocation)

                Divider()
            }
            
            #if DEBUG
            CommandMenu("Develop")
            {
                Button("Clear Selection")
                {
                    focusedDocument?.selectedArtifact = nil
                }
                
                Button("Test XPC Service With Last Codebase")
                {
//                    ProcessServiceTest.run()
//                    XPCExecutable.testForCodeface()
                }
                .keyboardShortcut("t")
                .disabled(true)
            }
            #endif
        }
    }
    
    private var lastFolderName: String
    {
        CodebaseLocationPersister.cachedLocation?.folder.lastPathComponent ?? "Last Folder"
    }
    
    // MARK: - Load Codebase from Folder
    
    @State private var isPresentingCodebaseLocator = false
    @State private var isPresentingFolderImporter = false
    
    // MARK: - Basics
    
    @StateObject var sidebarViewModel = DoubleSidebarViewModel()
    
    @FocusedValue(\.document) var focusedDocument: CodefaceDocument?
}