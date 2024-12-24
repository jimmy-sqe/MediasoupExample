//
//  SDKConfigurationAPIData.swift
//  SqeIdFramework
//
//  Created by Marthin Satrya Pasaribu on 05/02/24.
//

import Foundation

enum SDKConfigurationAPIData: NetworkAPIData {
    case getConfiguration(ClientConfigRequestParam, String?)
    case getTime(TimeInterval)
    
    var path: String {
        switch self {
        case .getConfiguration:
            return "v1/mobile-config"
        case .getTime:
            return "time"
        }
    }
    
    var method: NetworkHTTPMethod {
        switch self {
        case .getConfiguration, .getTime:
            return .get
        }
    }
    
    var parameters: NetworkRequestParams {
        switch self {
        case .getConfiguration(let dataModel, _):
            return NetworkRequestParams(urlParameters: dataModel.asDictionary(), bodyParameters: nil)
        case .getTime:
            return NetworkRequestParams(urlParameters: nil, bodyParameters: nil)
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .getConfiguration(_ ,let signature):
            if let signature = signature {
                return ["x-signature" : signature]
            }
            return nil
        case .getTime:
            return nil
        }
    }
    
    var headerContentType: NetworkHeaderContentType {
        switch self {
        case .getConfiguration, .getTime:
            return .json
        }
    }
    
    var timeoutInMilliseconds: TimeInterval {
        switch self {
        case .getTime(let timeoutInMilliseconds):
            return timeoutInMilliseconds
        default:
            return Constants.DefaultNetworkTimeoutInMilliseconds
        }
    }
}
