//
//  DeviceSendTransportHandler.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 27/12/24.
//

import Foundation
import Mediasoup

class DeviceSendTransportHandler {
    
    private var isAudioConsumerCreated: Bool = false
    private var isVideoConsumerCreated: Bool = false
    private let loggerController: LoggerControllerProtocol
    private let webSocketController: WebSocketControllerProtocol

    init(loggerController: LoggerControllerProtocol,
         webSocketController: WebSocketControllerProtocol) {
        self.loggerController = loggerController
        self.webSocketController = webSocketController
    }
    
    private func createWebRTCTransportConsumer(meetingRoomId: String, consumerTransportId: String, rtpCapabilities: String, mediaServerProducer: MediaServerProducer) {
        let originalRequestId = UUID().uuidString

        self.webSocketController.createWebRTCTransportConsumer(
            originalRequestId: originalRequestId,
            meetingRoomId: meetingRoomId,
            consumerTransportId: consumerTransportId,
            producerId: mediaServerProducer.id,
            rtpCapabilities: rtpCapabilities,
            mediaType: mediaServerProducer.mediaType
        )
    }
    
}

extension DeviceSendTransportHandler: SendTransportDelegate {
    
    func onProduce(transport: any Transport, kind: MediaKind, rtpParameters: String, appData: String, callback: @escaping (String?) -> Void) {
        self.loggerController.sendLog(name: "DeviceSendTransport:OnProduce:\(rtpParameters)", properties: nil)
        
        guard let rtpParameters: [String: Any] = rtpParameters.data(using: .utf8)?.toDictionary() else {
            self.loggerController.sendLog(name: "DeviceSendTransport:OnProduce failed", properties: [
                "error": "Invalid rtpParameters"
            ])
            return
        }
        
        guard let encodings: [[String: Any]] = rtpParameters["encodings"] as? [[String: Any]] else {
            self.loggerController.sendLog(name: "DeviceSendTransport:OnProduce failed", properties: [
                "error": "Invalid encodings"
            ])
            return
        }
        
        let newEncodingParams: [String: Any] = [
            "maxBitrate": 3000000,
            "maxFramerate": 24,
            "priority": "high",
            "networkPriority": "high"
        ]
        
        let newEncodings: [[String: Any]] = encodings.map {
            $0.merging(newEncodingParams) { _, new in new }
        }
        
        let newRtpParameters: [String: Any] = rtpParameters.merging(
            [
                "encodings": newEncodings
            ]
        ) { _, new in new }
        
        let appData = appData.toDictionary()
        let originalRequestId = UUID().uuidString
        let meetingRoomId = (appData?["meetingRoomId"] as? String) ?? "unknown"
        let producerTransportId = (appData?["producerTransportId"] as? String) ?? "unknown"
        let mediaType = (appData?["mediaType"] as? String) ?? "unknown"
        self.webSocketController.createWebRTCTransportProducer(
            originalRequestId: originalRequestId,
            meetingRoomId: meetingRoomId,
            producerTransportId: producerTransportId,
            kind: mediaType,
            rtpParameters: newRtpParameters,
            mediaType: mediaType
        )
        
//        const producerId = res.data.producer.id;
//        if (appData.mediaType === 'screen') setProducerIdScreen(producerId);
//        if (appData.mediaType === 'video') setProducerIdVideo(producerId);
//        if (appData.mediaType === 'audio') setProducerIdAudio(producerId);
        
        guard let mediaServerProducersDictionary = appData?["mediaServerProducers"] as? [[String: Any]],
              let mediaServerProducersData = mediaServerProducersDictionary.toData(),
              let mediaServerProducers = try? JSONDecoder().decode([MediaServerProducer].self, from: mediaServerProducersData) else {
            self.loggerController.sendLog(name: "DeviceSendTransport:OnProduce failed", properties: [
                "appData": appData ?? "unknown",
                "error": "Invalid mediaServerProducers"
            ])
            return
        }
        
        let consumerTransportId = (appData?["consumerTransportId"] as? String) ?? "unknown"
        let rtpCapabilities = (appData?["rtpCapabilities"] as? String) ?? "unknown"
        
        mediaServerProducers.forEach { mediaServerProducer in
            if !isAudioConsumerCreated && kind == .audio && mediaServerProducer.kind == "audio" {
                isAudioConsumerCreated = true
                
                self.createWebRTCTransportConsumer(meetingRoomId: meetingRoomId, consumerTransportId: consumerTransportId, rtpCapabilities: rtpCapabilities, mediaServerProducer: mediaServerProducer)
            }
            
            if !isVideoConsumerCreated && kind == .video && mediaServerProducer.kind == "video" {
                isVideoConsumerCreated = true
                
                
                self.createWebRTCTransportConsumer(meetingRoomId: meetingRoomId, consumerTransportId: consumerTransportId, rtpCapabilities: rtpCapabilities, mediaServerProducer: mediaServerProducer)
            }
        }

        callback(originalRequestId)
        
//        DEBUG:WebSocket:DidReceiveMessage with properties: {
//            message = "{\"event\":\"WEBRTC_TRANSPORT_PRODUCER_CREATED\",\"meetingRoomId\":\"0ee8aa1b-22bd-4bf3-8786-17bb311bab7a\",\"conversationId\":\"ea6cfb83-a84d-4d0c-a046-cf905745471a\",\"data\":{\"me\":{\"name\":\"Jimmy - 31/11:11\U202fAM\",\"id\":\"ec706c56-984a-41d4-8782-b456b86d6cdd\"},\"producer\":{\"id\":\"f9645b1f-7f20-4db2-b370-b4f1da97c5dc\",\"kind\":\"audio\",\"mediaType\":\"audio\"}}}";
//        }
        
        //        //BE balikin originalRequestID
        //        //Save producerId dari res.data.producer.id
        //        //Panggil callback(id)
    }
    
    func onProduceData(transport: any Transport, sctpParameters: String, label: String, protocol dataProtocol: String, appData: String, callback: @escaping (String?) -> Void) {
        
        self.loggerController.sendLog(name: "DeviceSendTransport:OnProduceData:\(label)", properties: nil)
    }
    
    func onConnect(transport: any Transport, dtlsParameters: String) {
        
        self.loggerController.sendLog(name: "DeviceSendTransport:OnConnect:\(dtlsParameters)", properties: nil)
    }
    
    func onConnectionStateChange(transport: any Transport, connectionState: TransportConnectionState) {
        
        self.loggerController.sendLog(name: "DeviceSendTransport:OnConnectionStateChange:\(connectionState)", properties: nil)
    }
    
}

extension DeviceSendTransportHandler: ProducerDelegate {
    
    func onTransportClose(in producer: Producer) {
        self.loggerController.sendLog(name: "DeviceProducer:OnTransportClose:\(producer.id)", properties: nil)
    }
    
}
