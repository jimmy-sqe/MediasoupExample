//
//  Event.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 24/12/24.
//

enum WebSocketReceiveEvent: String, Codable {
    
    case webSocketConnected = "WEBSOCKET_CONNECTED"
    case requestToJoinApproved = "REQUEST_TO_JOIN_APPROVED"
    case rtpCapabilities = "RTP_CAPABILITIES"
    case userJoinedMeetingRoom = "USER_JOINED_MEETING_ROOM"
    case webRTCTransport = "WEBRTC_TRANSPORT"
    case mediaServerProducers = "MEDIA_SERVER_PRODUCERS"
    case userConnectedWebRTCTransport = "USER_CONNECTED_WEBRTC_TRANSPORT"
    case webRTCTransportProducerCreated = "WEBRTC_TRANSPORT_PRODUCER_CREATED"
    case webRTCTransportConsumerCreated = "WEBRTC_TRANSPORT_CONSUMER_CREATED"

    case unknown = "UNKNOWN"
    
}
