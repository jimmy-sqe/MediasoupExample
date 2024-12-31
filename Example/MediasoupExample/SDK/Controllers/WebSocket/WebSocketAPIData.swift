//
//  WebSocketAPIData.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 24/12/24.
//


enum WebSocketAPIData: NetworkAPIData {
    case connect(String, String)
    case sendEvent(WebSocketSendEvent, [String: Any])

    var path: String {
        switch self {
            case .connect:
                return "web-widget/cable"
            case .sendEvent:
                return ""
        }
    }
    
    var parameters: NetworkRequestParams {
        switch self {
        case .connect(let wsToken, let cwToken):
            let urlParameters: [String: Any] = [
                "websiteToken": wsToken,
                "cwToken": cwToken
            ]
            return NetworkRequestParams(urlParameters: urlParameters)
        case .sendEvent(let event, let params):
            
            let paramsWithEvent = params.merging([
                "event": event.rawValue
            ]) { _, new in new }

            return NetworkRequestParams(bodyParameters: paramsWithEvent)
        }
    }
}
