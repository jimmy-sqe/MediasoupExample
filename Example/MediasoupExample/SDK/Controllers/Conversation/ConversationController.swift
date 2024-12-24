//
//  Auth.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 23/12/24.
//

protocol ConversationControllerProtocol {
    func createConversation(authToken: String, completion: @escaping (Result<Conversation, NetworkError>) -> Void)
    func selectCommunicationMode(authToken: String, communicationMode: CommunicationMode, completion: @escaping (Result<EmptyResponse, NetworkError>) -> Void)
    func checkStatus(authToken: String, completion: @escaping (Result<ConversationStatus, NetworkError>) -> Void)
}

class ConversationController: ConversationControllerProtocol {
    
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
    
    func createConversation(authToken: String, completion: @escaping (Result<Conversation, NetworkError>) -> Void) {
        self.loggerController.sendLog(name: "API:createConversation", properties: nil)
        
        let apiData = ConversationAPIData.createConversation(authToken, wsToken)
        apiClient.call(request: apiData, basePath: baseUrl, keyDecodingStrategy: .convertFromSnakeCase) { [weak self] (result: Result<ConversationData, NetworkError>) in
            switch result {
            case .success(let conversationData):
                if let firstConversation = conversationData.data.first {
                    self?.loggerController.sendLog(name: "API:createConversation succeed", properties: ["meetingRoomId": firstConversation.meetingRoomId])
                    completion(.success(firstConversation))
                } else {
                    self?.loggerController.sendLog(name: "API:createConversation failed", properties: ["error": "Conversation is empty"])
                }
            case .failure(let error):
                self?.loggerController.sendLog(name: "API:createConversation failed", properties: ["error": error.errorDescription ?? "unknown"])
                completion(.failure(error))
            }
        }
    }
    
    func selectCommunicationMode(authToken: String, communicationMode: CommunicationMode, completion: @escaping (Result<EmptyResponse, NetworkError>) -> Void) {
        self.loggerController.sendLog(name: "API:selectCommunicationMode", properties: nil)
        
        let apiData = ConversationAPIData.selectCommunicationMode(authToken, wsToken, communicationMode)
        apiClient.call(request: apiData, basePath: baseUrl, keyDecodingStrategy: .convertFromSnakeCase) { [weak self] (result: Result<EmptyResponse, NetworkError>) in
            switch result {
            case .success(let emptyResponse):
                self?.loggerController.sendLog(name: "API:selectCommunicationMode succeed", properties: nil)
                completion(.success(emptyResponse))
            case .failure(let error):
                if error.statusCode == 200 {
                    self?.loggerController.sendLog(name: "API:selectCommunicationMode succeed", properties: nil)
                    completion(.success(EmptyResponse()))
                } else {
                    self?.loggerController.sendLog(name: "API:selectCommunicationMode failed", properties: ["error": error.errorDescription ?? "unknown"])
                    completion(.failure(error))
                }
            }
        }
    }
    
    func checkStatus(authToken: String, completion: @escaping (Result<ConversationStatus, NetworkError>) -> Void) {
        self.loggerController.sendLog(name: "API:checkStatus", properties: nil)
        
        let apiData = ConversationAPIData.checkStatus(authToken)
        apiClient.call(request: apiData, basePath: baseUrl, keyDecodingStrategy: .convertFromSnakeCase) { [weak self] (result: Result<ConversationStatus, NetworkError>) in
            switch result {
            case .success(let conversationStatus):
                self?.loggerController.sendLog(name: "API:checkStatus succeed", properties: ["meetingRoomId": conversationStatus.meetingRoomId])
                completion(.success(conversationStatus))
            case .failure(let error):
                self?.loggerController.sendLog(name: "API:checkStatus failed", properties: ["error": error.errorDescription ?? "unknown"])
                completion(.failure(error))
            }
        }
    }
    
}
