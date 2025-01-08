//
//  NetworkAPIClient.swift
//  SqeIdFramework
//
//  Created by Marthin Satrya Pasaribu on 12/02/24.
//

import Foundation

class NetworkAPIClientImpl: NetworkAPIClient {
    
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager = NetworkManagerImpl.shared) {
        self.networkManager = networkManager
    }
    
    func call<T: Codable>(request: NetworkAPIData, basePath: String, completionHandler: @escaping ((Result<T, NetworkError>) -> Void)) {
        self.networkManager.startRequest(request: request, basePath: basePath) { (data, response, error) in
            
            if let error = error {
                let errorType = NetworkError(cause: error, statusCode: response?.code ?? 0)
                completionHandler(.failure(errorType))
                return
            }
            
            guard let responseData = response as? HTTPURLResponse,
                let receivedData = data else {
                
                let errorType = NetworkError(cause: NetworkErrorCode.noResponseData, statusCode: response?.code ?? 0)
                    completionHandler(.failure(errorType))
                    return
            }
            let response: Response<NetworkError> = Response(data: receivedData, response: responseData, error: error)
            
            do {
                if let dictionary = try response.result() as? [String: Any] {
                    let data = try JSONSerialization.data(withJSONObject: dictionary)
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    decoder.dateDecodingStrategy = .secondsSince1970
                    let decodedObject = try decoder.decode(T.self, from: data)
                    completionHandler(.success(decodedObject))
                } else {
                    completionHandler(.failure(NetworkError(from: response)))
                }
            } catch let error as NetworkError {
                if error.shouldSendErrorEventToSentry() {
                    CrashReporterImpl.sendReport(subject: error.code, body: error.debugDescription, info: error.info)
                }
                completionHandler(.failure(error))
            } catch {
                let networkError = NetworkError(cause: error, statusCode: response.response?.statusCode ?? 0)
                if networkError.shouldSendErrorEventToSentry() {
                    CrashReporterImpl.sendReport(subject: networkError.code, body: networkError.debugDescription, info: networkError.info)
                }
                completionHandler(.failure(networkError))
            }
        }
    }
}
