//
//  WebSocketController.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 24/12/24.
//

protocol WebSocketControllerDelegate: AnyObject {
}

protocol WebSocketControllerProtocol {
    
    func connect(wsToken: String, cwToken: String)
    
}

class WebSocketController: WebSocketControllerProtocol {
    
    weak var delegate: WebSocketControllerDelegate?
    
    private let loggerController: LoggerControllerProtocol
    private let webSocketClient: WebSocketClientProtocol

    init(baseUrl: String,
         loggerController: LoggerControllerProtocol,
         webSocketClient: WebSocketClientProtocol? = nil) {
         
        self.loggerController = loggerController
        self.webSocketClient = webSocketClient ?? WebSocketClient(baseUrl: baseUrl)
    }
    
    func connect(wsToken: String, cwToken: String) {
        let request: WebSocketAPIData = .connect(wsToken, cwToken)
        
        self.loggerController.sendLog(name: "WebSocket:Connect", properties: nil)
        self.webSocketClient.connect(request: request)
        
        if let webSocketClient = self.webSocketClient as? WebSocketClient {
            webSocketClient.delegate = self
        }
    }
    
}

extension WebSocketController: WebSocketClientDelegate {
    func webSocketDidConnect() {
        self.loggerController.sendLog(name: "WebSocket:DidConnect", properties: nil)
    }
    
    func webSocketDidReceiveError(errorMessage: String) {
        self.loggerController.sendLog(name: "WebSocket:DidReceiveError", properties: [
            "errorMessage": errorMessage
        ])
    }
    
    func webSocketDidReceiveMessage(message: String) {
        self.loggerController.sendLog(name: "WebSocket:DidReceiveMessage", properties: [
            "message": message
        ])
    }
}
