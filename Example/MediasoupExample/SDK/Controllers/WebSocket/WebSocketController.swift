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
    func onMediaServerProducersReceived(mediaServerProducers: [[String: Any]])

}

protocol WebSocketControllerProtocol {
    
    var delegate: WebSocketControllerDelegate? { get set }
    
    func connect(wsToken: String, cwToken: String)
    func disconnect()
    func joinMeetingRoom(originalRequestId: String, meetingRoomId: String) -> Future<WebSocketReceiveMessage>
    func getRTPCapabilities(originalRequestId: String, meetingRoomId: String) -> Future<WebSocketReceiveMessage>
    func createWebRTCTransport(originalRequestId: String, meetingRoomId: String) -> Future<WebSocketReceiveMessage>
    func connectWebRTCTransport(originalRequestId: String, meetingRoomId: String, transportId: String, dtlsParameters: String) -> Future<WebSocketReceiveMessage>
    func createWebRTCTransportProducer(originalRequestId: String, meetingRoomId: String, producerTransportId: String, kind: String, rtpParameters: [String: Any], mediaType: String) -> Future<WebSocketReceiveMessage>
    func createWebRTCTransportConsumer(originalRequestId: String, meetingRoomId: String, consumerTransportId: String, producerId: String, rtpCapabilities: String, mediaType: String) -> Future<WebSocketReceiveMessage>
    func resumeConsumer(originalRequestId: String, meetingRoomId: String, consumerId: String)

}

class WebSocketController: WebSocketControllerProtocol {
    weak var delegate: WebSocketControllerDelegate?
    
    private var webSocketRequestQueue: [String: Promise<WebSocketReceiveMessage>] = [:]
    
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
    
    func joinMeetingRoom(originalRequestId: String, meetingRoomId: String) -> Future<WebSocketReceiveMessage> {
        let promise = Promise<WebSocketReceiveMessage>()
        self.webSocketRequestQueue[originalRequestId] = promise

        let request: WebSocketAPIData = .sendEvent(.joinMeetingRoom, [
            "originalRequestId": originalRequestId,
            "meetingRoomId": meetingRoomId
        ])
        
        self.loggerController.sendLog(name: "WebSocket:Send:\(request.parameters.bodyParameters?["event"] ?? "unknown")", properties: request.parameters.bodyParameters)
        self.webSocketClient.send(request: request)
        
        return promise
    }
    
    func getRTPCapabilities(originalRequestId: String, meetingRoomId: String) -> Future<WebSocketReceiveMessage> {
        let promise = Promise<WebSocketReceiveMessage>()
        self.webSocketRequestQueue[originalRequestId] = promise

        let request: WebSocketAPIData = .sendEvent(.getRTPCabilities, [
            "originalRequestId": originalRequestId,
            "meetingRoomId": meetingRoomId
        ])
        
        self.loggerController.sendLog(name: "WebSocket:Send:\(request.parameters.bodyParameters?["event"] ?? "unknown")", properties: request.parameters.bodyParameters)
        self.webSocketClient.send(request: request)
        
        return promise
    }
    
    func createWebRTCTransport(originalRequestId: String, meetingRoomId: String) -> Future<WebSocketReceiveMessage> {
        let promise = Promise<WebSocketReceiveMessage>()
        self.webSocketRequestQueue[originalRequestId] = promise

        let request: WebSocketAPIData = .sendEvent(.createWebRTCTransport, [
            "originalRequestId": originalRequestId,
            "meetingRoomId": meetingRoomId
        ])
        
        self.loggerController.sendLog(name: "WebSocket:Send:\(request.parameters.bodyParameters?["event"] ?? "unknown")", properties: request.parameters.bodyParameters)
        self.webSocketClient.send(request: request)
        
        return promise
    }
    
    func createWebRTCTransportProducer(originalRequestId: String, meetingRoomId: String, producerTransportId: String, kind: String, rtpParameters: [String: Any], mediaType: String) -> Future<WebSocketReceiveMessage> {
        let promise = Promise<WebSocketReceiveMessage>()
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
        
        return promise
    }
    
    func createWebRTCTransportConsumer(originalRequestId: String, meetingRoomId: String, consumerTransportId: String, producerId: String, rtpCapabilities: String, mediaType: String) -> Future<WebSocketReceiveMessage> {
        let promise = Promise<WebSocketReceiveMessage>()
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
        
        self.loggerController.sendLog(name: "WebSocket:Send:\(request.parameters.bodyParameters?["event"] ?? "unknown")", properties: nil)
        self.webSocketClient.send(request: request)
        
        return promise
    }
    
    func connectWebRTCTransport(originalRequestId: String, meetingRoomId: String, transportId: String, dtlsParameters: String) -> Future<WebSocketReceiveMessage> {
        let promise = Promise<WebSocketReceiveMessage>()
        self.webSocketRequestQueue[originalRequestId] = promise

        let request: WebSocketAPIData = .sendEvent(.connectWebRTCTransport, [
            "originalRequestId": originalRequestId,
            "meetingRoomId": meetingRoomId,
            "transportId": transportId,
            "dtlsParameters": dtlsParameters
        ])
        
        self.loggerController.sendLog(name: "WebSocket:Send:\(request.parameters.bodyParameters?["event"] ?? "unknown")", properties: request.parameters.bodyParameters)
        self.webSocketClient.send(request: request)
        
        return promise
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
        var promise: Promise<WebSocketReceiveMessage>?
        
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
        case .webRTCTransport:
            let data = jsonObject?["data"] as? [String: Any]
            let webRTCResponse = data?["webrtcResponse"] as? [String: Any]
            
            let id = webRTCResponse?["id"] as? String
            let iceParameters = (webRTCResponse?["iceParameters"] as? [String: Any])?.toJSONString()
            let iceCandidates = (webRTCResponse?["iceCandidates"] as? [[String: Any]])?.toJSONString()
            let dtlsParameters = (webRTCResponse?["dtlsParameters"] as? [String: Any])?.toJSONString()
            let messageWithData = WebSocketReceiveMessage(
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
            promise?.resolve(with: messageWithData)
        default:
            let messageWithData = WebSocketReceiveMessage(
                event: message.event,
                originalRequestId: message.originalRequestId,
                data: jsonObject?["data"] as? [String: Any]
            )
            promise?.resolve(with: messageWithData)
        }
    }
    
}
