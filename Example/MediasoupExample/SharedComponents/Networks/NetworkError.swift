//
//  NetworkError.swift
//  SqeIdFramework
//
//  Created by Marthin Satrya Pasaribu on 12/02/24.
//

import Foundation

public enum NetworkErrorCode: Error {
    case malformedURL
    case parameterEncodingFailed
    case noResponseData
    case unableToDecodeResponseData
    case badRequest
    case failed
    
    func statusCode() -> Int {
        switch self {
        case .malformedURL:
            return 1
        case .parameterEncodingFailed:
            return 2
        case .noResponseData:
            return 3
        case .unableToDecodeResponseData:
            return 4
        case .badRequest:
            return 5
        case .failed:
            return 6
        }
    }
}

public struct NetworkError: APIError {

    /// Additional information about the error.
    public let info: [String: Any]

    /// Creates an error from a JSON response.
    ///
    /// - Parameters:
    ///   - info:       JSON response.
    ///   - statusCode: HTTP status code of the response.
    ///
    /// - Returns: A new `NetworkError`.
    public init(info: [String: Any], statusCode: Int) {
        var values = info
        values["statusCode"] = statusCode
        self.info = values
        self.statusCode = statusCode
    }

    /// HTTP status code of the response.
    public let statusCode: Int

    /// The underlying `Error` value, if any. Defaults to `nil`.
    public var cause: Error? {
        return self.info["cause"] as? Error
    }

    /// The code of the error as a string.
    public var code: String {
        let code = self.info["error"] ?? self.info["code"]
        return code as? String ?? unknownError
    }

    /// Description of the error.
    ///
    /// - Important: You should avoid displaying the error description to the user, it's meant for **debugging** only.
    public var debugDescription: String {
        self.appendCause(to: self.message)
    }
    
    public var message: String {
        let description = self.info["description"] ?? self.info["error_description"]

        if let string = description as? String {
            return string
        }
        if self.code == unknownError {
            return "Failed with unknown error \(self.info)."
        }

        return "Received error with code \(self.code)."
    }
}

// MARK: - Equatable

extension NetworkError: Equatable {

    /// Conformance to `Equatable`.
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        return lhs.code == rhs.code
            && lhs.statusCode == rhs.statusCode
            && lhs.localizedDescription == rhs.localizedDescription
    }

}

extension NetworkError {
    func shouldSendErrorEventToSentry() -> Bool {
        switch(code) {
        case "unexpected_error",
            "invalid_request_body",
            "invalid_client_credential",
            "invalid_user_session",
            "max_refresh_token_exceed",
            "invalid_refresh_token",
            "invalid_token":
            return true
        default:
            return false
        }
    }
}
