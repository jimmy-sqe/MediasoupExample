//
//  DeviceReceiveTransportHandler.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 27/12/24.
//

import Combine
import Foundation
import Mediasoup

class DeviceReceiveTransportHandler {
    
    var meetingRoomId: String?
    
    private var receiveTransport: ReceiveTransport?
    
    private var cancellables = Set<AnyCancellable>()
    private let loggerController: LoggerControllerProtocol
    private let webSocketController: WebSocketControllerProtocol

    init(loggerController: LoggerControllerProtocol,
         webSocketController: WebSocketControllerProtocol) {
        self.loggerController = loggerController
        self.webSocketController = webSocketController
    }
    
    func setReceiveTransport(_ receiveTransport: ReceiveTransport) {
        self.receiveTransport = receiveTransport
        self.receiveTransport?.delegate = self
    }
    
}

extension DeviceReceiveTransportHandler: ReceiveTransportDelegate {
    
    func onConnect(transport: any Transport, dtlsParameters: String) {
        self.loggerController.sendLog(name: "DeviceReceiveTransport:OnConnect", properties: nil)
        
        Task.synchronous {
            await withCheckedContinuation { continuation in
                self.webSocketController.connectWebRTCTransport(
                    originalRequestId: UUID().uuidString,
                    meetingRoomId: self.meetingRoomId ?? "unknown",
                    transportId: transport.id,
                    dtlsParameters: dtlsParameters.toDictionary() ?? ["unknown": "unknown"]
                ).sink { _ in
                    self.loggerController.sendLog(name: "DeviceReceiveTransport:connectWebRTCTransport succeed", properties: nil)
                    continuation.resume()
                }.store(in: &self.cancellables)
            }
        }
    }
    
    func onProduce(transport: any Transport, kind: MediaKind, rtpParameters: String, appData: String, callback: @escaping (String?) -> Void) {
        self.loggerController.sendLog(name: "DeviceReceiveTransport:OnProduce", properties: nil)
    }
    
    func onProduceData(transport: any Transport, sctpParameters: String, label: String, protocol dataProtocol: String, appData: String, callback: @escaping (String?) -> Void) {
        self.loggerController.sendLog(name: "DeviceReceiveTransport:OnProduceData:\(label)", properties: nil)
    }
    
    func onConnectionStateChange(transport: any Transport, connectionState: TransportConnectionState) {
        self.loggerController.sendLog(name: "DeviceReceiveTransport:OnConnectionStateChange:\(connectionState)", properties: nil)
        
        switch connectionState {
        case .disconnected, .failed:
            restartIce(transportId: transport.id);
        default:
            //TODO: Implement timeout please refer to FE implementation
            break
        }
    }
    
    private func restartIce(transportId: String) {
        self.loggerController.sendLog(name: "DeviceReceiveTransport:RestartIce", properties: [
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
                self?.loggerController.sendLog(name: "DeviceReceiveTransport:RestartIce failed", properties: [
                    "transportId": transportId,
                    "error": "Invalid iceParameters"
                ])
                return
            }
            
            do {
                try self.receiveTransport?.restartICE(with: iceParameters)
                self.loggerController.sendLog(name: "DeviceReceiveTransport:RestartIce succeed", properties: [
                    "transportId": transportId
                ])
            } catch {
                self.loggerController.sendLog(name: "DeviceReceiveTransport:RestartIce failed", properties: [
                    "transportId": transportId,
                    "error": error.localizedDescription
                ])
            }
        }.store(in: &cancellables)
    }
}
