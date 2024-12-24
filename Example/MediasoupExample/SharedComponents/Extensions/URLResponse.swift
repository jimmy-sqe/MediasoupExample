//
//  URLResponse.swift
//  SqeMpSDK
//
//  Created by Jimmy Suhartono on 03/10/24.
//

import Foundation

extension URLResponse {
    
    var code: Int {
        return (self as? HTTPURLResponse)?.statusCode ?? 0
    }
    
}
