//
//  Event.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 24/12/24.
//

import Foundation

struct WebSocketReceiveMessage {
    
    let event: WebSocketReceiveEvent

    init(
        event: WebSocketReceiveEvent
    ) {
        self.event = event
    }
    
}

extension WebSocketReceiveMessage: Codable {

    enum CodingKeys: String, CodingKey {
        case event
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let eventString = try values.decode(String.self, forKey: .event)
        
        self.init(
            event: WebSocketReceiveEvent(rawValue: eventString) ?? .unknown
        )
    }

}
