import Cocoa
import ApplicationServices
import FancyZonesCore

@MainActor
class WindowManager {
    static let shared = WindowManager()
    
    private init() {}
    
    func getWindowUnderCursor() -> AXUIElement? {
        let mouseLocation = NSEvent.mouseLocation
        
        // NSEvent.mouseLocation is bottom-left based. AX requires top-left based.
        guard let screenHeight = NSScreen.main?.frame.height else { return nil }
        let flippedY = screenHeight - mouseLocation.y
        
        let systemWide = AXUIElementCreateSystemWide()
        var element: AXUIElement?
        
        let result = AXUIElementCopyElementAtPosition(systemWide, Float(mouseLocation.x), Float(flippedY), &element)
        
        if result == .success, let element = element {
            return getWindowFromElement(element)
        }
        
        return nil
    }
    
    private func getWindowFromElement(_ element: AXUIElement) -> AXUIElement? {
        var currentElement = element
        
        // Loop up to find the window
        while true {
            var role: AnyObject?
            let result = AXUIElementCopyAttributeValue(currentElement, kAXRoleAttribute as CFString, &role)
            
            if result == .success, let roleStr = role as? String {
                if roleStr == kAXWindowRole {
                    return currentElement
                }
            }
            
            var parent: AnyObject?
            let parentResult = AXUIElementCopyAttributeValue(currentElement, kAXParentAttribute as CFString, &parent)
            
            if parentResult == .success, let parentElement = parent {
                // Determine if parent is an AXUIElement (it is returned as CFTypeRef/AnyObject)
                if CFGetTypeID(parentElement) == AXUIElementGetTypeID() {
                    currentElement = parentElement as! AXUIElement
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        return nil
    }
    
    func moveWindow(_ window: AXUIElement, to rect: CGRect, spacing: CGFloat = 0) {
        guard let screen = NSScreen.main else { return }
        
        // Delegate all coordinate math to ZoneEngine (tested separately)
        let frame = zoneEngine.axFrame(
            for: rect,
            visibleFrame: screen.visibleFrame,
            screenFrame: screen.frame,
            spacing: spacing
        )
        
        var position = CGPoint(x: frame.origin.x, y: frame.origin.y)
        var size = CGSize(width: frame.width, height: frame.height)
        
        if let positionValue = AXValueCreate(.cgPoint, &position),
           let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
    }
}
