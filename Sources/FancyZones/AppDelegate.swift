import Cocoa
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check Permissions
        if !AccessibilityManager.shared.checkAccessibilityTrusted() {
            // Prompt generic alert or just rely on system prompt
            let alert = NSAlert()
            alert.messageText = "Accessibility Permissions Needed"
            alert.informativeText = "FancyZones requires Accessibility permissions to move and resize windows. Please enable them in System Settings."
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Quit")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)
            } else {
                NSApp.terminate(nil)
            }
        }
        
        // Setup Overlay
        OverlayManager.shared.setup()
        
        // Start Input Monitoring
        InputMonitor.shared.startMonitoring()
        
        // Setup Menu Bar
        setupMenuBar()
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "rectangle.grid.3x2", accessibilityDescription: "FancyZones")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Switch Layout", action: #selector(switchLayout), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func switchLayout() {
        OverlayManager.shared.cycleLayout()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
