//
//  MakeCall.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 23/12/24.
//

class MakeCall {
    
    private var authToken: String?
    private let wsToken: String
    private let env: SqeCcEnvironment
    private let loggerController: LoggerControllerProtocol
    private let authController: AuthControllerProtocol
    private let webSocketController: WebSocketControllerProtocol

    init(env: SqeCcEnvironment,
         wsToken: String,
         loggerController: LoggerControllerProtocol,
         authController: AuthControllerProtocol? = nil,
         webSocketController: WebSocketControllerProtocol? = nil) {
        
        self.env = env
        self.wsToken = wsToken
        self.loggerController = loggerController
        
        self.authController = authController ?? AuthController(baseUrl: env.apiBaseUrl.absoluteString, wsToken: wsToken, loggerController: loggerController)
        self.webSocketController = webSocketController ?? WebSocketController(baseUrl: env.wsBaseUrl.absoluteString, loggerController: loggerController)
    }
    
    func doAuthAndConnectWebSocket(name: String, phone: String) {
        let requestParam = AuthRequestParam(name: name, phone: phone)
        authController.doAuth(requestParam: requestParam) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let auth):
                self.webSocketController.connect(wsToken: self.wsToken, cwToken: auth.token)
            case .failure:
                break
            }
        }
    }
    
}
