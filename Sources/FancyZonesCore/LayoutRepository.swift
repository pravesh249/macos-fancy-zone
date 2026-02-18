import Foundation

/// Handles loading and saving layouts to disk.
@MainActor
public class LayoutRepository {
    public static let shared = LayoutRepository()

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // File path: ~/Library/Application Support/FancyZones/layouts.json
    private var layoutsFileURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("FancyZones")
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("layouts.json")
    }

    private init() {
        encoder.outputFormatting = .prettyPrinted
    }

    public func saveLayouts(_ layouts: [ZoneLayout]) throws {
        let data = try encoder.encode(layouts)
        try data.write(to: layoutsFileURL)
    }

    public func loadLayouts() -> [ZoneLayout] {
        guard let data = try? Data(contentsOf: layoutsFileURL),
              let layouts = try? decoder.decode([ZoneLayout].self, from: data) else {
            return []
        }
        return layouts
    }

    /// Returns default layouts combined with any saved custom layouts
    public func getAllLayouts() -> [ZoneLayout] {
        let saved = loadLayouts()
        let defaults: [ZoneLayout] = [
            ZoneLayout.wideCenter,
            ZoneLayout.priorityGrid,
            ZoneLayout.threeColumn,
            ZoneLayout.twoByTwo
        ]
        
        // Return saved first, then defaults (filtering out any saved ones that conflict/overwrite defaults if we wanted, 
        // but for now let's just append custom ones or treat them separately).
        // Actually, let's return defaults + saved unique ones.
        // For simplicity, just return defaults for now if no saved. 
        // If saved exists, return everything? 
        // Users might want to edit default layouts.
        
        if saved.isEmpty {
            return defaults
        }
        
        return defaults + saved
    }
}
