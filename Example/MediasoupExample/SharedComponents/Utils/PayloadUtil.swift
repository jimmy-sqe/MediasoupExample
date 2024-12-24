//
//  PayloadUtil.swift
//  sqeid
//
//  Created by Jimmy Suhartono on 19/06/23.
//

import Foundation

class PayloadUtil {
    
    static func createTandaTangan(payload: [String: Any], rahasia: String) -> String? {
        let resp = JWTHandler(payload: payload, secret: rahasia)
        let encode = resp.encode()
        let signature = encode?.components(separatedBy: ".").last
        return signature
    }
    
    static func createSecretKey(clientId: String, mobileClientId: String, currentTime: Date) -> String {
        let timestamp: Int64 = Int64(currentTime.roundDownSecondsToZero().timeIntervalSince1970)
        return "\(mobileClientId)#\(clientId)#\(timestamp)"
    }
    
}
