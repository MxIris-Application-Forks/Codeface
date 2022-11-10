import FoundationToolz
import Foundation

/// The protocol that this service will vend as its API. This protocol will also need to be visible to the process hosting the service (the main app).
@objc protocol LSPXPCServiceExportedInterface
{
    func launchExecutable(withEncodedConfig: Data,
                          with reply: @escaping (String) -> Void)
}
