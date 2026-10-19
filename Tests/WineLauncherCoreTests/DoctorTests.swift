import Foundation
import Testing
@testable import WineLauncherCore

struct DoctorTests {
    private func makeRuntime(withMoltenVK: Bool) throws -> WineRuntime {
        let root = TestSupport.makeTempDirectory().appendingPathComponent("wine")
        let bin = root.appendingPathComponent("bin")
        let lib = root.appendingPathComponent("lib")
        try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: lib, withIntermediateDirectories: true)
        let wine = bin.appendingPathComponent("wine")
        try "x".write(to: wine, atomically: true, encoding: .utf8)
        if withMoltenVK {
            try "x".write(to: lib.appendingPathComponent("libMoltenVK.dylib"), atomically: true, encoding: .utf8)
        }
        return WineRuntime(wineExecutable: wine)
    }

    @Test func healthyRuntimeReportsNoFailures() async throws {
        let doctor = Doctor(runtime: try makeRuntime(withMoltenVK: true), launcher: RecordingLauncher())

        let report = await doctor.run()

        #expect(report.allSatisfy { $0.status != .failure })
        #expect(report.contains { $0.name == "Wine" && $0.status == .ok })
        #expect(report.contains { $0.name == "MoltenVK" && $0.status == .ok })
    }

    @Test func missingWineBinaryIsAFailure() async {
        let runtime = WineRuntime(wineExecutable: URL(fileURLWithPath: "/nonexistent/bin/wine"))

        let report = await Doctor(runtime: runtime, launcher: RecordingLauncher()).run()

        #expect(report.contains { $0.name == "Wine" && $0.status == .failure })
    }

    @Test func wineThatCannotRunIsAFailure() async throws {
        let launcher = RecordingLauncher()
        launcher.exitCode = 126
        let doctor = Doctor(runtime: try makeRuntime(withMoltenVK: true), launcher: launcher)

        let report = await doctor.run()

        #expect(report.contains { $0.name == "Wine" && $0.status == .failure })
    }

    @Test func missingMoltenVKIsOnlyAWarning() async throws {
        let doctor = Doctor(runtime: try makeRuntime(withMoltenVK: false), launcher: RecordingLauncher())

        let report = await doctor.run()

        #expect(report.contains { $0.name == "MoltenVK" && $0.status == .warning })
    }
}
