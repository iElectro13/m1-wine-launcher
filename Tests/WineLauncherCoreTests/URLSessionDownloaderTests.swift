import Foundation
import Testing
@testable import WineLauncherCore

struct URLSessionDownloaderTests {
    @Test func downloadsAFileUrlToTheDestinationAndReportsProgress() async throws {
        let source = TestSupport.makeTempDirectory().appendingPathComponent("payload.bin")
        try Data(repeating: 7, count: 200_000).write(to: source)
        let destination = TestSupport.makeTempDirectory().appendingPathComponent("sub/payload.bin")
        let last = LockedBox<Double>(0)

        try await URLSessionDownloader().download(from: source, to: destination) { last.value = $0 }

        #expect(try Data(contentsOf: destination).count == 200_000)
        #expect(last.value == 1)
    }

    @Test func throwsWhenTheSourceDoesNotExist() async {
        let missing = URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString)")
        let destination = TestSupport.makeTempDirectory().appendingPathComponent("x")

        await #expect(throws: (any Error).self) {
            try await URLSessionDownloader().download(from: missing, to: destination)
        }
    }
}

final class LockedBox<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: T

    init(_ value: T) { stored = value }

    var value: T {
        get { lock.withLock { stored } }
        set { lock.withLock { stored = newValue } }
    }
}
