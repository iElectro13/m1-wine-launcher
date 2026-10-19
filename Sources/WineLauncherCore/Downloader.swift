import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Port: fetches a remote file to a local path. `progress` receives values in 0...1.
public protocol Downloader: Sendable {
    func download(
        from url: URL, to destination: URL, progress: (@Sendable (Double) -> Void)?
    ) async throws
}

extension Downloader {
    public func download(from url: URL, to destination: URL) async throws {
        try await download(from: url, to: destination, progress: nil)
    }
}

public enum DownloadError: Error, Equatable {
    case badStatus(Int)
}

/// Adapter backed by `URLSession`.
public struct URLSessionDownloader: Downloader {
    public init() {}

    public func download(
        from url: URL, to destination: URL, progress: (@Sendable (Double) -> Void)?
    ) async throws {
        if url.isFileURL {
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.copyItem(at: url, to: destination)
            progress?(1)
            return
        }
        try await DownloadSession(destination: destination, progress: progress).run(url)
    }
}

private final class DownloadSession: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let destination: URL
    private let progress: (@Sendable (Double) -> Void)?
    private var continuation: CheckedContinuation<Void, any Error>?
    private var failure: (any Error)?

    init(destination: URL, progress: (@Sendable (Double) -> Void)?) {
        self.destination = destination
        self.progress = progress
    }

    func run(_ url: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
            session.downloadTask(with: url).resume()
            session.finishTasksAndInvalidate()
        }
    }

    func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        progress?(min(1, Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)))
    }

    // The temporary file is deleted when this returns, so it must be moved here.
    func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL
    ) {
        do {
            if let http = downloadTask.response as? HTTPURLResponse,
                !(200..<300).contains(http.statusCode)
            {
                throw DownloadError.badStatus(http.statusCode)
            }
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: location, to: destination)
            progress?(1)
        } catch {
            failure = error
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        guard let continuation else { return }
        self.continuation = nil
        if let error = error ?? failure {
            continuation.resume(throwing: error)
        } else {
            continuation.resume()
        }
    }
}
