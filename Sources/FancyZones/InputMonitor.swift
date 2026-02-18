import Cocoa

@MainActor
protocol InputMonitorDelegate: AnyObject {
    func didUpdateMouseLocation(_ location: NSPoint)
    func didEndDrag()
    func shouldActivateOverlay() -> Bool
    func activateOverlay()
    func deactivateOverlay()
}

@MainActor
class InputMonitor {
    static let shared = InputMonitor()
    
    weak var delegate: InputMonitorDelegate?
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isDragging = false
    
    private init() {}
    
    func startMonitoring() {
        // Monitor for Left Mouse Dragged globally
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .flagsChanged, .leftMouseUp]) { [weak self] event in
            self?.handleEvent(event)
        }
        
        // Also need local monitor if we want to test within the app (though this app is mostly background)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged, .flagsChanged, .leftMouseUp]) { [weak self] event in
            self?.handleEvent(event)
            return event
        }
    }
    
    func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
    
    private func handleEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDragged:
            // Check for modifiers (Shift or Option)
            let flags = event.modifierFlags
            if flags.contains(.shift) || flags.contains(.option) {
                if !isDragging {
                    isDragging = true
                    delegate?.activateOverlay()
                }
                delegate?.didUpdateMouseLocation(NSEvent.mouseLocation)
            } else {
                if isDragging {
                    isDragging = false
                    delegate?.deactivateOverlay()
                }
            }
            
        case .flagsChanged:
            // If dragging, and modifier is released, hide overlay
            // But flagsChanged doesn't tell us if mouse is down easily without tracking state.
            // Actually, we should rely on drag events mostly. But if user releases shift while dragging, we need to hide.
            
            // However, getting "is mouse down" relies on other state tracking or CGEvent source state.
            // For simplicity, we can just check if we were "isDragging" (which means we were in a drag loop with modifiers)
            // and if modifiers are now gone, we cancel.
            
            if isDragging {
                let flags = event.modifierFlags
                if !flags.contains(.shift) && !flags.contains(.option) {
                    isDragging = false
                    delegate?.deactivateOverlay()
                }
            }
            
        case .leftMouseUp:
            if isDragging {
                isDragging = false
                delegate?.didEndDrag()
                delegate?.deactivateOverlay()
            }
            
        default:
            break
        }
    }
}
