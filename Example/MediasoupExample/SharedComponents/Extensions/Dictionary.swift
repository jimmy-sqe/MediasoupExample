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
}
