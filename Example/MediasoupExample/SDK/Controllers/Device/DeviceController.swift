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
    
    func checkAudioPermission()
    func setup()
    func loadDevice(rtpCapabilities: String)
    func createSendTransport(param: DeviceTransportParam)
    func createReceiveTransport(param: DeviceTransportParam)
    func createProducer(meetingRoomId: String, mediaServerProducers: [MediaServerProducer]?)

}

class DeviceController: DeviceControllerProtocol {
    
    weak var delegate: DeviceControllerDelegate?
    
    private let peerConnectionFactory = RTCPeerConnectionFactory()
    private var mediaStream: RTCMediaStream?
    private var audioTrack: RTCAudioTrack?
    private var videoTrack: RTCVideoTrack?

    private var device: Device?
    
    private var rtpCapabilities: String?
    
    private var sendTransport: SendTransport?
    private var producerTransportId: String?
    private var producer: Producer?
    private let deviceSendTransportHandler: DeviceSendTransportHandler
    
    private var receiveTransport: ReceiveTransport?
    private var consumerTransportId: String?
    private var consumer: Consumer?
    private let deviceReceiveTransportHandler: DeviceReceiveTransportHandler

    private let loggerController: LoggerControllerProtocol

    init(loggerController: LoggerControllerProtocol,
         webSocketController: WebSocketControllerProtocol) {
        self.loggerController = loggerController

        self.deviceSendTransportHandler = DeviceSendTransportHandler(loggerController: loggerController, webSocketController: webSocketController)
        self.deviceReceiveTransportHandler = DeviceReceiveTransportHandler(loggerController: loggerController)
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
            sendTransport.delegate = self.deviceSendTransportHandler
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
    
    func createProducer(meetingRoomId: String, mediaServerProducers: [MediaServerProducer]?) {
        guard let sendTransport, let audioTrack else { return }
        
        self.loggerController.sendLog(name: "Device:CreateProducer", properties: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            do {
                let appData: [String: Any] = [
                    "meetingRoomId": meetingRoomId,
                    "producerTransportId": self.producerTransportId ?? "unknown",
                    "consumerTransportId": self.consumerTransportId ?? "unknown",
                    "rtpCapabilities": self.rtpCapabilities ?? "unknown",
                    "mediaType": "audio",
                    "mediaServerProducers": mediaServerProducers ?? "unknown"
                ]
                let producer = try sendTransport.createProducer(for: audioTrack, encodings: nil, codecOptions: nil, codec: nil, appData: appData.toJSONString())
                self.producer = producer
                producer.delegate = self.deviceSendTransportHandler
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
