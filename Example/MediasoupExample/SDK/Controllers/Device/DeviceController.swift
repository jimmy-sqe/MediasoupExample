//
//  DeviceController.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 27/12/24.
//

import AVFoundation
import Combine
import Mediasoup
import WebRTC

protocol DeviceControllerDelegate: AnyObject {
    
    func onDeviceLoaded()
    
}

protocol DeviceControllerProtocol {
    
    var delegate: DeviceControllerDelegate? { get set }
    var meetingRoomId: String? { get set }
    
    func checkAudioPermission()
    func setup()
    func loadDevice(rtpCapabilities: [String: Any])
    func createSendTransport(param: DeviceTransportParam)
    func createReceiveTransport(param: DeviceTransportParam)
    func createProducer(mediaServerProducers: [[String: Any]])

}

class DeviceController: DeviceControllerProtocol {
    
    weak var delegate: DeviceControllerDelegate?
    var meetingRoomId: String? {
        didSet {
            self.deviceReceiveTransportHandler.meetingRoomId = meetingRoomId
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var isAudioConsumerCreated: Bool = false
    private var isVideoConsumerCreated: Bool = false

    private let peerConnectionFactory = RTCPeerConnectionFactory()
    private var peerConnection: RTCPeerConnection?
    private var mediaStream: RTCMediaStream?
    private var audioTrack: RTCAudioTrack?
    private var videoTrack: RTCVideoTrack?

    private var device: Device?
    
    private var mediaServerProducers: [[String: Any]]?
    private var rtpCapabilities: [String: Any]?
    
    private var sendTransport: SendTransport?
    private var sendTransportParam: DeviceTransportParam?
    private var producerId: String?
    private var audioProducerId: String?
    private var producer: Producer?
    
    private var receiveTransport: ReceiveTransport?
    private var receiveTransportParam: DeviceTransportParam?
    private var consumer: Consumer?
    // Create separate handler for receive transport because it has same method names with SendTransportDelegate
    private let deviceReceiveTransportHandler: DeviceReceiveTransportHandler

    private let loggerController: LoggerControllerProtocol
    private let webSocketController: WebSocketControllerProtocol

    init(loggerController: LoggerControllerProtocol,
         webSocketController: WebSocketControllerProtocol) {
        self.loggerController = loggerController
        self.webSocketController = webSocketController

        self.deviceReceiveTransportHandler = DeviceReceiveTransportHandler(loggerController: loggerController, webSocketController: webSocketController)
    }
    
    deinit {
        self.sendTransport?.close()
        self.receiveTransport?.close()
    }
    
    func checkAudioPermission() {
        if AVCaptureDevice.authorizationStatus(for: .audio) != .authorized {
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
        }
    }
    
    func setup() {
        let audioTrack = peerConnectionFactory.audioTrack(withTrackId: "sqe_audio")
        self.audioTrack = audioTrack
        
        let mediaStream = peerConnectionFactory.mediaStream(withStreamId: "sqe_stream")
        self.mediaStream = mediaStream
        mediaStream.addAudioTrack(audioTrack)
        
        // Additional from ChatGPT
//        let config = RTCConfiguration()
//        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
//        let peerConnection = peerConnectionFactory.peerConnection(with: config, constraints: constraints, delegate: nil)
//        self.peerConnection = peerConnection
//        peerConnection?.add(mediaStream)
    }
    
    func loadDevice(rtpCapabilities: [String: Any]) {
        self.loggerController.sendLog(name: "Device:LoadDevice", properties: nil)
        
        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
            self.loggerController.sendLog(name: "Device:LoadDevice failed", properties: [
                "error": "DeviceAuthorizationStatus: \(AVCaptureDevice.authorizationStatus(for: .audio))"
            ])
            return
        }
        
        do {
            let device = Device()
            self.device = device
            self.rtpCapabilities = rtpCapabilities
            try device.load(with: rtpCapabilities.toJSONString() ?? "unknown")
            
            let isDeviceLoaded = device.isLoaded()
            if isDeviceLoaded {
                self.loggerController.sendLog(name: "Device:LoadDevice succeed", properties: nil)
            } else {
                self.loggerController.sendLog(name: "Device:LoadDevice failed", properties: ["error": "Device is not loaded"])
            }

            let canProduceVideo = try device.canProduce(.video)
            self.loggerController.sendLog(name: "Device:canProduceVideo:\(canProduceVideo)", properties: nil)
            
            let canProduceAudio = try device.canProduce(.audio)
            self.loggerController.sendLog(name: "Device:canProduceAudio:\(canProduceAudio)", properties: nil)
            
            if canProduceVideo && canProduceAudio {
                self.delegate?.onDeviceLoaded()
            }
        } catch {
            self.handleError(subject: "Device:LoadDevice", error: error)
        }
    }
    
    func createSendTransport(param: DeviceTransportParam) {
        guard let device else { return }
        
        self.sendTransportParam = param
        
        do {
            self.loggerController.sendLog(name: "Device:CreateSendTransport", properties: [
                "id": param.id,
                "iceParameters": param.iceParameters,
                "iceCandidates": param.iceCandidates,
                "dtlsParameters": param.dtlsParameters
            ])
            
            let sendTransport = try device.createSendTransport(
                id: param.id,
                iceParameters: param.iceParameters,
                iceCandidates: param.iceCandidates,
                dtlsParameters: param.dtlsParameters,
                sctpParameters: nil,
                appData: nil)
            sendTransport.delegate = self
            self.sendTransport = sendTransport
        } catch {
            self.handleError(subject: "Device:CreateSendTransport", error: error)
        }
    }
    
    func createReceiveTransport(param: DeviceTransportParam) {
        guard let device else { return }
        
        self.receiveTransportParam = param
        
        do {
            self.loggerController.sendLog(name: "Device:CreateReceiveTransport", properties: [
                "id": param.id,
                "iceParameters": param.iceParameters,
                "iceCandidates": param.iceCandidates,
                "dtlsParameters": param.dtlsParameters
            ])
            
            let receiveTransport = try device.createReceiveTransport(
                id: param.id,
                iceParameters: param.iceParameters,
                iceCandidates: param.iceCandidates,
                dtlsParameters: param.dtlsParameters,
                sctpParameters: nil,
                appData: nil)
            receiveTransport.delegate = self.deviceReceiveTransportHandler
            self.receiveTransport = receiveTransport
        } catch {
            self.handleError(subject: "Device:CreateReceiveTransport", error: error)
        }
    }
    
    func createProducer(mediaServerProducers: [[String: Any]]) {
        guard let sendTransport, let audioTrack else { return }
        
        self.mediaServerProducers = mediaServerProducers
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            do {
                self.loggerController.sendLog(name: "Device:CreateProducer", properties: nil)
                let producer = try sendTransport.createProducer(for: audioTrack, encodings: nil, codecOptions: nil, codec: nil, appData: nil)
                self.producer = producer
                
                producer.delegate = self
                producer.resume()
                self.loggerController.sendLog(name: "Device:CreateProducer succeed", properties: nil)
            } catch {
                self.handleError(subject: "Device:CreateProducer", error: error)
            }
        }
    }
    
    private func handleError(subject: String, error: Error) {
        let errorMessage: String
        
        if let error = error as? MediasoupError {
            switch error {
            case let .unsupported(message):
                errorMessage = "unsupported: \(message)"
            case let .invalidState(message):
                errorMessage = "invalid state: \(message)"
            case let .invalidParameters(message):
                errorMessage = "invalid parameters: \(message)"
            case let .mediasoup(underlyingError):
                errorMessage = "mediasoup: \(underlyingError)"
            case .unknown(let underlyingError):
                errorMessage = "unknown: \(underlyingError)"
            @unknown default:
                errorMessage = "unknown"
            }
        } else {
            errorMessage = error.localizedDescription
        }
        
        self.loggerController.sendLog(name: "\(subject) failed", properties: [
            "error": errorMessage
        ])
    }
    
}

extension DeviceController: SendTransportDelegate {
    
    func onConnect(transport: any Transport, dtlsParameters: String) {
        self.loggerController.sendLog(name: "DeviceSendTransport:OnConnect", properties: nil)
        
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
        self.loggerController.sendLog(name: "DeviceSendTransport:OnProduce", properties: nil)
        
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
        
        let mediaType: String = {
            switch kind {
            case .audio:
                "audio"
            case .video:
                "video"
            default:
                "unknown"
            }
        }();
        
        self.webSocketController.createWebRTCTransportProducer(
            originalRequestId: UUID().uuidString,
            meetingRoomId: meetingRoomId ?? "unknown",
            producerTransportId: transport.id,
            kind: mediaType,
            rtpParameters: newRtpParameters,
            mediaType: mediaType
        ).sink { [weak self] message in
            guard let self else { return }
            
            let originalRequestIdFromServer: String = message.originalRequestId ?? "unknown"
            
            self.loggerController.sendLog(name: "DeviceSendTransport:createWebRTCTransportProducer succeed", properties: [
                "originalRequestIdFromServer": originalRequestIdFromServer,
            ])
            
            let producer: [String: Any]? = message.data?["producer"] as? [String: Any]
            self.producerId = producer?["id"] as? String
            if (mediaType == "audio") {
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
                        consumerTransportId: self.receiveTransportParam?.id ?? "unknown",
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
        self.loggerController.sendLog(name: "DeviceSendTransport:OnProduceData:\(label)", properties: nil)
    }
    
    func onConnectionStateChange(transport: any Transport, connectionState: TransportConnectionState) {
        self.loggerController.sendLog(name: "DeviceSendTransport:OnConnectionStateChange:\(connectionState)", properties: nil)
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
                kind: kind == "audio" ? MediaKind.audio : MediaKind.video,
                rtpParameters: rtpParameters.toJSONString() ?? "unknown",
                appData: nil
            )
            
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
}

extension DeviceController: ProducerDelegate {
    
    func onTransportClose(in producer: Producer) {
        self.loggerController.sendLog(name: "DeviceProducer:OnTransportClose:\(producer.id)", properties: nil)
    }
    
}
