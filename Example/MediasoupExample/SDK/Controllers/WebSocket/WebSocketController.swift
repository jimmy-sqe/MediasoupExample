//
//  WebSocketController.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 24/12/24.
//

import Foundation

protocol WebSocketControllerDelegate: AnyObject {
    
    func onWebSocketConnected()
    
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
        
        if let messageData = message.data(using: .utf8) {
            let decoder = JSONDecoder()
            
            do {
                let webSocketMessage = try decoder.decode(WebSocketMessage.self, from: messageData)
                self.triggerEvent(event: webSocketMessage.event)
            } catch(let error) {
                self.loggerController.sendLog(name: "WebSocket:DidReceiveMessage:DecodeFailed", properties: [
                    "error": error.localizedDescription
                ])
            }
        }
    }
    
    private func triggerEvent(event: WebSocketEvent) {
        switch event {
            case .webSocketConnected:
                delegate?.onWebSocketConnected()
                break
            case .unknown:
                break
        }
    }
}
