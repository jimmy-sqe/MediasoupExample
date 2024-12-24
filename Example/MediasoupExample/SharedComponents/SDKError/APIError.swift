//
//  APIError.swift
//  sqeid-sdk
//
//  Created by Jimmy Wu on 06/01/23.
//

import Foundation

/// Generic representation of SqeId API errors.
public protocol APIError: SDKError {

    /// Additional information about the error.
    var info: [String: Any] { get }

    /// The code name of the error as a string.
    var code: String { get }

    /// HTTP status code of the response.
    var statusCode: Int { get }

    /// Creates an error from a JSON response.
    ///
    /// - Parameters:
    ///   - info:       JSON response from SqeId.
    ///   - statusCode: HTTP status code of the response.
    ///
    /// - Returns: A new `APIError`.
    init(info: [String: Any], statusCode: Int)

}

extension APIError {

    init(info: [String: Any], statusCode: Int) {
        self.init(info: info, statusCode: statusCode)
    }

    init(cause error: Error, statusCode: Int) {
        func isNetworkError() -> (status: Bool, message: String?) {
            guard let error = error as? URLError else {
                return (false, nil)
            }

            let networkErrorCodes: [URLError.Code] = [
                .notConnectedToInternet,
                .networkConnectionLost,
                .dnsLookupFailed,
                .cannotFindHost,
                .cannotConnectToHost,
                .timedOut,
                .internationalRoamingOff,
                .callIsActive
            ]
            let message = error.localizedDescription
            return (status: networkErrorCodes.contains(error.code), message: message)
        }
        
        let info: [String: Any]
        
        let isNetworkError = isNetworkError()
        if isNetworkError.status {
            let networkErrorCode = "network_error"
            info = [
                "code": networkErrorCode,
                "description": isNetworkError.message ?? "",
                "cause": error
            ]
        } else {
            info = [
                "code": nonJSONError,
                "description": "Unable to complete the operation.",
                "cause": error
            ]
        }
        
        self.init(info: info, statusCode: statusCode)

    }

    init(description: String?, statusCode: Int) {
        let info: [String: Any] = [
            "code": description != nil ? nonJSONError : emptyBodyError,
            "description": description ?? "Empty response body."
        ]
        self.init(info: info, statusCode: statusCode)
    }

    init(from response: Response<Self>) {
        self.init(description: String(response.data), statusCode: response.response?.statusCode ?? 0)
    }

}

