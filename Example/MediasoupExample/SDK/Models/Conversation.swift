//
//  Conversation.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 24/12/24.
//

import Foundation

final class ConversationData: NSObject {
    
    let data: [Conversation]
    
    init(
        data: [Conversation]
    ) {
        self.data = data
    }
    
}

final class Conversation: NSObject {
    
    let meetingRoomId: String
    
    init(
        meetingRoomId: String
    ) {
        self.meetingRoomId = meetingRoomId
    }
    
}

extension ConversationData: Codable {

    enum CodingKeys: String, CodingKey {
        case data
    }
    
    public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let data = try values.decode([Conversation].self, forKey: .data)
        
        self.init(
            data: data
        )
    }

}

extension Conversation: Codable {

    enum CodingKeys: String, CodingKey {
        case meetingRoomId
    }
    
    public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let meetingRoomId = try values.decode(String.self, forKey: .meetingRoomId)
        
        self.init(
            meetingRoomId: meetingRoomId
        )
    }

}
