//
//  Dictionary.swift
//  sqeid
//
//  Created by Jimmy Suhartono on 20/06/23.
//

import Foundation

extension Dictionary {
    var encodedBase64URLSafe: String? {
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: self,
                                                            options: [.sortedKeys, .withoutEscapingSlashes]) else {
            return nil
        }
        
        return theJSONData.encodeBase64URLSafe()
    }
    
    func toData() -> Data? {
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: self) else {
            return nil
        }
        
        return theJSONData
    }
    
    func toJSONString() -> String? {
        guard let theJSONData = toData() else {
            return nil
        }
        
        return String(data: theJSONData, encoding: .utf8)
    }
}
