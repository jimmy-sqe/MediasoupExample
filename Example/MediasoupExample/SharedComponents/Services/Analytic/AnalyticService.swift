//
//  AnalyticService.swift
//  SqeIdFramework
//
//  Created by Jimmy Suhartono on 11/07/24.
//

import Foundation

class AnalyticService: Analytic {
    
    private let allAnalytics: [Analytic]
    private let UsernameKey = "username"
    
    init(env: SqeCommonEnvironment, clientId: String, datadogClientToken: String, allAnalytics: [Analytic]? = nil) {
        
        if let allAnalytics = allAnalytics {
            self.allAnalytics = allAnalytics
        } else {
            let datadogLogs: Analytic = DatadogLogs(env: env, clientToken: datadogClientToken, clientId: clientId)

            self.allAnalytics = [
                datadogLogs
            ]
        }

    }

    func setUserInfo(phoneNumber: String, properties: [String : Any]?) {
        guard let encryptedPhoneNumber = PhoneNumberEncryptionUtil.encrypt(phoneNumber) else { return }
        
        allAnalytics.forEach {
            $0.setUserInfo(phoneNumber: encryptedPhoneNumber, properties: properties)
        }
    }
    
    func sendEvent(name: String, properties: [String: Any]?) {
        var mutableProperties: [String: Any]? = properties
        
        if let properties,
           properties.keys.contains(UsernameKey) {
            if let username = properties[UsernameKey] as? String,
               let encryptedUsername = PhoneNumberEncryptionUtil.encrypt(username) {
                mutableProperties?[UsernameKey] = encryptedUsername
            }
        }
        
        allAnalytics.forEach {
            $0.sendEvent(name: name, properties: mutableProperties)
        }
    }
    
}
