//
//  SDKConfigHandler.swift
//  SqeIdFramework
//
//  Created by Jimmy Suhartono on 12/07/24.
//

import Foundation

public protocol SDKConfigHandler {
    var sdkConfig: SDKConfig { get }
}

class SDKConfigHandlerImpl: SDKConfigHandler {
    let sdkConfig: SDKConfig
    
    init(env: String) throws {
        let sdkConfigs = SDKConfigs(rawValue: env)!
        
        let primaryId = sdkConfigs.primaryId
        let secondaryId = sdkConfigs.secondaryId
        
        let firstEncryptedConfigHandler = try! EncryptedConfigHandlerImpl(clientId: primaryId, bundleId: secondaryId)
        
        let finalPrimaryId = try! firstEncryptedConfigHandler.decrypt(encryptedConfig: sdkConfigs.encryptedPrimaryId)
        
        let finalSecondaryId = try! firstEncryptedConfigHandler.decrypt(encryptedConfig: sdkConfigs.encryptedSecondaryId)
        
        let secondEncryptedConfigHandler = try! EncryptedConfigHandlerImpl(clientId: finalPrimaryId, bundleId: finalSecondaryId)
        
        let encryptedConfig = sdkConfigs.encrypted
        
        let jsonString = try! secondEncryptedConfigHandler.decrypt(encryptedConfig: encryptedConfig)
        self.sdkConfig = try! SDKConfigHandlerImpl.decodeStringToDataModel(jsonString: jsonString)
    }
    
    private static func decodeStringToDataModel(jsonString: String) throws -> SDKConfig {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ConfigFileError.invalidJsonConfig
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let dataModel = try decoder.decode(SDKConfig.self, from: jsonData)
            return dataModel
        } catch {
            throw ConfigFileError.invalidDecodeConfig
        }
    }
    
}
