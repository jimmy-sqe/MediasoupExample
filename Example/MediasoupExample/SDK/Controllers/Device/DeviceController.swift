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

}

class DeviceController: DeviceControllerProtocol {
    
    weak var delegate: DeviceControllerDelegate?
    
    private let peerConnectionFactory = RTCPeerConnectionFactory()
    private var mediaStream: RTCMediaStream?
    private var audioTrack: RTCAudioTrack?
    
    private let device = Device()
    
    private var sendTransport: SendTransport?
    private let deviceSendTransportHandler: DeviceSendTransportHandler
    private var receiveTransport: ReceiveTransport?
    private let deviceReceiveTransportHandler: DeviceReceiveTransportHandler
    
    private var producer: Producer?

    private let loggerController: LoggerControllerProtocol
    
    init(loggerController: LoggerControllerProtocol) {
        self.loggerController = loggerController
        
        self.deviceSendTransportHandler = DeviceSendTransportHandler(loggerController: loggerController)
        self.deviceReceiveTransportHandler = DeviceReceiveTransportHandler(loggerController: loggerController)
    }
    
    func checkAudioPermission() {
        if AVCaptureDevice.authorizationStatus(for: .audio) != .authorized {
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
            //TODO: Should restart app
        }
    }
    
    func setup() {
        mediaStream = peerConnectionFactory.mediaStream(withStreamId: TestData.MediaStream.mediaStreamId)
        let audioTrack = peerConnectionFactory.audioTrack(withTrackId: TestData.MediaStream.audioTrackId)
        mediaStream?.addAudioTrack(audioTrack)
        self.audioTrack = audioTrack
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
            self.handleError(error: error)
        }
    }
    
    func createSendTransport(param: DeviceTransportParam) {
        self.loggerController.sendLog(name: "Device:CreateSendTransport", properties: nil)

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
            self.handleError(error: error)
        }
    }
    
    func createReceiveTransport(param: DeviceTransportParam) {
        self.loggerController.sendLog(name: "Device:CreateReceiveTransport", properties: nil)

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
            self.handleError(error: error)
        }
    }
    
    private func handleError(error: Error) {
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
        
        self.loggerController.sendLog(name: "Device:error occurred failed", properties: [
            "error": errorMessage
        ])
    }
    
}
