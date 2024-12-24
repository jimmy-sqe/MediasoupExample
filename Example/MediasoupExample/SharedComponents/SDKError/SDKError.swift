import Foundation

let unknownError = "sqe.sdk.internal_error.unknown"
let nonJSONError = "sqe.sdk.internal_error.plain"
let emptyBodyError = "sqe.sdk.internal_error.empty"

/// Generic representation of errors.
public protocol SDKError: LocalizedError, CustomDebugStringConvertible {

    /// The underlying `Error` value, if any.
    var cause: Error? { get }
}

public extension SDKError {

    /// The underlying `Error` value, if any. Defaults to `nil`.
    var cause: Error? { return nil }

    /// Description of the error.
    ///
    /// - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
    var localizedDescription: String { return self.debugDescription }

    /// Description of the error.
    ///
    /// - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
    var errorDescription: String? { return self.debugDescription }

}

extension SDKError {

    func appendCause(to errorMessage: String) -> String {
        guard let cause = self.cause else {
            return errorMessage
        }

        let separator = errorMessage.hasSuffix(".") ? "" : "."
        return "\(errorMessage)\(separator) CAUSE: \(String(describing: cause))"
    }

}

