//
//  SDKConfigurationService.swift
//  SqeIdFramework
//
//  Created by Marthin Satrya Pasaribu on 05/02/24.
//

import Foundation

protocol SDKConfigurationService {
    func getSdkConfiguration(requestParam: ClientConfigRequestParam,
                             signature: String?,
                             completion: @escaping (Result<ClientConfigResponse, NetworkError>) -> Void)
}

class SDKConfigurationServiceImpl: SDKConfigurationService {
    let baseUrl: String
    let apiClient: NetworkAPIClient
    
    init(baseUrl: String,
         apiClient: NetworkAPIClient?) {
        self.baseUrl = baseUrl
        self.apiClient = apiClient ?? NetworkAPIClientImpl()
    }
    
    func getSdkConfiguration(requestParam: ClientConfigRequestParam,
                             signature: String?,
                             completion: @escaping (Result<ClientConfigResponse, NetworkError>) -> Void) {
        let apiData = SDKConfigurationAPIData.getConfiguration(requestParam, signature)
        
        apiClient.call(request: apiData, basePath: baseUrl, keyDecodingStrategy: .convertFromSnakeCase, completionHandler: completion)
    }
}
