import Foundation
import WineLauncherCore

/// Turns the core's typed errors into text a person can act on.
enum ErrorMessage {
    static func describe(_ error: any Error) -> String {
        switch error {
        case let error as BottleManagerError:
            switch error {
            case .commandFailed(let step, let exitCode, let message):
                return failure("\(step) failed (exit code \(exitCode))", detail: message)
            }
        case let error as RecipeError:
            switch error {
            case .stepFailed(let index, let exitCode, let message):
                return failure("Installer step \(index + 1) failed (exit code \(exitCode))", detail: message)
            case .invalidFileName(let name):
                return "The recipe uses an invalid file name: \(name)"
            }
        case let error as RuntimeInstallerError:
            switch error {
            case .wineExecutableNotFound:
                return "The downloaded Wine archive does not contain a wine executable."
            }
        case let error as DownloadError:
            switch error {
            case .badStatus(let status):
                return "The download failed with HTTP status \(status)."
            }
        case let error as ArchiveError:
            switch error {
            case .extractionFailed(let exitCode, let message):
                return failure("Unpacking the archive failed (exit code \(exitCode))", detail: message)
            }
        case let error as BottleStoreError:
            switch error {
            case .invalidName:
                return "The bottle needs a name."
            case .notFound:
                return "The bottle no longer exists on disk."
            }
        default:
            return error.localizedDescription
        }
    }

    private static func failure(_ summary: String, detail: String) -> String {
        detail.isEmpty ? summary : "\(summary): \(detail)"
    }
}
