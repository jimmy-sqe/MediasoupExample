//
//  ClientConfig.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 23/12/24.
//

import Foundation

public struct ClientConfig: Decodable {
    let environment: String
    let configExpiryTime: Double?
    let mobileClientId: String
    let externalConfig: ExternalConfig
    
    struct ExternalConfig: Decodable {
        let crashMonitoringToken: String
        let isClientUseSentry: Bool?
    }
    
    init(environment: String,
        configExpiryTime: Double? = nil,
        mobileClientId: String,
        externalConfig: ExternalConfig) {
        self.environment = environment
        self.configExpiryTime = configExpiryTime
        self.mobileClientId = mobileClientId
        self.externalConfig = externalConfig
    }
}
