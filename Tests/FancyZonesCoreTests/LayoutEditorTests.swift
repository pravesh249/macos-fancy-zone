import Foundation
import CoreGraphics
@testable import FancyZonesCore

func runLayoutEditorLogicTests() {
    print("\n💾 Layout Editor Logic & Persistence Tests")

    test("Zone Codable Roundtrip") {
        let original = Zone(id: UUID(), rect: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Zone.self, from: data)
        
        try expect(original.id == decoded.id, "Zone ID matches")
        try expect(original.rect == decoded.rect, "Zone Rect matches")
    }

    test("ZoneLayout Codable Roundtrip") {
        let zone1 = Zone(rect: CGRect(x: 0, y: 0, width: 0.5, height: 1))
        let layout = ZoneLayout(name: "Test Layout", spacing: 10, zones: [zone1])
        
        let data = try JSONEncoder().encode(layout)
        let decoded = try JSONDecoder().decode(ZoneLayout.self, from: data)
        
        try expect(layout.name == decoded.name, "Layout Name matches")
        try expect(layout.spacing == decoded.spacing, "Layout Spacing matches")
        try expect(layout.zones.count == decoded.zones.count, "Layout Zone count matches")
        try expect(layout.zones.first?.rect == decoded.zones.first?.rect, "First zone rect matches")
    }
    
    test("Layout List Serialization") {
        let layout1 = ZoneLayout(name: "L1", spacing: 5, zones: [])
        let layout2 = ZoneLayout(name: "L2", spacing: 10, zones: [])
        let list = [layout1, layout2]
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(list)
        
        let decoder = JSONDecoder()
        let decodedList = try decoder.decode([ZoneLayout].self, from: data)
        
        try expect(list.count == decodedList.count, "List count matches")
        try expect(decodedList[0].name == "L1", "First name matches")
        try expect(decodedList[1].name == "L2", "Second name matches")
    }
    
    test("ZoneLayout Identity") {
        let l1 = ZoneLayout(name: "My Layout", spacing: 0, zones: [])
        let l2 = ZoneLayout(name: "My Layout", spacing: 10, zones: [])
        // IDs are derived from names currently
        try expect(l1.id == l2.id, "Layouts with same name have same ID")
        try expect(l1.id == "My Layout", "ID is the name")
    }
}
