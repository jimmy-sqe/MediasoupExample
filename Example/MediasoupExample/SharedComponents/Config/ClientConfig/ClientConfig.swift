//
//  ClientConfig.swift
//  SqeKycFrameworkExcludeVIDA
//
//  Created by Marthin Satrya Pasaribu on 12/02/24.
//

import Foundation

public struct ClientConfig: Decodable {
    let environment: String
    let configExpiryTime: Double?
    let mobileClientId: String
    let externalConfig: ExternalConfig
    let sqekyc: SqeKycClientConfig?
    
    struct SqeKycClientConfig: Decodable {
        let livenessApiKey: String
        let livenessLicenseKey: String
    }
    
    struct ExternalConfig: Decodable {
        let crashMonitoringToken: String
        let isClientUseSentry: Bool?
    }
    
    init(environment: String,
         configExpiryTime: Double? = nil,
         mobileClientId: String,
         externalConfig: ExternalConfig,
         sqekyc: SqeKycClientConfig? = nil
    ) {
        self.environment = environment
        self.configExpiryTime = configExpiryTime
        self.mobileClientId = mobileClientId
        self.externalConfig = externalConfig
        self.sqekyc = sqekyc
    }
}
