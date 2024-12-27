//
//  Event.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 24/12/24.
//

import Foundation

struct WebSocketReceiveMessage {
    
    let event: WebSocketReceiveEvent
    let originalRequestId: String?

    init(
        event: WebSocketReceiveEvent,
        originalRequestId: String?
    ) {
        self.event = event
        self.originalRequestId = originalRequestId
    }
    
}

extension WebSocketReceiveMessage: Codable {

    enum CodingKeys: String, CodingKey {
        case event
        case originalRequestId
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let eventString = try values.decode(String.self, forKey: .event)
        let originalRequestId = try? values.decode(String.self, forKey: .originalRequestId)

        self.init(
            event: WebSocketReceiveEvent(rawValue: eventString) ?? .unknown,
            originalRequestId: originalRequestId
        )
    }

}
