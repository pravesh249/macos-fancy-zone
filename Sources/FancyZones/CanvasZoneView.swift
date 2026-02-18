import SwiftUI
import FancyZonesCore

struct CanvasZoneView: View {
    let zone: Zone
    let containerSize: CGSize
    let isSelected: Bool
    let onUpdate: (CGRect) -> Void
    let onDelete: () -> Void
    
    // Minimum size for a zone (normalized)
    private let minSize: CGFloat = 0.05
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        let pixelRect = CGRect(
            x: zone.rect.origin.x * containerSize.width,
            y: zone.rect.origin.y * containerSize.height,
            width: zone.rect.width * containerSize.width,
            height: zone.rect.height * containerSize.height
        )
        
        ZStack {
            // Zone content / Drag Area
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .border(Color.blue, width: isSelected ? 3 : 1)
                .overlay(
                    Text("Zone")
                        .font(.caption)
                        .foregroundColor(.white)
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            let dx = value.translation.width / containerSize.width
                            let dy = value.translation.height / containerSize.height
                            
                            var newX = zone.rect.origin.x + dx
                            var newY = zone.rect.origin.y + dy
                            
                            // Clamp to bounds
                            newX = max(0, min(1.0 - zone.rect.width, newX))
                            newY = max(0, min(1.0 - zone.rect.height, newY))
                            
                            onUpdate(CGRect(x: newX, y: newY, width: zone.rect.width, height: zone.rect.height))
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            
            // Resize Handles
            resizeHandle(alignment: .topLeading, pixelRect: pixelRect)
            resizeHandle(alignment: .topTrailing, pixelRect: pixelRect)
            resizeHandle(alignment: .bottomLeading, pixelRect: pixelRect)
            resizeHandle(alignment: .bottomTrailing, pixelRect: pixelRect)
            
            // Delete Button (only show on hover/select ideally, but for now always top-right)
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(Color.white.mask(Circle()))
            }
            .position(x: pixelRect.maxX, y: pixelRect.minY)
            .offset(x: 5, y: -5)
        }
        .frame(width: containerSize.width, height: containerSize.height, alignment: .topLeading)
        // Position the ZStack sub-elements based on pixelRect? 
        // No, the ZStack wraps the whole canvas, and we position elements absolutely within it.
        // Actually, simpler: The View *is* the rect.
        .position(x: pixelRect.midX, y: pixelRect.midY)
    }
    
    private func resizeHandle(alignment: Alignment, pixelRect: CGRect) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: 10, height: 10)
            .overlay(Circle().stroke(Color.blue, lineWidth: 1))
            .position(
                x: alignment == .topLeading || alignment == .bottomLeading ? pixelRect.minX : pixelRect.maxX,
                y: alignment == .topLeading || alignment == .topTrailing ? pixelRect.minY : pixelRect.maxY
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let dx = value.translation.width / containerSize.width
                        let dy = value.translation.height / containerSize.height
                        
                        var newRect = zone.rect
                        
                        switch alignment {
                        case .topLeading:
                            newRect.origin.x += dx
                            newRect.origin.y += dy
                            newRect.size.width -= dx
                            newRect.size.height -= dy
                        case .topTrailing:
                            newRect.origin.y += dy
                            newRect.size.width += dx
                            newRect.size.height -= dy
                        case .bottomLeading:
                            newRect.origin.x += dx
                            newRect.size.width -= dx
                            newRect.size.height += dy
                        case .bottomTrailing:
                            newRect.size.width += dx
                            newRect.size.height += dy
                        default: break
                        }
                        
                        // normalize check
                        if newRect.width < minSize { newRect.size.width = minSize }
                        if newRect.height < minSize { newRect.size.height = minSize }
                        
                        onUpdate(newRect)
                    }
            )
    }
}
