//
//  Digest.swift
//  SqeIdSDK
//
//  Created by Jimmy Suhartono on 25/10/24.
//

import CryptoKit
import Foundation

extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }

    var hexStr: String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }
}
