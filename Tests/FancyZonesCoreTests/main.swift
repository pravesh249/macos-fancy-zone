import Darwin
// main.swift — entry point for the standalone test runner
print("🧪 FancyZones Unit Tests")
print(String(repeating: "─", count: 50))

runZoneLayoutTests()
runHitTestingTests()
runCoordinateTests()
runAXFrameTests()

print("\n" + String(repeating: "─", count: 50))
print("Results: \(passed) passed, \(failed) failed")

if !failures.isEmpty {
    print("\nFailed tests:")
    for name in failures { print("  ❌ \(name)") }
    exit(1)
} else {
    print("🎉 All tests passed!")
    exit(0)
}
