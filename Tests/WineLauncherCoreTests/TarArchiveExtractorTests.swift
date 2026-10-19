import Foundation
import Testing
@testable import WineLauncherCore

struct TarArchiveExtractorTests {
    @Test func extractsArchiveContentsIntoTheDestination() async throws {
        let archive = try TestSupport.makeTarGz(files: ["a/b.txt": "hello"])
        let destination = TestSupport.makeTempDirectory().appendingPathComponent("out")

        try await TarArchiveExtractor(launcher: FoundationProcessLauncher())
            .extract(archive, to: destination)

        let text = try String(contentsOf: destination.appendingPathComponent("a/b.txt"), encoding: .utf8)
        #expect(text == "hello")
    }

    @Test func throwsWhenTheArchiveIsCorrupt() async throws {
        let bogus = TestSupport.makeTempDirectory().appendingPathComponent("bogus.tar.gz")
        try "not an archive".write(to: bogus, atomically: true, encoding: .utf8)
        let destination = TestSupport.makeTempDirectory().appendingPathComponent("out")

        await #expect(throws: ArchiveError.self) {
            try await TarArchiveExtractor(launcher: FoundationProcessLauncher())
                .extract(bogus, to: destination)
        }
    }
}
