//
//  MakeCall.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 23/12/24.
//

import Combine
import Foundation

class ManageRoom {
    
    var username: PassthroughSubject<String?, Never> = PassthroughSubject()
    var roomStatus: PassthroughSubject<String?, Never> = PassthroughSubject()

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
    private var cancellables = Set<AnyCancellable>()
    private let wsToken: String
    private let env: SqeCcEnvironment
    private let loggerController: LoggerControllerProtocol
    private let storage: Storage
    private let authController: AuthControllerProtocol
    private let conversationController: ConversationControllerProtocol
    private var webSocketController: WebSocketControllerProtocol
    private var deviceController: DeviceControllerProtocol

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
        self.roomStatus.send(completion: .finished)
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
                self.roomStatus.send(status.callJoinStatus.displayText)
            case .failure:
                break
            }
        }
    }
    
    func joinMeetingRoom() {
        guard let meetingRoomId else { return }
        
        webSocketController
            .joinMeetingRoom(originalRequestId: UUID().uuidString, meetingRoomId: meetingRoomId)
            .flatMap { [weak self] message in
                guard let self else {
                    return Future<WebSocketReceiveMessage, Never> { promise in
                        promise(.success(WebSocketReceiveMessage(event: .unknown)))
                    }
                }

                self.loggerController.sendLog(name: "ManageRoom:joinMeetingRoom succeed", properties: nil)

                let username: String? = {
                    let joiningUser = message.data?["joiningUser"] as? [String: Any]
                    return joiningUser?["name"] as? String
                }();
                self.username.send(username)
                self.roomStatus.send("Joined")

                return self.webSocketController.getRTPCapabilities(originalRequestId: UUID().uuidString, meetingRoomId: meetingRoomId)
            }
            .sink { [weak self] message in
                guard let self else { return }
                
                if let rtpCapabilitiesString = (message.data?["rtpCapabilities"] as? [String: Any])?.toJSONString() {
                    self.loggerController.sendLog(name: "ManageRoom:getRTPCapabilities succeed", properties: ["rtpCapabilities": rtpCapabilitiesString])
                    self.setupDevice(rtpCapabilities: rtpCapabilitiesString)
                } else {
                    self.loggerController.sendLog(name: "ManageRoom:getRTPCapabilities failed", properties: ["error": "Invalid rtpCapabilities"])
                }
            }.store(in: &cancellables)
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
    }
    
    func onMediaServerProducersReceived(mediaServerProducers: [[String: Any]]) {
        self.loggerController.sendLog(name: "ManageRoom:OnMediaServerProducersReceived", properties: [
            "mediaServerProducers": mediaServerProducers
        ])
        
        self.mediaServerProducers = mediaServerProducers
    }
    
    func onMediaServerError(errorMessage: String) {
        self.roomStatus.send("Error: \(errorMessage)")
    }
}

extension ManageRoom: DeviceControllerDelegate {
    
    func onDeviceLoaded() {
        guard let meetingRoomId else { return }
        
        var sendTransportParam: DeviceTransportParam?
        var receiveTransportParam: DeviceTransportParam?
        
        webSocketController
            .createWebRTCTransport(originalRequestId: UUID().uuidString, meetingRoomId: meetingRoomId)
            .flatMap { [weak self] message in
                guard let self else {
                    return Future<WebSocketReceiveMessage, Never> { promise in
                        promise(.success(WebSocketReceiveMessage(event: .unknown)))
                    }
                }
                
                
                let id = message.data?["id"] as? String ?? "unknown"
                let iceParameters = message.data?["iceParameters"] as? String ?? "unknown"
                let iceCandidates = message.data?["iceCandidates"] as? String ?? "unknown"
                let dtlsParameters = message.data?["dtlsParameters"] as? String ?? "unknown"
                
                sendTransportParam = DeviceTransportParam(
                    id: id,
                    iceParameters: iceParameters,
                    iceCandidates: iceCandidates,
                    dtlsParameters: dtlsParameters
                )
                self.loggerController.sendLog(name: "ManageRoom:createWebRTCSendTransport succeed", properties: ["id": id])
                
                return self.webSocketController
                    .createWebRTCTransport(originalRequestId: UUID().uuidString, meetingRoomId: meetingRoomId)
            }.sink { [weak self] message in
                guard let self else { return }
                
                let id = message.data?["id"] as? String ?? "unknown"
                let iceParameters = message.data?["iceParameters"] as? String ?? "unknown"
                let iceCandidates = message.data?["iceCandidates"] as? String ?? "unknown"
                let dtlsParameters = message.data?["dtlsParameters"] as? String ?? "unknown"
                
                receiveTransportParam = DeviceTransportParam(
                    id: id,
                    iceParameters: iceParameters,
                    iceCandidates: iceCandidates,
                    dtlsParameters: dtlsParameters
                )
                self.loggerController.sendLog(name: "ManageRoom:createWebRTCReceiveTransport succeed", properties: ["id": id])
                
                guard let sendTransportParam, let receiveTransportParam else {
                    self.loggerController.sendLog(name: "ManageRoom:transportParam failed", properties: ["error": "Invalid sendTransportParam and receiveTransportParam"])
                    return
                }
                
                self.deviceController.createSendTransport(param: sendTransportParam)
                self.deviceController.createReceiveTransport(param: receiveTransportParam)
                
                guard let mediaServerProducers = self.mediaServerProducers, !mediaServerProducers.isEmpty else {
                    self.loggerController.sendLog(name: "ManageRoom:mediaServerProducers failed", properties: ["error": "Invalid mediaServerProducers"])
                    return
                }
                
                self.deviceController.createProducer(mediaServerProducers: mediaServerProducers)
            }.store(in: &cancellables)
    }
    
}
