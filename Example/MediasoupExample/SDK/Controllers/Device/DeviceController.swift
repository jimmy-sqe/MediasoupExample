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
        
}

class DeviceController: DeviceControllerProtocol {
    
    weak var delegate: DeviceControllerDelegate?
    
    private let peerConnectionFactory = RTCPeerConnectionFactory()
    private var mediaStream: RTCMediaStream?
    private var audioTrack: RTCAudioTrack?
    
    private var device: Device?
    private var sendTransport: SendTransport?
    private var producer: Producer?

    private let loggerController: LoggerControllerProtocol
    
    init(loggerController: LoggerControllerProtocol) {
        self.loggerController = loggerController
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
        
        let device = Device()
        self.device = device
    }
    
    func loadDevice(rtpCapabilities: String) {
        self.loggerController.sendLog(name: "Device:LoadDevice", properties: nil)
        
        guard let device, AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
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
            
        } catch let error as MediasoupError {
            let errorMessage: String
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
            self.loggerController.sendLog(name: "Device:LoadDevice failed", properties: [
                "error": errorMessage
            ])
        } catch {
            self.loggerController.sendLog(name: "Device:LoadDevice failed", properties: [
                "error": error.localizedDescription
            ])
        }
    }
    
}

extension DeviceController: SendTransportDelegate {
    
    func onProduce(transport: any Transport, kind: MediaKind, rtpParameters: String, appData: String, callback: @escaping (String?) -> Void) {
        
        self.loggerController.sendLog(name: "Device:OnProduce:\(kind)", properties: nil)
        
        //        print("on produce \(kind)")
        //        //TODO:
        //        //rtpParameters: diubah sedikit ditambah manual baris 150
        //        //newRtpParam: masukin lagi
        //        //balikin lagi ke BE pakai WebSocket
        //        //BE balikin originalRequestID
        //        //Save producerId dari res.data.producer.id
        //        //Panggil callback
    }
    
    func onProduceData(transport: any Transport, sctpParameters: String, label: String, protocol dataProtocol: String, appData: String, callback: @escaping (String?) -> Void) {
        
        self.loggerController.sendLog(name: "Device:OnProduceData:\(label)", properties: nil)
    }
    
    func onConnect(transport: any Transport, dtlsParameters: String) {
        
        self.loggerController.sendLog(name: "Device:OnConnect:\(dtlsParameters)", properties: nil)
    }
    
    func onConnectionStateChange(transport: any Transport, connectionState: TransportConnectionState) {
        
        self.loggerController.sendLog(name: "Device:OnConnectionStateChange:\(connectionState)", properties: nil)
    }
    
}
