//
//  SqeCcEnvironment.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 23/12/24.
//

import Foundation

public enum SqeCcEnvironment: String {
    case staging
    case production

    var apiBaseUrl: URL {
        switch self {
        case .staging:
            return .httpsURL(from: "sqecc-be.stg.squantumengine.com")
        case .production:
            return .httpsURL(from: "sqecc-be.squantumengine.com")
        }
    }
    
    var wsBaseUrl: URL {
        switch self {
        case .staging:
            return .wssURL(from: "sqecc-be.stg.squantumengine.com")
        case .production:
            return .wssURL(from: "sqecc-be.squantumengine.com")
        }
    }
    
}
