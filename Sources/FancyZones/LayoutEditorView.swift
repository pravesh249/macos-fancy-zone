import SwiftUI
import FancyZonesCore

struct LayoutEditorView: View {
    @State private var layouts: [ZoneLayout] = []
    @State private var selectedLayoutId: String?
    @State private var editingLayout: ZoneLayout?
    
    // For saving/loading
    private let repository = LayoutRepository.shared
    
    var body: some View {
        HSplitView {
            // Sidebar: List of Layouts
            VStack {
                List(selection: $selectedLayoutId) {
                    ForEach(layouts) { layout in
                        Text(layout.name)
                            .tag(layout.id)
                    }
                }
                .listStyle(.sidebar)
                
                HStack {
                    Button(action: createNewLayout) {
                        Image(systemName: "plus")
                    }
                    Button(action: deleteSelectedLayout) {
                        Image(systemName: "minus")
                    }
                    .disabled(selectedLayoutId == nil)
                    Spacer()
                }
                .padding(8)
            }
            .frame(minWidth: 200, maxWidth: 300)
            
            // Main Content: Canvas Editor
            VStack {
                if let selectedId = selectedLayoutId, 
                   let layoutIndex = layouts.firstIndex(where: { $0.id == selectedId }) {
                    
                    EditorCanvas(layout: $layouts[layoutIndex])
                        .id(selectedId) // Force refresh when switching
                    
                } else {
                    Text("Select a layout to edit")
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear(perform: loadLayouts)
        // Auto-save on change? Or explicit save button?
        // Let's add explicit "Save All" for now to keep it simple, or auto-save on disappear.
        .toolbar {
            Button("Save Changes") {
                saveLayouts()
            }
        }
    }
    
    private func loadLayouts() {
        layouts = repository.getAllLayouts()
        selectedLayoutId = layouts.first?.id
    }
    
    private func saveLayouts() {
        do {
            try repository.saveLayouts(layouts)
            // Reload overlay
            OverlayManager.shared.reloadLayouts()
        } catch {
            print("Failed to save layouts: \(error)")
        }
    }
    
    private func createNewLayout() {
        let newLayout = ZoneLayout(
            name: "New Layout \(layouts.count + 1)",
            spacing: 16,
            zones: [
                Zone(rect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))
            ]
        )
        layouts.append(newLayout)
        selectedLayoutId = newLayout.id
    }
    
    private func deleteSelectedLayout() {
        guard let id = selectedLayoutId else { return }
        layouts.removeAll(where: { $0.id == id })
        selectedLayoutId = nil
    }
}

struct EditorCanvas: View {
    @Binding var layout: ZoneLayout
    
    var body: some View {
        VStack {
            TextField("Layout Name", text: Binding(
                get: { layout.name },
                set: { layout = ZoneLayout(name: $0, spacing: layout.spacing, zones: layout.zones) }
            ))
            .textFieldStyle(.roundedBorder)
            .padding()
            
            HStack {
                Text("Spacing: \(Int(layout.spacing))")
                Slider(value: Binding(
                    get: { layout.spacing },
                    set: { layout = ZoneLayout(name: layout.name, spacing: $0, zones: layout.zones) }
                ), in: 0...100)
            }
            .padding(.horizontal)
            
            GeometryReader { geo in
                ZStack {
                    // Background representing screen
                    Rectangle()
                        .fill(Color.black.opacity(0.8))
                        .border(Color.gray, width: 2)
                    
                    // Zones
                    ForEach(Array(layout.zones.enumerated()), id: \.offset) { index, zone in
                        CanvasZoneView(
                            zone: zone,
                            containerSize: geo.size,
                            isSelected: false, // selection logic later
                            onUpdate: { newRect in
                                var newZones = layout.zones
                                newZones[index] = Zone(id: zone.id, rect: newRect)
                                layout = ZoneLayout(name: layout.name, spacing: layout.spacing, zones: newZones)
                            },
                            onDelete: {
                                var newZones = layout.zones
                                newZones.remove(at: index)
                                layout = ZoneLayout(name: layout.name, spacing: layout.spacing, zones: newZones)
                            }
                        )
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .background(Color.blue.opacity(0.1))
            }
            .padding()
            
            Button("Add Zone") {
                var newZones = layout.zones
                newZones.append(Zone(rect: CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2)))
                layout = ZoneLayout(name: layout.name, spacing: layout.spacing, zones: newZones)
            }
            .padding()
        }
    }
}
