//
//  DeviceController.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 27/12/24.
//

import AVFoundation
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
    func loadDevice(rtpCapabilities: String)
    func createSendTransport(param: DeviceTransportParam)
    func createReceiveTransport(param: DeviceTransportParam)
    func createProducer(mediaServerProducers: [MediaServerProducer]?)

}

class DeviceController: DeviceControllerProtocol {
    
    weak var delegate: DeviceControllerDelegate?
    var meetingRoomId: String? {
        didSet {
            self.deviceReceiveTransportHandler.meetingRoomId = meetingRoomId
        }
    }
    
    private var isAudioConsumerCreated: Bool = false
    private var isVideoConsumerCreated: Bool = false

    private let peerConnectionFactory = RTCPeerConnectionFactory()
    private var mediaStream: RTCMediaStream?
    private var audioTrack: RTCAudioTrack?
    private var videoTrack: RTCVideoTrack?

    private var device: Device?
    
    private var rtpCapabilities: String?
    
    private var sendTransport: SendTransport?
    private var producerTransportId: String?
    private var producer: Producer?
    
    private var receiveTransport: ReceiveTransport?
    private var consumerTransportId: String?
    private var consumer: Consumer?
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
    }
    
    func loadDevice(rtpCapabilities: String) {
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
            try device.load(with: rtpCapabilities)
            
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
        
        self.loggerController.sendLog(name: "Device:CreateSendTransport", properties: [
            "id": param.id,
            "iceParameters": param.iceParameters,
            "iceCandidates": param.iceCandidates,
            "dtlsParameters": param.dtlsParameters
        ])
        
        self.producerTransportId = param.id

        do {
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
        
        self.loggerController.sendLog(name: "Device:CreateReceiveTransport", properties: [
            "id": param.id,
            "iceParameters": param.iceParameters,
            "iceCandidates": param.iceCandidates,
            "dtlsParameters": param.dtlsParameters
        ])
        
        self.consumerTransportId = param.id

        do {
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
    
    func createProducer(mediaServerProducers: [MediaServerProducer]?) {
        guard let sendTransport, let audioTrack else { return }
        
        self.loggerController.sendLog(name: "Device:CreateProducer", properties: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            do {
                let appData: [String: Any] = [
                    "consumerTransportId": self.consumerTransportId ?? "unknown",
                    "rtpCapabilities": self.rtpCapabilities ?? "unknown",
                    "mediaType": "audio",
                    "mediaServerProducers": mediaServerProducers ?? "unknown"
                ]
                let producer = try sendTransport.createProducer(for: audioTrack, encodings: nil, codecOptions: nil, codec: nil, appData: appData.toJSONString())
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
        self.loggerController.sendLog(name: "DeviceSendTransport:OnConnect:\(dtlsParameters)", properties: nil)
        
        let originalRequestId = UUID().uuidString
        self.webSocketController.connectWebRTCTransport(
            originalRequestId: originalRequestId,
            meetingRoomId: meetingRoomId ?? "unknown",
            transportId: transport.id,
            dtlsParameters: dtlsParameters
        )
    }
    
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
        let mediaType = (appData?["mediaType"] as? String) ?? "unknown"
        self.webSocketController.createWebRTCTransportProducer(
            originalRequestId: originalRequestId,
            meetingRoomId: meetingRoomId ?? "unknown",
            producerTransportId: transport.id,
            kind: mediaType,
            rtpParameters: newRtpParameters,
            mediaType: mediaType
        )
        
        //TODO: Store originalRequestId from result of createWebRTCTransportProducer for callback value
//        let originalRequestId =

        //TODO: Store producer id from result of createWebRTCTransportProducer for resuming and closing producer
//        {\"event\":\"WEBRTC_TRANSPORT_PRODUCER_CREATED\",\"meetingRoomId\":\"0ee8aa1b-22bd-4bf3-8786-17bb311bab7a\",\"conversationId\":\"ea6cfb83-a84d-4d0c-a046-cf905745471a\",\"data\":{\"me\":{\"name\":\"Jimmy - 31/11:11\U202fAM\",\"id\":\"ec706c56-984a-41d4-8782-b456b86d6cdd\"},\"producer\":{\"id\":\"f9645b1f-7f20-4db2-b370-b4f1da97c5dc\",\"kind\":\"audio\",\"mediaType\":\"audio\"}}}";
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
                
                self.createWebRTCTransportConsumer(consumerTransportId: consumerTransportId, rtpCapabilities: rtpCapabilities, mediaServerProducer: mediaServerProducer)
                
                //TODO: pass result from createWebRTCTransportConsumer
                self.consumeConsumer(consumer: [:])
            }
            
            //TODO: do for video
        }

        callback(originalRequestId)
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
                  let rtpParameters = consumer["rtpParameters"] as? String,
                  let codecOptions = consumer["codecOptions"] as? String else {
                self.loggerController.sendLog(name: "DeviceSendTransport:ConsumeConsumer failed", properties: [
                    "error": "Invalid consumer"
                ])
                
                return
            }
            
            let appData = [
                "codecOptions": codecOptions
            ]
            
            let consumer = try self.receiveTransport?.consume(
                consumerId: consumerId,
                producerId: producerId,
                kind: kind == "audio" ? MediaKind.audio : MediaKind.video,
                rtpParameters: rtpParameters,
                appData: appData.toJSONString()
            )
            
            if consumer?.kind == .audio {
//                const remAudio = new MediaStream();
//                let remoteStreamAudio: any = document.getElementById('remote-audio');
//                remAudio.addTrack(track);
//                useVideoCallStore.getState().setRemoteAudioStream(remAudio);
//                remoteStreamAudio.srcObject = remAudio;
            } else {
                //TODO: for video
            }
            
            let originalRequestId = UUID().uuidString
            self.webSocketController.resumeConsumer(
                originalRequestId: originalRequestId,
                meetingRoomId: meetingRoomId ?? "unknown",
                consumerId: consumerId
            )
        } catch {
            self.loggerController.sendLog(name: "DeviceSendTransport:ConsumeConsumer failed", properties: [
                "error": error.localizedDescription
            ])
        }

    }
    
    private func createWebRTCTransportConsumer(consumerTransportId: String, rtpCapabilities: String, mediaServerProducer: MediaServerProducer) {
        let originalRequestId = UUID().uuidString

        self.webSocketController.createWebRTCTransportConsumer(
            originalRequestId: originalRequestId,
            meetingRoomId: meetingRoomId ?? "unknown",
            consumerTransportId: consumerTransportId,
            producerId: mediaServerProducer.id,
            rtpCapabilities: rtpCapabilities,
            mediaType: mediaServerProducer.mediaType
        )
    }

}

extension DeviceController: ProducerDelegate {
    
    func onTransportClose(in producer: Producer) {
        self.loggerController.sendLog(name: "DeviceProducer:OnTransportClose:\(producer.id)", properties: nil)
    }
    
}
