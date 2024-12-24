//
//  NetworkConfig.swift
//  SqeIdFramework
//
//  Created by Marthin Satrya Pasaribu on 12/02/24.
//

import Foundation

enum NetworkHTTPMethod: String {
    case get
    case post
}

enum NetworkResponseDataType {
    case Data
    case JSON
}

enum NetworkEncoding: String {
    case URL
    case JSON
}

enum NetworkHeaderContentType: String {
    case json = "application/json"
    case urlEncode = "application/x-www-form-urlencoded"
}

enum NetworkHTTPHeaderKeys: String {
    case contentType = "Content-Type"
    case cookie = "Cookie"
}

struct NetworkRequestParams {
    let urlParameters: [String: Any]?
    let bodyParameters: [String: Any]?
    let bodyData: Data?
    
    init(urlParameters: [String: Any]? = nil, 
         bodyParameters: [String: Any]? = nil,
         bodyData: Data? = nil,
         contentType: NetworkHeaderContentType = .json) {
        self.urlParameters = urlParameters
        self.bodyParameters = bodyParameters
        self.bodyData = bodyData
    }
}
