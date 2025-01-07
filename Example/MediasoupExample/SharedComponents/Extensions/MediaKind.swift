//
//  MediaKind.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 07/01/25.
//

import Mediasoup

extension MediaKind {
    
    var string: String {
        switch self {
        case .audio:
            return "audio"
        case .video:
            return "video"
        default:
            return "unknown"
        }
    }
    
}
