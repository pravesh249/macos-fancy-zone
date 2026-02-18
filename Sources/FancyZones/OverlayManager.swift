import Cocoa
import SwiftUI
import FancyZonesCore

@MainActor
class OverlayManager: InputMonitorDelegate {
    static let shared = OverlayManager()
    
    private var panel: OverlayPanel?
    private var currentLayout: ZoneLayout = ZoneLayout.wideCenter
    private var activeZoneIndex: Int?
    
    private init() {}
    
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
        switch currentLayout.name {
        case ZoneLayout.priorityGrid.name:
            currentLayout = ZoneLayout.threeColumn
        case ZoneLayout.threeColumn.name:
            currentLayout = ZoneLayout.twoByTwo
        case ZoneLayout.twoByTwo.name:
            currentLayout = ZoneLayout.wideCenter
        default:
            currentLayout = ZoneLayout.priorityGrid
        }
        updateView()
        print("Switched layout to: \(currentLayout.name)")
    }
}
