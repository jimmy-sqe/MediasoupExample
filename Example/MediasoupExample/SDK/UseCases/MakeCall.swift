//
//  MakeCall.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 23/12/24.
//

class MakeCall {
    
    var onStatusUpdated: ((String) -> Void)? = nil
    
    private var authToken: String?
    private var meetingRoomId: String?
    private let wsToken: String
    private let env: SqeCcEnvironment
    private let loggerController: LoggerControllerProtocol
    private let authController: AuthControllerProtocol
    private let conversationController: ConversationControllerProtocol
    private let webSocketController: WebSocketControllerProtocol

    init(env: SqeCcEnvironment,
         wsToken: String,
         loggerController: LoggerControllerProtocol,
         authController: AuthControllerProtocol? = nil,
         conversationController: ConversationControllerProtocol? = nil,
         webSocketController: WebSocketControllerProtocol? = nil) {
        
        self.env = env
        self.wsToken = wsToken
        self.loggerController = loggerController
        
        self.authController = authController ?? AuthController(baseUrl: env.apiBaseUrl.absoluteString, wsToken: wsToken, loggerController: loggerController)
        self.conversationController = conversationController ?? ConversationController(baseUrl: env.apiBaseUrl.absoluteString, wsToken: wsToken, loggerController: loggerController)
        self.webSocketController = webSocketController ?? WebSocketController(baseUrl: env.wsBaseUrl.absoluteString, loggerController: loggerController)
    }
    
    func setup() {
        if let webSocketController = self.webSocketController as? WebSocketController {
            webSocketController.delegate = self
        }
    }
    
    func doAuthAndConnectWebSocket(name: String, phone: String) {
        let requestParam = AuthRequestParam(name: name, phone: phone)
        authController.doAuth(requestParam: requestParam) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let auth):
                self.authToken = auth.token
                self.webSocketController.connect(wsToken: self.wsToken, cwToken: auth.token)
                self.checkStatus()
            case .failure:
                break
            }
        }
    }
    
    func selectCommunicationMode(_ communicationMode: CommunicationMode) {
        guard let authToken else { return }
        
        conversationController.selectCommunicationMode(authToken: authToken, communicationMode: .audioVideo) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(_):
                self.checkStatus()
            case .failure:
                break
            }
        }
    }
    
    func checkStatus() {
        guard let authToken else { return }
        
        conversationController.checkStatus(authToken: authToken) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let status):
                self.onStatusUpdated?(status.callJoinStatus.displayText)
            case .failure:
                break
            }
        }
    }
    
    private func createConversation() {
        guard let authToken else { return }
        
        conversationController.createConversation(authToken: authToken) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let conversation):
                self.meetingRoomId = conversation.meetingRoomId
                self.selectCommunicationMode(.audioVideo)
            case .failure:
                break
            }
            
        }
    }
    
}

extension MakeCall: WebSocketControllerDelegate {
    
    func onWebSocketConnected() {
        self.loggerController.sendLog(name: "MakeCall:OnWebSocketConnected", properties: nil)
        
        self.createConversation()
    }
    
    func onRequestToJoinApproved() {
        self.loggerController.sendLog(name: "MakeCall:OnRequestToJoinApproved", properties: nil)
    }
    
}
