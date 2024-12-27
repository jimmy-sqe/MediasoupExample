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
    func createProducer()

}

class DeviceController: DeviceControllerProtocol {
    
    weak var delegate: DeviceControllerDelegate?
    
    private let peerConnectionFactory = RTCPeerConnectionFactory()
    private var mediaStream: RTCMediaStream?
    private var audioTrack: RTCAudioTrack?
    private var videoTrack: RTCVideoTrack?

    private let device = Device()
    
    private var sendTransport: SendTransport?
    private var producer: Producer?
    private let deviceSendTransportHandler: DeviceSendTransportHandler
    
    private var receiveTransport: ReceiveTransport?
    private var consumer: Consumer?
    private let deviceReceiveTransportHandler: DeviceReceiveTransportHandler

    private let loggerController: LoggerControllerProtocol
    
    init(loggerController: LoggerControllerProtocol) {
        self.loggerController = loggerController
        
        self.deviceSendTransportHandler = DeviceSendTransportHandler(loggerController: loggerController)
        self.deviceReceiveTransportHandler = DeviceReceiveTransportHandler(loggerController: loggerController)
    }
    
    deinit {
        self.sendTransport?.close()
        self.receiveTransport?.close()
    }
    
    func checkAudioPermission() {
        if AVCaptureDevice.authorizationStatus(for: .audio) != .authorized {
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
            //TODO: Should restart app
        }
    }
    
    func setup() {
        mediaStream = peerConnectionFactory.mediaStream(withStreamId: "mediaStream")
        
        let audioTrack = peerConnectionFactory.audioTrack(withTrackId: "audio")
        self.audioTrack = audioTrack
        
        mediaStream?.addAudioTrack(audioTrack)
        
        let videoSource = peerConnectionFactory.videoSource()
        let videoTrack = peerConnectionFactory.videoTrack(with: videoSource, trackId: "video")
        self.videoTrack = videoTrack
        
        mediaStream?.addVideoTrack(videoTrack)
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
        self.loggerController.sendLog(name: "Device:CreateSendTransport", properties: [
            "id": param.id,
            "iceParameters": param.iceParameters,
            "iceCandidates": param.iceCandidates,
            "dtlsParameters": param.dtlsParameters
        ])

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
        self.loggerController.sendLog(name: "Device:CreateReceiveTransport", properties: [
            "id": param.id,
            "iceParameters": param.iceParameters,
            "iceCandidates": param.iceCandidates,
            "dtlsParameters": param.dtlsParameters
        ])
        
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
    
    func createProducer() {
        guard let sendTransport, let audioTrack else { return }
        
        self.loggerController.sendLog(name: "Device:CreateProducer", properties: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let producer = try? sendTransport.createProducer(for: audioTrack, encodings: nil, codecOptions: nil, codec: nil, appData: nil) {
                self.producer = producer
                producer.delegate = self.deviceSendTransportHandler
                producer.resume()
                self.loggerController.sendLog(name: "Device:CreateProducer succeed", properties: nil)
            } else {
                self.loggerController.sendLog(name: "Device:CreateProducer failed", properties: nil)
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
        
        self.loggerController.sendLog(name: "Device:\(subject) failed", properties: [
            "error": errorMessage
        ])
    }
    
}
