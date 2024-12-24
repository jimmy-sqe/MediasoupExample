//
//  NetworkManager.swift
//  SqeIdFramework
//
//  Created by Marthin Satrya Pasaribu on 12/02/24.
//

import Foundation

#if DEBUG
let parameterPropertyKey = "id.co.sqe.parameter"
#endif

class NetworkManagerImpl: NetworkManager {
    static let shared = NetworkManagerImpl()
    private var task: URLSessionTask?
    private let deviceInfoGenerator = DeviceInfoGeneratorImpl()
    
    // Create this as private to prevent initialization multiple times
    // we can use `NetworkManagerImpl.shared`
    private init() {
    }
    
    func startRequest(request: NetworkAPIData, basePath: String, completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.timeoutIntervalForRequest = request.timeoutInMilliseconds / 1000
        urlSessionConfiguration.timeoutIntervalForResource = request.timeoutInMilliseconds / 1000
        
        let urlSession = URLSession(configuration: urlSessionConfiguration)
        
        do {
            let urlRequest = try self.createURLRequest(apiData: request, basePath: basePath)
            
            task = urlSession.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
                completion(data, response, error)
            })
            task?.resume()
        } catch {
            completion(nil, nil, error)
        }
    }
}

extension NetworkManagerImpl {
    
    func createURLRequest(apiData: NetworkAPIData, basePath: String) throws -> URLRequest {
        do {
            if let url = URL(string: apiData.absolutePath(from: basePath))  {
                
                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = apiData.method.rawValue
                self.addRequestHeaders(request: &urlRequest, requestHeaders: apiData.headers)
                self.addDeviceInfoHeaders(request: &urlRequest)
                try self.encode(request: &urlRequest, parameters: apiData.parameters, headerContentType: apiData.headerContentType)
                
                return urlRequest
            } else {
                throw NetworkError(cause: NetworkErrorCode.malformedURL, statusCode: 0)
            }
        } catch {
            throw error
        }
    }
    
    func addDeviceInfoHeaders(request: inout URLRequest) {
        if let value = deviceInfoGenerator.generateEncryptedDeviceInfo() {
            request.setValue(value, forHTTPHeaderField: "Auth-Client")
        } else {
            request.setValue(nil, forHTTPHeaderField: "Auth-Client")
        }
    }
    
    func addRequestHeaders(request: inout URLRequest, requestHeaders: [String: String]?) {
        guard let headers = requestHeaders else{
            return
        }
        for (key, value) in headers{
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
    
    func encode(request: inout URLRequest, parameters: NetworkRequestParams?, headerContentType: NetworkHeaderContentType) throws {
        
        guard let url: URL = request.url else {
            throw NetworkError(cause: NetworkErrorCode.malformedURL, statusCode: 0)
        }
        guard let parameters = parameters else{
            return
        }
        
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let urlParams = parameters.urlParameters, !urlParams.isEmpty{
            
            urlComponents.queryItems = [URLQueryItem]()
            
            for (key, value) in urlParams{
                if let valueString = value as? String {
                    let queryItem = URLQueryItem(name: key, value: valueString)
                    urlComponents.queryItems?.append(queryItem)
                }
            }
            
            urlComponents.percentEncodedQuery = urlComponents.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            request.url = urlComponents.url
        }
        
        if let bodyData = parameters.bodyData {
            request.httpBody = bodyData
            request.setValue(headerContentType.rawValue, forHTTPHeaderField: NetworkHTTPHeaderKeys.contentType.rawValue)
        } else if let bodyParams = parameters.bodyParameters, !bodyParams.isEmpty {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: bodyParams, options: [.sortedKeys, .withoutEscapingSlashes])
                request.httpBody = jsonData
                request.setValue(headerContentType.rawValue, forHTTPHeaderField: NetworkHTTPHeaderKeys.contentType.rawValue)
            } catch {
                throw NetworkError(cause: NetworkErrorCode.parameterEncodingFailed, statusCode: 0)
            }
        }
    }
}
