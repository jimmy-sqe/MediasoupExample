//
//  WebSocketController.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 24/12/24.
//

import Foundation

protocol WebSocketControllerDelegate: AnyObject {
    
    func onWebSocketConnected()
    func onRequestToJoinApproved()
    func onUserJoinedMeetingRoom()
    func onRTPCapabilitiesReceived(rtpCapabilities: String)
    func onWebRTCTransportReceived(originalRequestId: String, id: String, iceParameters: String, iceCandidates: String, dtlsParameters: String)

}

protocol WebSocketControllerProtocol {
    
    var delegate: WebSocketControllerDelegate? { get set }
    
    func connect(wsToken: String, cwToken: String)
    func disconnect()
    func joinMeetingRoom(originalRequestId: String, meetingRoomId: String)
    func getRTPCapabilities(originalRequestId: String, meetingRoomId: String)
    func createWebRTCTransport(originalRequestId: String, meetingRoomId: String)

}

enum WebSocketRequestType {
    case webRTCSendTransport
    case webRTCReceiveTransport
}

class WebSocketController: WebSocketControllerProtocol {
    
    weak var delegate: WebSocketControllerDelegate?
    
    private let loggerController: LoggerControllerProtocol
    private var webSocketClient: WebSocketClientProtocol

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
        self.webSocketClient.delegate = self
    }
    
    func disconnect() {
        self.webSocketClient.disconnect()
    }
    
    func joinMeetingRoom(originalRequestId: String, meetingRoomId: String) {
        let request: WebSocketAPIData = .sendEvent(.joinMeetingRoom, [
            "originalRequestId": originalRequestId,
            "meetingRoomId": meetingRoomId
        ])
        
        self.loggerController.sendLog(name: "WebSocket:Send:\(request.parameters.bodyParameters?["event"] ?? "unknown")", properties: request.parameters.bodyParameters)
        self.webSocketClient.send(request: request)
    }
    
    func getRTPCapabilities(originalRequestId: String, meetingRoomId: String) {
        let request: WebSocketAPIData = .sendEvent(.getRTPCabilities, [
            "originalRequestId": originalRequestId,
            "meetingRoomId": meetingRoomId
        ])
        
        self.loggerController.sendLog(name: "WebSocket:Send:\(request.parameters.bodyParameters?["event"] ?? "unknown")", properties: request.parameters.bodyParameters)
        self.webSocketClient.send(request: request)
    }
    
    func createWebRTCTransport(originalRequestId: String, meetingRoomId: String) {
        let request: WebSocketAPIData = .sendEvent(.createWebRTCTransport, [
            "originalRequestId": originalRequestId,
            "meetingRoomId": meetingRoomId
        ])
        
        self.loggerController.sendLog(name: "WebSocket:Send:\(request.parameters.bodyParameters?["event"] ?? "unknown")", properties: request.parameters.bodyParameters)
        self.webSocketClient.send(request: request)
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
            
            do {
                let webSocketReceiveMessage = try JSONDecoder().decode(WebSocketReceiveMessage.self, from: messageData)
                
                let jsonObject = messageData.toDictionary()
                let data = jsonObject?["data"] as? [String: Any]
                
                self.readMessage(message: webSocketReceiveMessage, data: data)
            } catch(let error) {
                self.loggerController.sendLog(name: "WebSocket:DidReceiveMessage:DecodeMessageFailed", properties: [
                    "error": error.localizedDescription
                ])
            }
        }
    }
    
    private func readMessage(message: WebSocketReceiveMessage, data: [String: Any]?) {
        switch message.event {
        case .webSocketConnected:
            delegate?.onWebSocketConnected()
        case .requestToJoinApproved:
            delegate?.onRequestToJoinApproved()
        case .userJoinedMeetingRoom:
            delegate?.onUserJoinedMeetingRoom()
        case .rtpCapabilities:
            let rtpCapabilitiesString = (data?["rtpCapabilities"] as? [String: Any])?.toJSONString()
            delegate?.onRTPCapabilitiesReceived(rtpCapabilities: rtpCapabilitiesString ?? "unknown")
        case .webRTCTransport:
            let webRTCResponse = data?["webrtcResponse"] as? [String: Any]
            
            let id = webRTCResponse?["id"] as? String
            let iceParameters = (webRTCResponse?["iceParameters"] as? [String: Any])?.toJSONString()
            let iceCandidates = (webRTCResponse?["iceCandidates"] as? [String: Any])?.toJSONString()
            let dtlsParameters = (webRTCResponse?["dtlsParameters"] as? [String: Any])?.toJSONString()
            delegate?.onWebRTCTransportReceived(
                originalRequestId: message.originalRequestId ?? "unknown",
                id: id ?? "unknown",
                iceParameters: iceParameters ?? "unknown",
                iceCandidates: iceCandidates ?? "unknown",
                dtlsParameters: dtlsParameters ?? "unknown"
            )
        case .unknown:
            break
        }
    }
    
}
