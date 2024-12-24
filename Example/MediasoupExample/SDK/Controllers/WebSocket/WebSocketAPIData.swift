//
//  WebSocketAPIData.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 24/12/24.
//


enum WebSocketAPIData: NetworkAPIData {
    case connect(String, String)
    
    var path: String {
        switch self {
            case .connect:
                return "web-widget/cable"
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
        }
    }
}
