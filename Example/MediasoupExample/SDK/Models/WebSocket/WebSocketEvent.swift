//
//  Event.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 24/12/24.
//

enum WebSocketEvent: String, Codable {
    
    case webSocketConnected = "WEBSOCKET_CONNECTED"
    case unknown = "UNKNOWN"

}
