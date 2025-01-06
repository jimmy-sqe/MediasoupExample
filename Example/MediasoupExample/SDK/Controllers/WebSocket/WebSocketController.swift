//
//  WebSocketController.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 24/12/24.
//

import Combine
import Foundation

protocol WebSocketControllerDelegate: AnyObject {
    
    func onWebSocketConnected()
    func onRequestToJoinApproved()
    func onMediaServerProducersReceived(mediaServerProducers: [[String: Any]])
    func onMediaServerError(errorMessage: String)

}

protocol WebSocketControllerProtocol {
    
    var delegate: WebSocketControllerDelegate? { get set }
    
    func connect(wsToken: String, cwToken: String)
    func disconnect()
    func joinMeetingRoom(originalRequestId: String, meetingRoomId: String) -> Future<WebSocketReceiveMessage, Never>
    func getRTPCapabilities(originalRequestId: String, meetingRoomId: String) -> Future<WebSocketReceiveMessage, Never>
    func createWebRTCTransport(originalRequestId: String, meetingRoomId: String) -> Future<WebSocketReceiveMessage, Never>
    func connectWebRTCTransport(originalRequestId: String, meetingRoomId: String, transportId: String, dtlsParameters: String) -> Future<WebSocketReceiveMessage, Never>
    func createWebRTCTransportProducer(originalRequestId: String, meetingRoomId: String, producerTransportId: String, kind: String, rtpParameters: [String: Any], mediaType: String) -> Future<WebSocketReceiveMessage, Never>
    func createWebRTCTransportConsumer(originalRequestId: String, meetingRoomId: String, consumerTransportId: String, producerId: String, rtpCapabilities: [String: Any], mediaType: String) -> Future<WebSocketReceiveMessage, Never>
    func resumeConsumer(originalRequestId: String, meetingRoomId: String, consumerId: String)

}

class WebSocketController: WebSocketControllerProtocol {
    weak var delegate: WebSocketControllerDelegate?
    
    private var webSocketRequestQueue: [String: Future<WebSocketReceiveMessage, Never>.Promise] = [:]
    
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
        self.loggerController.sendLog(name: "WebSocket:Disconnect", properties: nil)
        self.webSocketClient.disconnect()
    }
    
    func joinMeetingRoom(originalRequestId: String, meetingRoomId: String) -> Future<WebSocketReceiveMessage, Never> {
        return Future<WebSocketReceiveMessage, Never>() { promise in
            self.webSocketRequestQueue[originalRequestId] = promise
            
            let request: WebSocketAPIData = .sendEvent(.joinMeetingRoom, [
                "originalRequestId": originalRequestId,
                "meetingRoomId": meetingRoomId
            ])
            
            self.loggerController.sendLog(name: "WebSocket:Send:\(request.parameters.bodyParameters?["event"] ?? "unknown")", properties: request.parameters.bodyParameters)
            self.webSocketClient.send(request: request)
        }
    }
    
    func getRTPCapabilities(originalRequestId: String, meetingRoomId: String) -> Future<WebSocketReceiveMessage, Never> {
        return Future<WebSocketReceiveMessage, Never>() { promise in
            self.webSocketRequestQueue[originalRequestId] = promise
            
            let request: WebSocketAPIData = .sendEvent(.getRTPCabilities, [
                "originalRequestId": originalRequestId,
                "meetingRoomId": meetingRoomId
            ])
            
            self.loggerController.sendLog(name: "WebSocket:Send:\(request.parameters.bodyParameters?["event"] ?? "unknown")", properties: request.parameters.bodyParameters)
            self.webSocketClient.send(request: request)
        }
    }
    
    func createWebRTCTransport(originalRequestId: String, meetingRoomId: String) -> Future<WebSocketReceiveMessage, Never> {
        return Future<WebSocketReceiveMessage, Never>() { promise in
            self.webSocketRequestQueue[originalRequestId] = promise
            
            let request: WebSocketAPIData = .sendEvent(.createWebRTCTransport, [
                "originalRequestId": originalRequestId,
                "meetingRoomId": meetingRoomId
            ])
            
            self.loggerController.sendLog(name: "WebSocket:Send:\(request.parameters.bodyParameters?["event"] ?? "unknown")", properties: request.parameters.bodyParameters)
            self.webSocketClient.send(request: request)
        }
    }
    
    func createWebRTCTransportProducer(originalRequestId: String, meetingRoomId: String, producerTransportId: String, kind: String, rtpParameters: [String: Any], mediaType: String) -> Future<WebSocketReceiveMessage, Never> {
        return Future<WebSocketReceiveMessage, Never>() { promise in
            self.webSocketRequestQueue[originalRequestId] = promise
            
            let request: WebSocketAPIData = .sendEvent(.createWebRTCTransportProducer, [
                "originalRequestId": originalRequestId,
                "meetingRoomId": meetingRoomId,
                "producerTransportId": producerTransportId,
                "data": [
                    "kind": kind,
                    "rtpParameters": rtpParameters,
                    "mediaType": mediaType
                ]
            ])
            
            self.loggerController.sendLog(name: "WebSocket:Send:\(request.parameters.bodyParameters?["event"] ?? "unknown")", properties: request.parameters.bodyParameters)
            self.webSocketClient.send(request: request)
        }
    }
    
    func createWebRTCTransportConsumer(originalRequestId: String, meetingRoomId: String, consumerTransportId: String, producerId: String, rtpCapabilities: [String: Any], mediaType: String) -> Future<WebSocketReceiveMessage, Never> {
        return Future<WebSocketReceiveMessage, Never>() { promise in
            self.webSocketRequestQueue[originalRequestId] = promise
            
            let request: WebSocketAPIData = .sendEvent(.createWebRTCTransportConsumer, [
                "originalRequestId": originalRequestId,
                "meetingRoomId": meetingRoomId,
                "consumerTransportId": consumerTransportId,
                "producerId": producerId,
                "data": [
                    "producerId": producerId,
                    "rtpCapabilities": rtpCapabilities,
                    "mediaType": mediaType
                ]
            ])
            
            self.loggerController.sendLog(name: "WebSocket:Send:\(request.parameters.bodyParameters?["event"] ?? "unknown")", properties: request.parameters.bodyParameters)
            self.webSocketClient.send(request: request)
        }
    }
    
    func connectWebRTCTransport(originalRequestId: String, meetingRoomId: String, transportId: String, dtlsParameters: String) -> Future<WebSocketReceiveMessage, Never> {
        return Future<WebSocketReceiveMessage, Never>() { promise in
            self.webSocketRequestQueue[originalRequestId] = promise
            
            let request: WebSocketAPIData = .sendEvent(.connectWebRTCTransport, [
                "originalRequestId": originalRequestId,
                "meetingRoomId": meetingRoomId,
                "transportId": transportId,
                "dtlsParameters": dtlsParameters
            ])
            
            self.loggerController.sendLog(name: "WebSocket:Send:\(request.parameters.bodyParameters?["event"] ?? "unknown")", properties: request.parameters.bodyParameters)
            self.webSocketClient.send(request: request)
        }
    }
    
    func resumeConsumer(originalRequestId: String, meetingRoomId: String, consumerId: String) {
        let request: WebSocketAPIData = .sendEvent(.resumeConsumerStreamRequest, [
            "originalRequestId": originalRequestId,
            "meetingRoomId": meetingRoomId,
            "consumerId": consumerId
        ])
        
        self.loggerController.sendLog(name: "WebSocket:Send:\(request.parameters.bodyParameters?["event"] ?? "unknown")", properties: request.parameters.bodyParameters)
        self.webSocketClient.send(request: request)
    }
    
}

extension WebSocketController: WebSocketClientDelegate {
    func webSocketDidReceiveMessage(message: String) {
        self.loggerController.sendLog(name: "WebSocket:DidReceiveMessage", properties: [
            "message": message
        ])
        
        if let messageData = message.data(using: .utf8) {
            do {
                let webSocketReceiveMessage = try JSONDecoder().decode(WebSocketReceiveMessage.self, from: messageData)
                
                let jsonObject = messageData.toDictionary()
                
                self.readMessage(message: webSocketReceiveMessage, jsonObject: jsonObject)
            } catch(let error) {
                self.loggerController.sendLog(name: "WebSocket:DidReceiveMessage:DecodeMessageFailed", properties: [
                    "error": error.localizedDescription
                ])
            }
        }
    }
    
    func webSocketDidConnect() {
        self.loggerController.sendLog(name: "WebSocket:DidConnect", properties: nil)
    }
    
    func webSocketDidDisconnect() {
        self.loggerController.sendLog(name: "WebSocket:DidDisconnect", properties: nil)
    }
    
    func webSocketDidAttemptBetterPathMigration() {
        self.loggerController.sendLog(name: "WebSocket:DidAttemptBetterPathMigration", properties: nil)
    }
    
    func webSocketDidReceivePong() {
        self.loggerController.sendLog(name: "WebSocket:DidReceivePong", properties: nil)
    }
    
    func webSocketDidReceiveMessage(data: Data) {
        self.loggerController.sendLog(name: "WebSocket:DidReceiveMessage", properties: [
            "data": data
        ])
    }
    
    func webSocketDidReceiveError(errorMessage: String) {
        self.loggerController.sendLog(name: "WebSocket:DidReceiveError", properties: [
            "errorMessage": errorMessage
        ])
    }
    
    private func readMessage(message: WebSocketReceiveMessage, jsonObject: [String: Any]?) {
        var promise: Future<WebSocketReceiveMessage, Never>.Promise?
        var messageWithData: WebSocketReceiveMessage?
        
        if let originalRequestId = message.originalRequestId {
            promise = webSocketRequestQueue[originalRequestId]
            self.webSocketRequestQueue.removeValue(forKey: originalRequestId)
        }
        
        switch message.event {
        case .webSocketConnected:
            delegate?.onWebSocketConnected()
        case .requestToJoinApproved:
            delegate?.onRequestToJoinApproved()
        case .mediaServerProducers:
            let producers = jsonObject?["producers"] as? [[String: Any]]
            if let metaData = producers?.first?["meta"] as? [[String: Any]] {
                delegate?.onMediaServerProducersReceived(mediaServerProducers: metaData)
            }
        case .mediaServerError:
            let errorMessage = jsonObject?["errorMessage"] as? String
            delegate?.onMediaServerError(errorMessage: errorMessage ?? "unknown")
        case .webRTCTransport:
            let data = jsonObject?["data"] as? [String: Any]
            let webRTCResponse = data?["webrtcResponse"] as? [String: Any]
            
            let id = webRTCResponse?["id"] as? String
            let iceParameters = (webRTCResponse?["iceParameters"] as? [String: Any])?.toJSONString()
            let iceCandidates = (webRTCResponse?["iceCandidates"] as? [[String: Any]])?.toJSONString()
            let dtlsParameters = (webRTCResponse?["dtlsParameters"] as? [String: Any])?.toJSONString()
            messageWithData = WebSocketReceiveMessage(
                event: message.event,
                originalRequestId: message.originalRequestId,
                data: [
                    "originalRequestId": message.originalRequestId ?? "unknown",
                    "id": id ?? "unknown",
                    "iceParameters": iceParameters ?? "unknown",
                    "iceCandidates": iceCandidates ?? "unknown",
                    "dtlsParameters": dtlsParameters ?? "unknown"
                ]
            )
        default:
            messageWithData = WebSocketReceiveMessage(
                event: message.event,
                originalRequestId: message.originalRequestId,
                data: jsonObject?["data"] as? [String: Any]
            )
        }
        
        if let messageWithData {
            promise?(.success(messageWithData))
        }
    }
    
}
