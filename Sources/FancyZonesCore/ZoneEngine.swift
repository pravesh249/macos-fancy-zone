import Foundation
import CoreGraphics

// MARK: - Models

/// A single zone defined by a normalized rect (0.0–1.0 relative to screen).
/// Origin is Top-Left (like CSS/Windows), Y increases downward.
public struct Zone: Identifiable, Sendable {
    public let id: UUID
    public let rect: CGRect

    public init(id: UUID = UUID(), rect: CGRect) {
        self.id = id
        self.rect = rect
    }
}

/// A collection of zones with a name and gap spacing.
public struct ZoneLayout: Sendable {
    public let name: String
    /// Gap in points between zones (applied as inset on each side).
    public let spacing: CGFloat
    public let zones: [Zone]

    public init(name: String, spacing: CGFloat, zones: [Zone]) {
        self.name = name
        self.spacing = spacing
        self.zones = zones
    }

    // MARK: - Hardcoded Layouts

    /// 3-Column Priority Grid: Left 25% | Center 50% | Right 25%
    public static let priorityGrid = ZoneLayout(
        name: "Priority Grid",
        spacing: 16,
        zones: [
            Zone(rect: CGRect(x: 0.00, y: 0.0, width: 0.25, height: 1.0)),
            Zone(rect: CGRect(x: 0.25, y: 0.0, width: 0.50, height: 1.0)),
            Zone(rect: CGRect(x: 0.75, y: 0.0, width: 0.25, height: 1.0)),
        ]
    )

    /// Equal 3-Column Grid
    public static let threeColumn = ZoneLayout(
        name: "3-Column",
        spacing: 16,
        zones: [
            Zone(rect: CGRect(x: 0.000, y: 0.0, width: 0.333, height: 1.0)),
            Zone(rect: CGRect(x: 0.333, y: 0.0, width: 0.334, height: 1.0)),
            Zone(rect: CGRect(x: 0.667, y: 0.0, width: 0.333, height: 1.0)),
        ]
    )

    /// 2×2 Grid
    public static let twoByTwo = ZoneLayout(
        name: "2x2 Grid",
        spacing: 16,
        zones: [
            Zone(rect: CGRect(x: 0.0, y: 0.0, width: 0.5, height: 0.5)),
            Zone(rect: CGRect(x: 0.5, y: 0.0, width: 0.5, height: 0.5)),
            Zone(rect: CGRect(x: 0.0, y: 0.5, width: 0.5, height: 0.5)),
            Zone(rect: CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)),
        ]
    )

    /// 3-Column Wide Center: Left 30% | Center 40% | Right 30%, no gaps
    public static let wideCenter = ZoneLayout(
        name: "Wide Center",
        spacing: 0,
        zones: [
            Zone(rect: CGRect(x: 0.0,  y: 0.0, width: 0.30, height: 1.0)),
            Zone(rect: CGRect(x: 0.3,  y: 0.0, width: 0.40, height: 1.0)),
            Zone(rect: CGRect(x: 0.7,  y: 0.0, width: 0.30, height: 1.0)),
        ]
    )
}

// MARK: - Zone Engine

/// Pure, testable logic for zone hit-testing and coordinate math.
public struct ZoneEngine: Sendable {

    public init() {}

    // MARK: Coordinate Conversion

    /// Converts a Cocoa mouse location (bottom-left origin) to a normalized
    /// layout point (top-left origin, 0–1 relative to `screenFrame`).
    ///
    /// - Parameters:
    ///   - mouseLocation: `NSEvent.mouseLocation` — Cocoa bottom-left coords.
    ///   - screenFrame: The full screen frame in Cocoa coords (bottom-left).
    /// - Returns: Normalized point where (0,0) is top-left of screen.
    public func normalizedLayoutPoint(
        mouseLocation: CGPoint,
        screenFrame: CGRect
    ) -> CGPoint {
        guard screenFrame.width > 0, screenFrame.height > 0 else {
            return .zero
        }
        let nx = (mouseLocation.x - screenFrame.origin.x) / screenFrame.width
        // Cocoa Y increases upward; layout Y increases downward → flip
        let ny = 1.0 - ((mouseLocation.y - screenFrame.origin.y) / screenFrame.height)
        return CGPoint(x: nx, y: ny)
    }

    // MARK: Hit Testing

    /// Returns the index of the first zone whose normalized rect contains `point`.
    ///
    /// - Parameters:
    ///   - point: Normalized layout point (top-left origin, 0–1).
    ///   - layout: The zone layout to test against.
    public func activeZoneIndex(for point: CGPoint, in layout: ZoneLayout) -> Int? {
        for (index, zone) in layout.zones.enumerated() {
            if zone.rect.contains(point) {
                return index
            }
        }
        return nil
    }

    // MARK: Target Frame Calculation

    /// Converts a normalized zone rect into an absolute `CGRect` suitable for
    /// passing to `AXUIElementSetAttributeValue` (top-left origin, points).
    ///
    /// - Parameters:
    ///   - zoneRect: Normalized zone rect (top-left origin, 0–1).
    ///   - visibleFrame: Screen's `visibleFrame` in Cocoa coords (bottom-left).
    ///   - screenFrame: Screen's full `frame` in Cocoa coords (bottom-left).
    ///   - spacing: Gap in points to inset on each side.
    /// - Returns: Absolute rect in AX coordinate space (top-left origin).
    public func axFrame(
        for zoneRect: CGRect,
        visibleFrame: CGRect,
        screenFrame: CGRect,
        spacing: CGFloat
    ) -> CGRect {
        // 1. Scale normalized rect to screen points (Cocoa bottom-left)
        let w = zoneRect.width  * visibleFrame.width
        let h = zoneRect.height * visibleFrame.height
        let x = visibleFrame.origin.x + zoneRect.origin.x * visibleFrame.width
        // Zone Y is top-left; visibleFrame.origin.y is bottom of visible area.
        // Top-left zone y=0 → bottom of screen (highest Y in Cocoa).
        // Top-left zone y=1 → bottom of visible area.
        let cocoaY = visibleFrame.origin.y + (1.0 - zoneRect.origin.y - zoneRect.height) * visibleFrame.height

        // 2. Apply spacing inset
        let raw = CGRect(x: x, y: cocoaY, width: w, height: h)
        let inset = raw.insetBy(dx: spacing / 2, dy: spacing / 2)

        // 3. Flip Y for AX (top-left origin)
        let axY = screenFrame.height - (inset.origin.y + inset.height)
        return CGRect(x: inset.origin.x, y: axY, width: inset.width, height: inset.height)
    }
}
