//
//  SqeCommonEnvironment.swift
//  SqeOcrFramework
//
//  Created by Samuel Maynard on 11/07/24.
//

import Foundation

public enum SqeCommonEnvironment: String {
    case development
    case staging
    case production
    
    public var apiBaseUrl: URL {
        switch self {
        case .development:
            return .httpsURL(from: "api-dev.simas-id.com")
        case .staging:
            return .httpsURL(from: "api-stg.simas-id.com")
        case .production:
            return .httpsURL(from: "api.simas-id.com")
        }
    }
    
}
