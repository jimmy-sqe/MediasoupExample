//
//  Event.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 24/12/24.
//

import Foundation

final class WebSocketMessage: NSObject {
    
    let event: WebSocketEvent
    
    init(
        event: WebSocketEvent
    ) {
        self.event = event
    }
    
}

extension WebSocketMessage: Codable {

    enum CodingKeys: String, CodingKey {
        case event
    }
    
    public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let eventString = try values.decode(String.self, forKey: .event)
        
        self.init(
            event: WebSocketEvent(rawValue: eventString) ?? .unknown
        )
    }

}
