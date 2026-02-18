import Cocoa
import SwiftUI
import FancyZonesCore

@MainActor
class OverlayManager: InputMonitorDelegate {
    static let shared = OverlayManager()
    
    private var panel: OverlayPanel?
    private var currentLayout: ZoneLayout
    private var layouts: [ZoneLayout] = []
    private var activeZoneIndex: Int?
    
    private init() {
        // Load layouts or fallback to defaults
        let loaded = LayoutRepository.shared.getAllLayouts()
        self.layouts = loaded
        self.currentLayout = loaded.first ?? ZoneLayout.wideCenter
    }
    
    func setup() {
        // Create panel covering the main screen
        guard let screen = NSScreen.main else { return }
        let panelRect = screen.frame
        
        let newPanel = OverlayPanel(contentRect: panelRect, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        self.panel = newPanel
        
        InputMonitor.shared.delegate = self
        
        updateView()
    }
    
    // MARK: - InputMonitorDelegate
    
    func didUpdateMouseLocation(_ location: NSPoint) {
        guard let screen = NSScreen.main else { return }
        
        // Use ZoneEngine to normalize mouse position and hit-test zones
        let layoutPoint = zoneEngine.normalizedLayoutPoint(
            mouseLocation: location,
            screenFrame: screen.frame
        )
        let foundIndex = zoneEngine.activeZoneIndex(for: layoutPoint, in: currentLayout)
        
        if foundIndex != activeZoneIndex {
            activeZoneIndex = foundIndex
            updateView()
        }
    }
    
    func didEndDrag() {
        if let index = activeZoneIndex {
            // Snap Window!
            if let window = WindowManager.shared.getWindowUnderCursor() {
                let zone = currentLayout.zones[index]
                WindowManager.shared.moveWindow(window, to: zone.rect, spacing: currentLayout.spacing)
            }
        }
        activeZoneIndex = nil
        updateView()
    }
    
    func activateOverlay() {
        panel?.orderFront(nil)
    }
    
    func deactivateOverlay() {
        panel?.orderOut(nil)
        activeZoneIndex = nil
        updateView()
    }
    
    func shouldActivateOverlay() -> Bool {
        return true
    }
    
    private func updateView() {
        guard let panel = panel else { return }
        
        let view = ZoneOverlayView(layout: currentLayout, activeZoneIndex: activeZoneIndex)
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(origin: .zero, size: panel.frame.size)
        // Ensure transparent background
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        
        panel.contentView = hostingView
    }
    
    func cycleLayout() {
        guard let currentIndex = layouts.firstIndex(where: { $0.name == currentLayout.name }) else {
            currentLayout = layouts.first ?? ZoneLayout.wideCenter
            updateView()
            return
        }
        
        let nextIndex = (currentIndex + 1) % layouts.count
        currentLayout = layouts[nextIndex]
        
        updateView()
        print("Switched layout to: \(currentLayout.name)")
    }
    
    func reloadLayouts() {
        let loaded = LayoutRepository.shared.getAllLayouts()
        self.layouts = loaded
        // Keep current if exists, else reset
        if !layouts.contains(where: { $0.name == currentLayout.name }) {
            currentLayout = layouts.first ?? ZoneLayout.wideCenter
        }
        updateView()
    }
}
