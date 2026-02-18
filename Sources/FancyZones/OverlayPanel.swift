import Cocoa
import SwiftUI
import FancyZonesCore

class OverlayPanel: NSPanel {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        self.isFloatingPanel = true
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = false
        self.ignoresMouseEvents = true
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
    }
}

struct ZoneOverlayView: View {
    let layout: ZoneLayout
    let activeZoneIndex: Int?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                ForEach(Array(layout.zones.enumerated()), id: \.offset) { index, zone in
                    ZoneRectView(
                        zone: zone,
                        isActive: index == activeZoneIndex,
                        spacing: layout.spacing,
                        containerSize: geometry.size
                    )
                }
            }
        }
    }
}

/// Extracted to help the compiler type-check each zone rect independently.
private struct ZoneRectView: View {
    let zone: Zone
    let isActive: Bool
    let spacing: CGFloat
    let containerSize: CGSize

    private var rect: CGRect {
        CGRect(
            x: zone.rect.origin.x * containerSize.width,
            // Flip Y: zone origin is top-left, SwiftUI origin is top-left too — no flip needed.
            // But our zone coords use top-left origin (y=0 is top), and SwiftUI also uses top-left.
            y: zone.rect.origin.y * containerSize.height,
            width: zone.rect.width * containerSize.width,
            height: zone.rect.height * containerSize.height
        ).insetBy(dx: spacing / 2, dy: spacing / 2)
    }

    var body: some View {
        let fillColor: Color = isActive ? Color.blue.opacity(0.45) : Color.white.opacity(0.12)
        let strokeColor: Color = isActive ? Color.blue : Color.white.opacity(0.5)

        Rectangle()
            .path(in: rect)
            .fill(fillColor)
            .overlay(
                Rectangle()
                    .path(in: rect)
                    .stroke(strokeColor, lineWidth: isActive ? 2.5 : 1.5)
            )
    }
}
