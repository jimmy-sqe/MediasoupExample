//
//  AuthAPIData.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 23/12/24.
//

import Foundation

enum ConversationAPIData: NetworkAPIData {
    
    case createConversation(String, String)
    case selectCommunicationMode(String, String, CommunicationMode)
    case checkStatus(String)

    var path: String {
        switch self {
            case .createConversation(_, let wsToken):
                "v1/widget/website-token/\(wsToken)/conversation"
            case .selectCommunicationMode(_, let wsToken, let communicationMode):
                "v1/widget/website-token/\(wsToken)/conversation/\(communicationMode.rawValue)"
            case .checkStatus:
                "v1/widget/call-order/status"
        }
    }
    
    var method: NetworkHTTPMethod {
        switch self {
        case .createConversation:
            .get
        case .selectCommunicationMode, .checkStatus:
            .post
        }
    }
    
    var headers: [String: String]? {
        switch self {
        case .createConversation(let authToken, _), .selectCommunicationMode(let authToken, _, _), .checkStatus(let authToken):
            ["Authorization": "jwt \(authToken)"]
        }
    }
}
