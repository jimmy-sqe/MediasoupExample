//
//  Time.swift
//  sqeid
//
//  Created by Jimmy Suhartono on 31/10/23.
//

import Foundation

public final class Time: NSObject {

    public let serverTime: Date

    // MARK: - Initializer

    /// Default initializer.
    public init(
        serverTime: Date
    ) {
        self.serverTime = serverTime
    }
    
    public override var debugDescription: String {
        return """
        serverTime = \(serverTime)
        """
    }

}

// MARK: - Codable

extension Time: Codable {

    enum CodingKeys: String, CodingKey {
        case serverTime = "epoch"
    }
    
    /// `Decodable` initializer.
    public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let serverTimeInDouble = try values.decode(Double.self, forKey: .serverTime)
        
        let serverTime = Date(timeIntervalSince1970: serverTimeInDouble)
        
        self.init(
            serverTime: serverTime
        )
    }

}
