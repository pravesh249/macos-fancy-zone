import Foundation
import CoreGraphics
import FancyZonesCore

// MARK: - Minimal Test Harness (Swift 6 compatible)

nonisolated(unsafe) var passed = 0
nonisolated(unsafe) var failed = 0
nonisolated(unsafe) var failures: [String] = []

func test(_ name: String, _ body: () throws -> Void) {
    do {
        try body()
        print("  ✅ \(name)")
        passed += 1
    } catch {
        print("  ❌ \(name): \(error)")
        failed += 1
        failures.append(name)
    }
}

struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

func expect(_ condition: Bool, _ message: String = "Assertion failed", line: Int = #line) throws {
    if !condition { throw TestFailure(description: "\(message) (line \(line))") }
}

func expectEqualF(_ a: CGFloat, _ b: CGFloat, accuracy: CGFloat = 0.001, _ message: String = "", line: Int = #line) throws {
    if abs(a - b) > accuracy { throw TestFailure(description: "\(message) — expected \(b), got \(a) (line \(line))") }
}

func expectNil<T>(_ value: T?, _ message: String = "Expected nil", line: Int = #line) throws {
    if value != nil { throw TestFailure(description: "\(message) — got \(value!) (line \(line))") }
}

func expectNotNil<T>(_ value: T?, _ message: String = "Expected non-nil", line: Int = #line) throws {
    if value == nil { throw TestFailure(description: "\(message) (line \(line))") }
}

// MARK: - Test Suites

func runZoneLayoutTests() {
    print("\n📐 ZoneLayout Tests")

    test("priorityGrid has 3 zones") {
        try expect(ZoneLayout.priorityGrid.zones.count == 3)
    }
    test("priorityGrid widths sum to 1.0") {
        let total = ZoneLayout.priorityGrid.zones.reduce(0.0) { $0 + $1.rect.width }
        try expectEqualF(total, 1.0, accuracy: 0.001, "Width sum")
    }
    test("priorityGrid left zone is 25%") {
        let left = ZoneLayout.priorityGrid.zones[0]
        try expectEqualF(left.rect.width, 0.25, accuracy: 0.001, "Left width")
        try expectEqualF(left.rect.origin.x, 0.0, accuracy: 0.001, "Left x")
    }
    test("priorityGrid center zone is 50%") {
        let center = ZoneLayout.priorityGrid.zones[1]
        try expectEqualF(center.rect.width, 0.50, accuracy: 0.001, "Center width")
        try expectEqualF(center.rect.origin.x, 0.25, accuracy: 0.001, "Center x")
    }
    test("priorityGrid right zone is 25%") {
        let right = ZoneLayout.priorityGrid.zones[2]
        try expectEqualF(right.rect.width, 0.25, accuracy: 0.001, "Right width")
        try expectEqualF(right.rect.origin.x, 0.75, accuracy: 0.001, "Right x")
    }
    test("priorityGrid spacing is 16") {
        try expect(ZoneLayout.priorityGrid.spacing == 16)
    }
    test("threeColumn has 3 equal-width zones") {
        let layout = ZoneLayout.threeColumn
        try expect(layout.zones.count == 3)
        for zone in layout.zones {
            try expectEqualF(zone.rect.width, 0.333, accuracy: 0.002)
        }
    }
    test("twoByTwo has 4 zones") {
        try expect(ZoneLayout.twoByTwo.zones.count == 4)
    }
    test("twoByTwo covers all quadrants") {
        let z = ZoneLayout.twoByTwo.zones
        try expect(z[0].rect.origin == CGPoint(x: 0, y: 0))
        try expect(z[1].rect.origin == CGPoint(x: 0.5, y: 0))
        try expect(z[2].rect.origin == CGPoint(x: 0, y: 0.5))
        try expect(z[3].rect.origin == CGPoint(x: 0.5, y: 0.5))
    }
    test("all layouts have non-empty names") {
        try expect(!ZoneLayout.priorityGrid.name.isEmpty)
        try expect(!ZoneLayout.threeColumn.name.isEmpty)
        try expect(!ZoneLayout.twoByTwo.name.isEmpty)
    }
}

func runHitTestingTests() {
    print("\n🎯 ZoneEngine Hit-Testing Tests")
    let engine = ZoneEngine()
    let layout = ZoneLayout.priorityGrid

    test("left zone → index 0")    { try expect(engine.activeZoneIndex(for: CGPoint(x: 0.125, y: 0.5), in: layout) == 0) }
    test("center zone → index 1")  { try expect(engine.activeZoneIndex(for: CGPoint(x: 0.5,   y: 0.5), in: layout) == 1) }
    test("right zone → index 2")   { try expect(engine.activeZoneIndex(for: CGPoint(x: 0.875, y: 0.5), in: layout) == 2) }
    test("outside zones → nil")    { try expectNil(engine.activeZoneIndex(for: CGPoint(x: 1.5, y: 0.5), in: layout)) }
    test("exact boundary → center"){ try expect(engine.activeZoneIndex(for: CGPoint(x: 0.25, y: 0.5), in: layout) == 1) }

    let grid = ZoneLayout.twoByTwo
    test("2x2 top-left → 0")    { try expect(engine.activeZoneIndex(for: CGPoint(x: 0.25, y: 0.25), in: grid) == 0) }
    test("2x2 top-right → 1")   { try expect(engine.activeZoneIndex(for: CGPoint(x: 0.75, y: 0.25), in: grid) == 1) }
    test("2x2 bottom-left → 2") { try expect(engine.activeZoneIndex(for: CGPoint(x: 0.25, y: 0.75), in: grid) == 2) }
    test("2x2 bottom-right → 3"){ try expect(engine.activeZoneIndex(for: CGPoint(x: 0.75, y: 0.75), in: grid) == 3) }
    test("(0,0) hits a zone")   { try expectNotNil(engine.activeZoneIndex(for: .zero, in: layout)) }
}

func runCoordinateTests() {
    print("\n🗺️  ZoneEngine Coordinate Conversion Tests")
    let engine = ZoneEngine()
    let screen = CGRect(x: 0, y: 0, width: 2560, height: 1440)

    test("center → (0.5, 0.5)") {
        let pt = engine.normalizedLayoutPoint(mouseLocation: CGPoint(x: 1280, y: 720), screenFrame: screen)
        try expectEqualF(pt.x, 0.5, accuracy: 0.001); try expectEqualF(pt.y, 0.5, accuracy: 0.001)
    }
    test("Cocoa top-left → layout (0,0)") {
        let pt = engine.normalizedLayoutPoint(mouseLocation: CGPoint(x: 0, y: 1440), screenFrame: screen)
        try expectEqualF(pt.x, 0.0, accuracy: 0.001); try expectEqualF(pt.y, 0.0, accuracy: 0.001)
    }
    test("Cocoa bottom-left → layout (0,1)") {
        let pt = engine.normalizedLayoutPoint(mouseLocation: CGPoint(x: 0, y: 0), screenFrame: screen)
        try expectEqualF(pt.x, 0.0, accuracy: 0.001); try expectEqualF(pt.y, 1.0, accuracy: 0.001)
    }
    test("Cocoa top-right → layout (1,0)") {
        let pt = engine.normalizedLayoutPoint(mouseLocation: CGPoint(x: 2560, y: 1440), screenFrame: screen)
        try expectEqualF(pt.x, 1.0, accuracy: 0.001); try expectEqualF(pt.y, 0.0, accuracy: 0.001)
    }
    test("zero-size screen → (0,0)") {
        let pt = engine.normalizedLayoutPoint(mouseLocation: CGPoint(x: 100, y: 100), screenFrame: .zero)
        try expect(pt == .zero)
    }
    test("offset screen center → (0.5, 0.5)") {
        let offset = CGRect(x: 100, y: 50, width: 1920, height: 1080)
        let pt = engine.normalizedLayoutPoint(mouseLocation: CGPoint(x: 1060, y: 590), screenFrame: offset)
        try expectEqualF(pt.x, 0.5, accuracy: 0.001); try expectEqualF(pt.y, 0.5, accuracy: 0.001)
    }
}

func runAXFrameTests() {
    print("\n📦 ZoneEngine AX Frame Tests")
    let engine = ZoneEngine()
    let sf = CGRect(x: 0, y: 0, width: 2560, height: 1440)
    let vf = CGRect(x: 0, y: 0, width: 2560, height: 1415)

    test("full-screen zone fills visible area") {
        let f = engine.axFrame(for: CGRect(x:0,y:0,width:1,height:1), visibleFrame: vf, screenFrame: sf, spacing: 0)
        try expectEqualF(f.origin.x, 0, accuracy: 0.5)
        try expectEqualF(f.width, 2560, accuracy: 0.5)
        try expectEqualF(f.height, 1415, accuracy: 0.5)
        try expectEqualF(f.origin.y, 25, accuracy: 0.5, "menu bar offset")
    }
    test("left 25% → width 640") {
        let f = engine.axFrame(for: CGRect(x:0,y:0,width:0.25,height:1), visibleFrame: vf, screenFrame: sf, spacing: 0)
        try expectEqualF(f.width, 640, accuracy: 0.5)
    }
    test("center 50% → x=640, width=1280") {
        let f = engine.axFrame(for: CGRect(x:0.25,y:0,width:0.5,height:1), visibleFrame: vf, screenFrame: sf, spacing: 0)
        try expectEqualF(f.origin.x, 640, accuracy: 0.5)
        try expectEqualF(f.width, 1280, accuracy: 0.5)
    }
    test("right 25% → x=1920, width=640") {
        let f = engine.axFrame(for: CGRect(x:0.75,y:0,width:0.25,height:1), visibleFrame: vf, screenFrame: sf, spacing: 0)
        try expectEqualF(f.origin.x, 1920, accuracy: 0.5)
        try expectEqualF(f.width, 640, accuracy: 0.5)
    }
    test("spacing=16 reduces size by 16") {
        let a = engine.axFrame(for: CGRect(x:0,y:0,width:1,height:1), visibleFrame: vf, screenFrame: sf, spacing: 0)
        let b = engine.axFrame(for: CGRect(x:0,y:0,width:1,height:1), visibleFrame: vf, screenFrame: sf, spacing: 16)
        try expectEqualF(a.width - b.width, 16, accuracy: 0.5)
        try expectEqualF(a.height - b.height, 16, accuracy: 0.5)
    }
    test("spacing=16 shifts origin by +8") {
        let a = engine.axFrame(for: CGRect(x:0,y:0,width:1,height:1), visibleFrame: vf, screenFrame: sf, spacing: 0)
        let b = engine.axFrame(for: CGRect(x:0,y:0,width:1,height:1), visibleFrame: vf, screenFrame: sf, spacing: 16)
        try expectEqualF(b.origin.x - a.origin.x, 8, accuracy: 0.5)
    }
}
