//
//  MakeCall.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 23/12/24.
//

import Foundation

class ManageRoom {
    
    var onRoomStatusUpdated: ((String) -> Void)? = nil
    
    private let AUTH_TOKEN_KEY: String = "AUTH_TOKEN_KEY"
    
    private var authToken: String? {
        didSet {
            if let authToken {
                storage.set(authToken, forKey: AUTH_TOKEN_KEY)
            }
        }
    }
    
    private var meetingRoomId: String? {
        didSet {
            self.deviceController.meetingRoomId = meetingRoomId
        }
    }
    
    private var mediaServerProducers: [[String: Any]]?
    private let wsToken: String
    private let env: SqeCcEnvironment
    private let loggerController: LoggerControllerProtocol
    private let storage: Storage
    private let authController: AuthControllerProtocol
    private let conversationController: ConversationControllerProtocol
    private var webSocketController: WebSocketControllerProtocol
    private var deviceController: DeviceControllerProtocol
    private var originalRequestIds = [WebSocketRequestType: String]()

    init(env: SqeCcEnvironment,
         wsToken: String,
         loggerController: LoggerControllerProtocol,
         storage: Storage,
         authController: AuthControllerProtocol? = nil,
         conversationController: ConversationControllerProtocol? = nil,
         webSocketController: WebSocketControllerProtocol? = nil,
         deviceController: DeviceControllerProtocol? = nil) {
        
        self.env = env
        self.wsToken = wsToken
        self.loggerController = loggerController
        self.storage = storage
        
        self.authController = authController ?? AuthController(baseUrl: env.apiBaseUrl.absoluteString, wsToken: wsToken, loggerController: loggerController)
        self.conversationController = conversationController ?? ConversationController(baseUrl: env.apiBaseUrl.absoluteString, wsToken: wsToken, loggerController: loggerController)
        self.webSocketController = webSocketController ?? WebSocketController(baseUrl: env.wsBaseUrl.absoluteString, loggerController: loggerController)
        self.deviceController = deviceController ?? DeviceController(loggerController: loggerController, webSocketController: self.webSocketController)
    }
    
    deinit {
        self.webSocketController.disconnect()
    }
    
    func setup() {
        self.webSocketController.delegate = self
        self.deviceController.delegate = self
        
        self.deviceController.checkAudioPermission()
        
        if let token: String = storage.get(forKey: AUTH_TOKEN_KEY) {
            //TODO: Check whether token is still valid or not
            
            self.authToken = token
            self.webSocketController.connect(wsToken: self.wsToken, cwToken: token)
            self.checkStatus()
        }
    }
    
    func doAuthAndConnectWebSocket(name: String, phone: String) {
        let requestParam = AuthRequestParam(name: name, phone: phone)
        authController.doAuth(requestParam: requestParam) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let auth):
                self.authToken = auth.token
                self.webSocketController.connect(wsToken: self.wsToken, cwToken: auth.token)
                self.checkStatus()
            case .failure:
                break
            }
        }
    }
    
    func selectCommunicationMode(_ communicationMode: CommunicationMode) {
        guard let authToken else { return }
        
        conversationController.selectCommunicationMode(authToken: authToken, communicationMode: .audioVideo) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(_):
                self.checkStatus()
            case .failure:
                break
            }
        }
    }
    
    func checkStatus() {
        guard let authToken else { return }
        
        conversationController.checkStatus(authToken: authToken) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let status):
                self.meetingRoomId = status.meetingRoomId
                self.onRoomStatusUpdated?(status.callJoinStatus.displayText)
            case .failure:
                break
            }
        }
    }
    
    func joinMeetingRoom() {
        guard let meetingRoomId else { return }
        
        let originalRequestId = UUID().uuidString
        webSocketController.joinMeetingRoom(originalRequestId: originalRequestId, meetingRoomId: meetingRoomId)
    }
    
    func getRTPCapabilities() {
        guard let meetingRoomId else { return }
        let originalRequestId = UUID().uuidString
        
        webSocketController.getRTPCapabilities(originalRequestId: originalRequestId, meetingRoomId: meetingRoomId)
    }
    
    func createWebRTCTransport(requestType: WebSocketRequestType) {
        guard let meetingRoomId else { return }
        let originalRequestId = UUID().uuidString
        self.originalRequestIds[requestType] = originalRequestId
        
        webSocketController.createWebRTCTransport(originalRequestId: originalRequestId, meetingRoomId: meetingRoomId)
    }
    
    private func createConversation() {
        guard let authToken else { return }
        
        conversationController.createConversation(authToken: authToken) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let conversation):
                self.meetingRoomId = conversation.meetingRoomId
                self.selectCommunicationMode(.audioVideo)
            case .failure:
                break
            }
            
        }
    }
    
    private func setupDevice(rtpCapabilities: String) {
        self.deviceController.setup()
        
        self.deviceController.loadDevice(rtpCapabilities: rtpCapabilities)
    }
    
}

extension ManageRoom: WebSocketControllerDelegate {
    
    func onWebSocketConnected() {
        self.loggerController.sendLog(name: "ManageRoom:OnWebSocketConnected", properties: nil)
        
        self.createConversation()
    }
    
    func onRequestToJoinApproved() {
        self.loggerController.sendLog(name: "ManageRoom:OnRequestToJoinApproved", properties: nil)
        
        self.joinMeetingRoom()
        self.getRTPCapabilities()
    }
    
    func onUserJoinedMeetingRoom() {
        self.loggerController.sendLog(name: "ManageRoom:OnUserJoinedMeetingRoom", properties: nil)
        
        self.onRoomStatusUpdated?("User Joined Meeting Room")
    }
    
    func onMediaServerProducersReceived(mediaServerProducers: [[String: Any]]) {
        self.loggerController.sendLog(name: "ManageRoom:OnMediaServerProducersReceived", properties: [
            "mediaServerProducers": mediaServerProducers
        ])
        
        self.mediaServerProducers = mediaServerProducers
    }
    
    func onRTPCapabilitiesReceived(rtpCapabilities: String) {
        self.loggerController.sendLog(name: "ManageRoom:OnRTPCapabilitiesReceived", properties: ["rtpCapabilities": rtpCapabilities])
        
        self.setupDevice(rtpCapabilities: rtpCapabilities)
    }
    
    func onWebRTCTransportReceived(originalRequestId: String, id: String, iceParameters: String, iceCandidates: String, dtlsParameters: String) {
        self.loggerController.sendLog(name: "ManageRoom:OnWebRTCTransportReceived", properties: ["id": id])
        
        let param = DeviceTransportParam(id: id, iceParameters: iceParameters, iceCandidates: iceCandidates, dtlsParameters: dtlsParameters)

        let key = (self.originalRequestIds.first { $0.value == originalRequestId })?.key
        
        switch key {
        case .webRTCSendTransport:
            self.deviceController.createSendTransport(param: param)
            if let mediaServerProducers = mediaServerProducers, !mediaServerProducers.isEmpty {
                self.deviceController.createProducer(mediaServerProducers: mediaServerProducers)
            } else {
                self.loggerController.sendLog(name: "ManageRoom:CreateProducer failed", properties: ["error": "Invalid mediaServerProducers"])
            }
        case .webRTCReceiveTransport:
            self.deviceController.createReceiveTransport(param: param)
        default:
            break
        }
    }
    
}

extension ManageRoom: DeviceControllerDelegate {
    
    func onDeviceLoaded() {
        self.createWebRTCTransport(requestType: .webRTCSendTransport)
        self.createWebRTCTransport(requestType: .webRTCReceiveTransport)
    }
    
}
