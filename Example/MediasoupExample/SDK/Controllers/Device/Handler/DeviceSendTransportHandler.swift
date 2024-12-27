//
//  DeviceSendTransportHandler.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 27/12/24.
//

import Mediasoup

class DeviceSendTransportHandler {
    
    private let loggerController: LoggerControllerProtocol
    
    init(loggerController: LoggerControllerProtocol) {
        self.loggerController = loggerController
    }
    
}

extension DeviceSendTransportHandler: SendTransportDelegate {
    
    func onProduce(transport: any Transport, kind: MediaKind, rtpParameters: String, appData: String, callback: @escaping (String?) -> Void) {
        self.loggerController.sendLog(name: "DeviceSendTransport:OnProduce:\(kind)", properties: nil)
        
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
        
        self.loggerController.sendLog(name: "DeviceSendTransport:OnProduceData:\(label)", properties: nil)
    }
    
    func onConnect(transport: any Transport, dtlsParameters: String) {
        
        self.loggerController.sendLog(name: "DeviceSendTransport:OnConnect:\(dtlsParameters)", properties: nil)
    }
    
    func onConnectionStateChange(transport: any Transport, connectionState: TransportConnectionState) {
        
        self.loggerController.sendLog(name: "DeviceSendTransport:OnConnectionStateChange:\(connectionState)", properties: nil)
    }
    
}
