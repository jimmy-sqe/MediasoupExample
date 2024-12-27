//
//  WebSocketDataMessage.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 27/12/24.
//

//struct WebSocketReceiveData<T: Codable> {
//    
//    let data: T
//
//    init(
//        data: T
//    ) {
//        self.data = data
//    }
//    
//}
//
//extension WebSocketReceiveData: Codable {
//
//    enum CodingKeys: String, CodingKey {
//        case data
//    }
//    
//    init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        
//        let data = try values.decode(T.self, forKey: .data)
//
//        self.init(
//            data: data
//        )
//    }
//
//}
