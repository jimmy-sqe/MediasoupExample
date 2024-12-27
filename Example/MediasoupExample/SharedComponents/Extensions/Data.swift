//
//  Data.swift
//  sqekyc
//
//  Created by Jimmy Suhartono on 20/07/23.
//

import Foundation
import CryptoKit

public extension Data {

    func encodeBase64URLSafe() -> String {
        return self
            .base64EncodedString(options: [])
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    func encodeBase64() -> String {
        return self
            .base64EncodedString(options: [])
    }
    
    func toDictionary() -> [String: Any]? {
        return try? JSONSerialization.jsonObject(with: self, options: []) as? [String: Any]
    }
    
}
