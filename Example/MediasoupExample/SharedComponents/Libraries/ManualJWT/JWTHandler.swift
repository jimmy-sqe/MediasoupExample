//
//  JWTHandler.swift
//  sqeid
//
//  Created by Marthin Satrya Pasaribu on 03/10/23.
//

import Foundation
import CommonCrypto

struct JWTHandler {
    var header: [String: Any] = ["alg": "HS256", "typ": "JWT"]
    var payload: [String: Any]
    var secret: String

    func encode() -> String? {
       
        let headerEncode = header.encodedBase64URLSafe ?? ""
        let claimEncode = payload.encodedBase64URLSafe ?? ""
        
        let signingInput = headerEncode + "." + claimEncode
        
        let secret = Data(secret.utf8)
        guard let signature = hmac256(signingInput: signingInput, secret: secret) else {
            return nil
        }
        let signatureEncode = signature.encodeBase64URLSafe()
        
        return signingInput + "." + signatureEncode
    }
   
    
    func hmac256(signingInput: String, secret: Data) -> Data? {
        guard #available(macOS 10.12, iOS 10.0, *) else {
            return nil
        }
        
        guard let data = signingInput.data(using: .utf8) else {
            return nil
        }
        
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
               secret.withUnsafeBytes { $0.baseAddress! },
               secret.count,
               data.withUnsafeBytes { $0.baseAddress! },
               data.count,
               &digest)

        return Data(digest)
    }
}


