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
    
    private var cancellables = Set<AnyCancellable>()
    private let loggerController: LoggerControllerProtocol
    private let webSocketController: WebSocketControllerProtocol

    init(loggerController: LoggerControllerProtocol,
         webSocketController: WebSocketControllerProtocol) {
        self.loggerController = loggerController
        self.webSocketController = webSocketController
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
    }
    
}
