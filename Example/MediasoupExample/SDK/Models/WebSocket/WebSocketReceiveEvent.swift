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

    case unknown = "UNKNOWN"
    
}
