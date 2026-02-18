import Cocoa
import ApplicationServices

@MainActor
class AccessibilityManager {
    static let shared = AccessibilityManager()
    
    private init() {}
    
    func checkAccessibilityTrusted() -> Bool {
        let promptKey = getAXTrustedCheckOptionPrompt()
        let options: NSDictionary = [promptKey as String : true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        if !trusted {
            print("Accessibility permissions not granted. Prompting user...")
        }
        
        return trusted
    }
}

// Helper to avoid Swift 6 concurrency error with kAXTrustedCheckOptionPrompt
private nonisolated func getAXTrustedCheckOptionPrompt() -> String {
    return "AXTrustedCheckOptionPrompt"
}
