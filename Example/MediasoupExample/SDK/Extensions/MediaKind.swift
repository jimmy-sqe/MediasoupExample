//
//  MediaKind.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 07/01/25.
//

import Mediasoup

extension MediaKind {
    
    var rawValue: String {
        switch self {
        case .audio:
            return "audio"
        case .video:
            return "video"
        default:
            return "unknown"
        }
    }
    
    init(rawValue: String) {
        if rawValue == "audio" {
            self = .audio
        } else {
            self = .video
        }
    }
    
}
