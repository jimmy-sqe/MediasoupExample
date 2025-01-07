//
//  Untitled.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 07/01/25.
//

import Combine
import Foundation
import Mediasoup

class DeviceSendTransportHandler {
    
    var meetingRoomId: String?
    
    private var isAudioConsumerCreated: Bool = false
    private var isVideoConsumerCreated: Bool = false

    private var rtpCapabilities: [String: Any]?
    private var mediaServerProducers: [[String: Any]]?
    private var producerId: String?
    private var audioProducerId: String?
    
    private var sendTransport: SendTransport?
    
    private var receiveTransport: ReceiveTransport?
    private var consumer: Consumer?
    private var consumerTransportId: String?

    private var cancellables = Set<AnyCancellable>()
    private let loggerController: LoggerControllerProtocol
    private let webSocketController: WebSocketControllerProtocol

    init(loggerController: LoggerControllerProtocol,
         webSocketController: WebSocketControllerProtocol) {
        self.loggerController = loggerController
        self.webSocketController = webSocketController
    }
    
    func setSendTransport(_ sendTransport: SendTransport) {
        self.sendTransport = sendTransport
        self.sendTransport?.delegate = self
    }
    
    func setReceiveTransport(_ receiveTransport: ReceiveTransport) {
        self.receiveTransport = receiveTransport
    }
    
    func setRTPCapabilities(_ rtpCapabilities: [String: Any]) {
        self.rtpCapabilities = rtpCapabilities
    }
    
    func setMediaServerProducers(_ mediaServerProducers: [[String: Any]]) {
        self.mediaServerProducers = mediaServerProducers
    }
    
    func setConsumerTransportId(_ consumerTransportId: String) {
        self.consumerTransportId = consumerTransportId
    }
    
}



extension DeviceSendTransportHandler: SendTransportDelegate {
    
    func onConnect(transport: any Transport, dtlsParameters: String) {
        self.loggerController.sendLog(name: "DeviceSendTransport:OnConnect", properties: [
            "transportId": transport.id
        ])
        
        Task.synchronous {
            await withCheckedContinuation { continuation in
                self.webSocketController.connectWebRTCTransport(
                    originalRequestId: UUID().uuidString,
                    meetingRoomId: self.meetingRoomId ?? "unknown",
                    transportId: transport.id,
                    dtlsParameters: dtlsParameters.toDictionary() ?? ["unknown": "unknown"]
                ).sink { _ in
                    self.loggerController.sendLog(name: "DeviceSendTransport:connectWebRTCTransport succeed", properties: nil)
                    continuation.resume()
                }.store(in: &self.cancellables)
            }
        }
    }
    
    func onProduce(transport: any Transport, kind: MediaKind, rtpParameters: String, appData: String, callback: @escaping (String?) -> Void) {
        self.loggerController.sendLog(name: "DeviceSendTransport:OnProduce", properties: [
            "transportId": transport.id
        ])
        
        guard let rtpParameters: [String: Any] = rtpParameters.toDictionary() else {
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
        
        self.webSocketController.createWebRTCTransportProducer(
            originalRequestId: UUID().uuidString,
            meetingRoomId: meetingRoomId ?? "unknown",
            producerTransportId: transport.id,
            kind: kind.rawValue,
            rtpParameters: newRtpParameters,
            mediaType: kind.rawValue
        ).sink { [weak self] message in
            guard let self else { return }
            
            let originalRequestIdFromServer: String = message.originalRequestId ?? "unknown"
            
            self.loggerController.sendLog(name: "DeviceSendTransport:createWebRTCTransportProducer succeed", properties: [
                "originalRequestIdFromServer": originalRequestIdFromServer,
            ])
            
            let producer: [String: Any]? = message.data?["producer"] as? [String: Any]
            self.producerId = producer?["id"] as? String
            if (kind == .audio) {
                self.audioProducerId = self.producerId
            }
            // TODO: do for video

            guard let mediaServerProducers = self.mediaServerProducers else {
                self.loggerController.sendLog(name: "DeviceSendTransport:OnProduce failed", properties: [
                    "appData": appData,
                    "error": "Invalid mediaServerProducers"
                ])
                return
            }
            
            mediaServerProducers.forEach { mediaServerProducer in
                if !self.isAudioConsumerCreated && kind == .audio && mediaServerProducer["kind"] as? String == "audio" {
                    self.isAudioConsumerCreated = true
                    
                    self.webSocketController.createWebRTCTransportConsumer(
                        originalRequestId: UUID().uuidString,
                        meetingRoomId: self.meetingRoomId ?? "unknown",
                        consumerTransportId: self.consumerTransportId ?? "unknown",
                        producerId: mediaServerProducer["id"] as? String ?? "unknown",
                        rtpCapabilities: self.rtpCapabilities ?? ["unknown": ""],
                        mediaType: mediaServerProducer["mediaType"] as? String ?? "unknown"
                    ).sink { message in
                        if let consumer = message.data?["consumer"] as? [String: Any],
                           let consumerId = consumer["id"] as? String {
                            self.consumeConsumer(consumer: consumer)
                            self.resumeConsumer(consumerId: consumerId)
                        } else {
                            self.loggerController.sendLog(name: "DeviceSendTransport:OnProduce failed", properties: [
                                "error": "Invalid consumer"
                            ])
                        }
                        
                        self.loggerController.sendLog(name: "DeviceSendTransport:OnProduce succeed", properties: nil)
                        
                        //TODO: it should be after VIDEO
                        
                        self.loggerController.sendLog(name: "DeviceSendTransport:callback", properties: nil)
                        callback(originalRequestIdFromServer)
                    }.store(in: &self.cancellables)
                }
                
                //TODO: do for video
            }
        }.store(in: &cancellables)
    }
    
    func onProduceData(transport: any Transport, sctpParameters: String, label: String, protocol dataProtocol: String, appData: String, callback: @escaping (String?) -> Void) {
        self.loggerController.sendLog(name: "DeviceSendTransport:OnProduceData:\(label)", properties: [
            "transportId": transport.id
        ])
    }
    
    func onConnectionStateChange(transport: any Transport, connectionState: TransportConnectionState) {
        self.loggerController.sendLog(name: "DeviceSendTransport:OnConnectionStateChange:\(connectionState)", properties: [
            "transportId": transport.id
        ])
        
        switch connectionState {
        case .disconnected, .failed:
            restartIce(transportId: transport.id);
        default:
            //TODO: Implement timeout please refer to FE implementation
            break
        }
    }
    
    private func consumeConsumer(consumer: [String: Any]) {
        self.loggerController.sendLog(name: "DeviceSendTransport:ConsumeConsumer", properties: nil)
        do {
            guard let consumerId = consumer["id"] as? String,
                  let producerId = consumer["producerId"] as? String,
                  let kind = consumer["kind"] as? String,
                  let rtpParameters = consumer["rtpParameters"] as? [String: Any] else {
                self.loggerController.sendLog(name: "DeviceSendTransport:ConsumeConsumer failed", properties: [
                    "error": "Invalid consumer"
                ])
                return
            }
            
            let consumer = try self.receiveTransport?.consume(
                consumerId: consumerId,
                producerId: producerId,
                kind: MediaKind(rawValue: kind),
                rtpParameters: rtpParameters.toJSONString() ?? "unknown",
                appData: nil
            )
            self.consumer = consumer
            
            self.loggerController.sendLog(name: "DeviceSendTransport:ConsumeConsumer succeed", properties: nil)
            
            if consumer?.kind == .audio {
//                const remAudio = new MediaStream();
//                let remoteStreamAudio: any = document.getElementById('remote-audio');
//                remAudio.addTrack(track);
//                useVideoCallStore.getState().setRemoteAudioStream(remAudio);
//                remoteStreamAudio.srcObject = remAudio;
            } else {
                //TODO: for video
            }
        } catch {
            self.loggerController.sendLog(name: "DeviceSendTransport:ConsumeConsumer failed", properties: [
                "error": error.localizedDescription
            ])
        }
    }
    
    private func resumeConsumer(consumerId: String) {
        self.loggerController.sendLog(name: "DeviceSendTransport:ResumeConsumer", properties: nil)

        Task.synchronous {
            await withCheckedContinuation { continuation in
                self.webSocketController.resumeConsumer(
                    originalRequestId: UUID().uuidString,
                    meetingRoomId: self.meetingRoomId ?? "unknown",
                    consumerId: consumerId
                ).sink { _ in
                    self.loggerController.sendLog(name: "DeviceSendTransport:ResumeConsumer succeed", properties: nil)
                    continuation.resume()
                }.store(in: &self.cancellables)
            }
        }
    }
    
    private func restartIce(transportId: String) {
        self.loggerController.sendLog(name: "DeviceSendTransport:RestartIce", properties: [
            "transportId": transportId
        ])
        
        //TODO: Implement timeout please refer to FE implementation
        self.webSocketController.restartIce(
            originalRequestId: UUID().uuidString,
            meetingRoomId: self.meetingRoomId ?? "unknown",
            transportId: transportId
        ).sink { [weak self] message in
            guard let self,
                  let iceParameters = message.data?["iceParameters"] as? String else {
                self?.loggerController.sendLog(name: "DeviceSendTransport:RestartIce failed", properties: [
                    "transportId": transportId,
                    "error": "Invalid iceParameters"
                ])
                return
            }
            
            do {
                try self.sendTransport?.restartICE(with: iceParameters)
                self.loggerController.sendLog(name: "DeviceSendTransport:RestartIce succeed", properties: [
                    "transportId": transportId
                ])
            } catch {
                self.loggerController.sendLog(name: "DeviceSendTransport:RestartIce failed", properties: [
                    "transportId": transportId,
                    "error": error.localizedDescription
                ])
            }
        }.store(in: &cancellables)
    }
    
}

extension DeviceSendTransportHandler: ProducerDelegate {
    
    func onTransportClose(in producer: Producer) {
        self.loggerController.sendLog(name: "DeviceProducer:OnTransportClose:\(producer.id)", properties: nil)
    }
    
}
