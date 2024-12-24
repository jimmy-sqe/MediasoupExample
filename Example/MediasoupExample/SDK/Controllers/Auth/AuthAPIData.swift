//
//  AuthAPIData.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 23/12/24.
//

import Foundation

enum AuthAPIData: NetworkAPIData {
    
    case auth(AuthRequestParam, String)
    
    var path: String {
        switch self {
            case .auth(_, let wsToken):
                return "v1/widget/website-token/\(wsToken)/auth"
        }
    }
    
    var method: NetworkHTTPMethod {
        switch self {
        case .auth:
            return .post
        }
    }
    
    var parameters: NetworkRequestParams {
        switch self {
        case .auth(let payload, _):
            return NetworkRequestParams(bodyParameters: payload.asDictionary())
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .auth:
            return nil
        }
    }
    
    var headerContentType: NetworkHeaderContentType {
        switch self {
        case .auth:
            return .json
        }
    }
    
}
