import Cocoa
import SwiftUI
import FancyZonesCore

class SettingsWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "FancyZones Settings"
        window.center()
        
        // Create the SwiftUI view for settings
        let contentView = SettingsView()
        window.contentView = NSHostingView(rootView: contentView)
        
        self.init(window: window)
    }
}

struct SettingsView: View {
    var body: some View {
        TabView {
            LayoutEditorView()
                .tabItem {
                    Label("Layout Editor", systemImage: "square.grid.3x2")
                }
            
            Text("General Settings Placeholder")
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }
}
