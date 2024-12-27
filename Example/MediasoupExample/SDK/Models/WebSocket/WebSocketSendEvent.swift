//
//  WebSocketSendEvent.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 27/12/24.
//

enum WebSocketSendEvent: String, Codable {
    
    case joinMeetingRoom = "JOIN_MEETING_ROOM"
    case getRTPCabilities = "GET_RTP_CAPABILITIES"
    case createWebRTCTransport = "CREATE_WEBRTC_TRANSPORT"

}
