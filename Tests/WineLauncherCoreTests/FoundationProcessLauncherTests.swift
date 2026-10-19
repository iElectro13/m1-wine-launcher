import Foundation
import Testing
@testable import WineLauncherCore

struct FoundationProcessLauncherTests {
    private let sh = URL(fileURLWithPath: "/bin/sh")

    @Test func capturesOutputAndExitCode() async throws {
        let command = WineCommand(
            executable: sh, arguments: ["-c", "echo out; echo err 1>&2; exit 3"], environment: [:])

        let result = try await FoundationProcessLauncher().run(command)

        #expect(result.exitCode == 3)
        #expect(result.standardOutput == "out\n")
        #expect(result.standardError == "err\n")
    }

    @Test func passesCommandEnvironmentOnTopOfInheritedOne() async throws {
        let command = WineCommand(
            executable: sh, arguments: ["-c", "echo $WL_TEST_VAR"], environment: ["WL_TEST_VAR": "bottle"])

        let result = try await FoundationProcessLauncher().run(command)

        #expect(result.standardOutput == "bottle\n")
    }

    @Test func doesNotDeadlockOnLargeStderr() async throws {
        let command = WineCommand(
            executable: sh,
            arguments: ["-c", "head -c 300000 /dev/zero | tr '\\0' x 1>&2; echo done"],
            environment: [:])

        let result = try await FoundationProcessLauncher().run(command)

        #expect(result.standardOutput == "done\n")
        #expect(result.standardError.count == 300_000)
    }

    @Test func throwsWhenExecutableDoesNotExist() async {
        let command = WineCommand(
            executable: URL(fileURLWithPath: "/nonexistent/wine"), arguments: [], environment: [:])

        await #expect(throws: (any Error).self) {
            try await FoundationProcessLauncher().run(command)
        }
    }
}
