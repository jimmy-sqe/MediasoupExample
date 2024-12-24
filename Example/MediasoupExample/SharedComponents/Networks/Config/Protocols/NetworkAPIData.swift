//
//  NetworkAPIData.swift
//  SqeIdFramework
//
//  Created by Marthin Satrya Pasaribu on 12/02/24.
//

import Foundation

protocol NetworkAPIData {
    var path: String { get }
    var parameters: NetworkRequestParams { get }
    var method: NetworkHTTPMethod { get }
    var headers: [String: String]? { get }
    var headerContentType: NetworkHeaderContentType { get }
    var timeoutInMilliseconds: TimeInterval { get }
    func absolutePath(from basePath: String) -> String
}

extension NetworkAPIData {
    var parameters: NetworkRequestParams {
        NetworkRequestParams()
    }
    
    var method: NetworkHTTPMethod {
        .get
    }
    
    var headers: [String: String]? {
        nil
    }
    
    var headerContentType: NetworkHeaderContentType {
        .json
    }
    
    var timeoutInMilliseconds: TimeInterval {
        return Constants.DefaultNetworkTimeoutInMilliseconds
    }
    
    func absolutePath(from basePath: String) -> String {
        return basePath + path
    }
}
