//
//  Auth.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 23/12/24.
//

import Foundation

final class Auth: NSObject {
    
    let token: String
    
    init(
        token: String
    ) {
        self.token = token
    }
    
}

extension Auth: Codable {

    enum CodingKeys: String, CodingKey {
        case token
    }
    
    public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let token = try values.decode(String.self, forKey: .token)
        
        self.init(
            token: token
        )
    }

}
