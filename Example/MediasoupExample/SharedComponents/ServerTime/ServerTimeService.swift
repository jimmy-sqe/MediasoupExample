//
//  ServerTimeService.swift
//  sqeid
//
//  Created by Jimmy Suhartono on 01/11/23.
//

import Foundation

protocol ServerTimeService {
    func getTime(timeoutInMilliseconds: TimeInterval, completion: @escaping (Result<Time, NetworkError>) -> Void)
}

class ServerTimeServiceImpl: ServerTimeService {
    let baseUrl: String
    let apiClient: NetworkAPIClient
    
    init(baseUrl: String,
         apiClient: NetworkAPIClient? = nil) {
        self.baseUrl = baseUrl
        self.apiClient = apiClient ?? NetworkAPIClientImpl()
    }
    
    func getTime(timeoutInMilliseconds: TimeInterval, completion: @escaping (Result<Time, NetworkError>) -> Void) {
        let apiData = SDKConfigurationAPIData.getTime(timeoutInMilliseconds)
        
        apiClient.call(request: apiData, basePath: baseUrl) { (result: Result<Time, NetworkError>) in
            switch result {
            case .success:
                completion(result)
                break
            case .failure:
                let now = Time(serverTime: Date())
                completion(.success(now))
                break
            }
        }
    }
}
