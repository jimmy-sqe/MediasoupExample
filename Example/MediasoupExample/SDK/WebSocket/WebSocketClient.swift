//
//  WebSocketClient.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 24/12/24.
//

import Network
import NWWebSocket

protocol WebSocketClientDelegate: AnyObject {
    func webSocketDidConnect()
    func webSocketDidDisconnect()
    func webSocketDidAttemptBetterPathMigration()
    func webSocketDidReceiveError(errorMessage: String)
    func webSocketDidReceivePong()
    func webSocketDidReceiveMessage(message: String)
    func webSocketDidReceiveMessage(data: Data)
}

protocol WebSocketClientProtocol {
    var delegate: WebSocketClientDelegate? { get set }
    
    func connect(request: WebSocketAPIData)
    func disconnect()
    func send(request: WebSocketAPIData)
}

class WebSocketClient: WebSocketClientProtocol {
    weak var delegate: WebSocketClientDelegate?
    
    private let baseUrl: String
    private var webSocket: NWWebSocket?

    init(baseUrl: String) {
        self.baseUrl = baseUrl
    }
    
    func connect(request: WebSocketAPIData) {
        func createRequestURL(baseUrl: String, request: WebSocketAPIData) -> URL? {
            guard let url = URL(string: request.absolutePath(from: baseUrl)) else { return nil }
            return url.addParameters(request.parameters)
        }
        
        guard let webSocketUrl = createRequestURL(baseUrl: baseUrl, request: request) else { return }
        
        let webSocket = NWWebSocket(url: webSocketUrl)
        webSocket.delegate = self
        self.webSocket = webSocket
        
        webSocket.connect()
    }
    
    func disconnect() {
        webSocket?.disconnect()
    }
    
    func send(request: WebSocketAPIData) {
        guard let message = request.parameters.bodyParameters?.toJSONString() else { return }
        
        self.webSocket?.send(string: message)
    }
    
}

extension WebSocketClient: WebSocketConnectionDelegate {
    func webSocketDidConnect(connection: WebSocketConnection) {
        delegate?.webSocketDidConnect()
    }
    
    func webSocketDidDisconnect(connection: WebSocketConnection, closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        delegate?.webSocketDidDisconnect()
    }
    
    func webSocketViabilityDidChange(connection: WebSocketConnection, isViable: Bool) {
        delegate?.webSocketDidConnect()
    }
    
    func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketConnection, NWError>) {
        delegate?.webSocketDidAttemptBetterPathMigration()
    }
    
    func webSocketDidReceiveError(connection: WebSocketConnection, error: NWError) {
        delegate?.webSocketDidReceiveError(errorMessage: error.debugDescription)
    }
    
    func webSocketDidReceivePong(connection: WebSocketConnection) {
        delegate?.webSocketDidReceivePong()
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        delegate?.webSocketDidReceiveMessage(message: string)
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        delegate?.webSocketDidReceiveMessage(data: data)
    }
}
