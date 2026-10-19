import Foundation

public struct ProcessResult: Sendable, Equatable {
    public let exitCode: Int32
    public let standardOutput: String
    public let standardError: String

    public init(exitCode: Int32, standardOutput: String, standardError: String) {
        self.exitCode = exitCode
        self.standardOutput = standardOutput
        self.standardError = standardError
    }
}

/// Port: runs a command to completion.
public protocol WineProcessLauncher: Sendable {
    func run(_ command: WineCommand) async throws -> ProcessResult
}

/// Adapter backed by `Foundation.Process`.
public struct FoundationProcessLauncher: WineProcessLauncher {
    public init() {}

    public func run(_ command: WineCommand) async throws -> ProcessResult {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(with: Result { try Self.runBlocking(command) })
            }
        }
    }

    private static func runBlocking(_ command: WineCommand) throws -> ProcessResult {
        let process = Process()
        process.executableURL = command.executable
        process.arguments = command.arguments
        process.environment = ProcessInfo.processInfo.environment
            .merging(command.environment) { _, commandValue in commandValue }

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        try process.run()

        // Drain both pipes concurrently: Wine is chatty on stderr and a full pipe would block it.
        let stderrCapture = PipeCapture(stderr.fileHandleForReading)
        let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrCapture.finish()
        process.waitUntilExit()

        return ProcessResult(
            exitCode: process.terminationStatus,
            standardOutput: String(decoding: stdoutData, as: UTF8.self),
            standardError: String(decoding: stderrData, as: UTF8.self))
    }
}

private final class PipeCapture: @unchecked Sendable {
    private let group = DispatchGroup()
    private var data = Data()

    init(_ handle: FileHandle) {
        group.enter()
        DispatchQueue.global().async { [self] in
            data = handle.readDataToEndOfFile()
            group.leave()
        }
    }

    func finish() -> Data {
        group.wait()
        return data
    }
}
