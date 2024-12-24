//
//  String.swift
//  SqeOcrFramework
//
//  Created by Jimmy Suhartono on 16/04/24.
//

import CryptoKit
import Foundation

/// Adds a utility method for decoding base64url-encoded data, like ID tokens.
public extension String {

    init?(_ data: Data?) {
        guard let data = data else { return nil }
        self.init(data: data, encoding: .utf8)
    }
    
    func encodeBase64URLSafe() -> String {
        let data = Data(self.utf8)
        return data.encodeBase64URLSafe()
    }

    func encodeBase64() -> String {
        let data = Data(self.utf8)
        return data.encodeBase64()
    }
    
    func encodeSHA256() -> String? {
        guard let stringData = self.data(using: .utf8) else { return nil }
        
        let digest = SHA256.hash(data: stringData)
        return digest.hexStr
    }

    func decodeBase64URLSafe() -> Data? {
        let lengthMultiple = 4
        let paddingLength = lengthMultiple - count % lengthMultiple
        let padding = (paddingLength < lengthMultiple) ? String(repeating: "=", count: paddingLength) : ""
        let base64EncodedString = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            + padding
        return Data(base64Encoded: base64EncodedString)
    }
    
    func toDate() -> Date? {
        guard let interval = Double(self) else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            formatter.timeZone = TimeZone(identifier: "UTC")
            return formatter.date(from: self)
        }
        return Date(timeIntervalSince1970: interval)
    }
    
    func split(to length: Int) -> [String] {
        
        var result = [String]()
        var collectedCharacters = [Character]()
        collectedCharacters.reserveCapacity(length)
        var count = 0
        
        for character in self {
            collectedCharacters.append(character)
            count += 1
            if count == length {
                // Reached the desired length
                count = 0
                result.append(String(collectedCharacters))
                collectedCharacters.removeAll(keepingCapacity: true)
            }
        }
        
        // Append the remainder
        if !collectedCharacters.isEmpty {
            result.append(String(collectedCharacters))
        }
        
        return result
    }
    
    func snakeCased() -> String {
        return self.reduce(into: "") { result, char in
            if char.isUppercase {
                result += "_"
                result.append(char.lowercased())
            } else {
                result.append(char)
            }
        }
    }
}
