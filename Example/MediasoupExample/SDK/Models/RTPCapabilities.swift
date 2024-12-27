//
//  RTPCapabilities.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 27/12/24.
//

//struct RTPCapabilities {
//    
//    let rtpCapabilities: DynamicDictionary
//    
//    init(
//        rtpCapabilities: DynamicDictionary
//    ) {
//        self.rtpCapabilities = rtpCapabilities
//    }
//    
//}
//
//extension RTPCapabilities: Codable {
//
//    enum CodingKeys: String, CodingKey {
//        case rtpCapabilities
//    }
//    
//    init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        
//        let rtpCapabilities = try values.decode(DynamicDictionary.self, forKey: .rtpCapabilities)
//        
//        self.init(
//            rtpCapabilities: rtpCapabilities
//        )
//    }
//
//}
