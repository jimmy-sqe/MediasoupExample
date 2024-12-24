//
//  Auth.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 23/12/24.
//

protocol AuthControllerProtocol {
    func doAuth(requestParam: AuthRequestParam,
                completion: @escaping (Result<Auth, NetworkError>) -> Void)
}

class AuthController: AuthControllerProtocol {
    
    private let baseUrl: String
    private let wsToken: String
    private let loggerController: LoggerControllerProtocol
    private let apiClient: NetworkAPIClient

    init(baseUrl: String,
         wsToken: String,
         loggerController: LoggerControllerProtocol,
         apiClient: NetworkAPIClient? = nil) {
        self.baseUrl = baseUrl
        self.wsToken = wsToken
        self.loggerController = loggerController
        self.apiClient = apiClient ?? NetworkAPIClientImpl()
    }
    
    func doAuth(requestParam: AuthRequestParam, completion: @escaping (Result<Auth, NetworkError>) -> Void) {
        self.loggerController.sendLog(name: "API:doAuth", properties: nil)
        
        let apiData = AuthAPIData.auth(requestParam, wsToken)
        apiClient.call(request: apiData, basePath: baseUrl, keyDecodingStrategy: .convertFromSnakeCase) { [weak self] (result: Result<Auth, NetworkError>) in
            switch result {
            case .success(let auth):
                self?.loggerController.sendLog(name: "API:doAuth succeed", properties: ["token": auth.token])
                completion(.success(auth))
            case .failure(let error):
                self?.loggerController.sendLog(name: "API:doAuth failed", properties: ["error": error.errorDescription ?? "unknown"])
                completion(.failure(error))
            }
        }
    }
    
}
