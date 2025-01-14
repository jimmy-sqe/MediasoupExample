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
    case createWebRTCTransportProducer = "CREATE_WEBRTC_TRANSPORT_PRODUCER"
    case createWebRTCTransportConsumer = "CREATE_WEBRTC_TRANSPORT_CONSUMER"
    case connectWebRTCTransport = "CONNECT_WEBRTC_TRANSPORT"
    case resumeConsumerStreamRequest = "RESUME_CONSUMER_STREAM_REQUEST"
    case restartICE = "RESTART_ICE"

}
