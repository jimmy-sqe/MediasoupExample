//
//  Status.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 24/12/24.
//

import Foundation

final class ConversationStatus: NSObject {
    
    let meetingRoomId: String
    let callJoinStatus: CallJoinStatus
    
    init(
        meetingRoomId: String,
        callJoinStatus: CallJoinStatus
    ) {
        self.meetingRoomId = meetingRoomId
        self.callJoinStatus = callJoinStatus
    }
    
}

final class CallJoinStatus: NSObject {
    
    let shouldJoinCall: String
    let displayText: String

    init(
        shouldJoinCall: String,
        displayText: String
    ) {
        self.shouldJoinCall = shouldJoinCall
        self.displayText = displayText
    }
    
}

extension ConversationStatus: Codable {

    enum CodingKeys: String, CodingKey {
        case meetingRoomId
        case callJoinStatus
    }
    
    public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let meetingRoomId = try values.decode(String.self, forKey: .meetingRoomId)
        let callJoinStatus = try values.decode(CallJoinStatus.self, forKey: .callJoinStatus)

        self.init(
            meetingRoomId: meetingRoomId,
            callJoinStatus: callJoinStatus
        )
    }

}

extension CallJoinStatus: Codable {

    enum CodingKeys: String, CodingKey {
        case shouldJoinCall
        case displayText
    }
    
    public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let shouldJoinCall = try values.decode(String.self, forKey: .shouldJoinCall)
        let displayText = try values.decode(String.self, forKey: .displayText)

        self.init(
            shouldJoinCall: shouldJoinCall,
            displayText: displayText
        )
    }

}
