//
//  MediaServerProducerType.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 27/12/24.
//

final class MediaServerProducer {
    
    let id: String
    let kind: String
    let mediaType: String

    init(
        id: String,
        kind: String,
        mediaType: String
    ) {
        self.id = id
        self.kind = kind
        self.mediaType = mediaType
    }
    
}

extension MediaServerProducer: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case mediaType
    }
    
    convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let id = try values.decode(String.self, forKey: .id)
        let kind = try values.decode(String.self, forKey: .kind)
        let mediaType = try values.decode(String.self, forKey: .mediaType)

        self.init(
            id: id,
            kind: kind,
            mediaType: mediaType
        )
    }

}
