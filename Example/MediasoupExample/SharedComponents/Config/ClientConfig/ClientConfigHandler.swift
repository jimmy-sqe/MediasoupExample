//
//  ClientConfigHandler.swift
//  SqeIdFramework
//
//  Created by Jimmy Suhartono on 12/07/24.
//

import Foundation

public protocol ClientConfigHandler {
    func loadFromFile() throws -> ClientConfig
    func decrypt(encryptedConfig: String) throws -> ClientConfig
}

class ClientConfigHandlerImpl: ClientConfigHandler {
    private let encryptedConfigHandler: EncryptedConfigHandler
    private let encryptedConfig: String

    private static let configExtension: String = "config"
    private static let sdkFileNameExtension: String = "sqesdk"
    
    init(clientId: String, bundle: Bundle = Bundle.main) throws {
        let bundleId = Bundle.app.bundleIdentifier!
        let fileName = "\(clientId).\(ClientConfigHandlerImpl.sdkFileNameExtension)"
        self.encryptedConfig = try ClientConfigHandlerImpl.fetchEncryptedConfig(fileConfigName: fileName, bundle: bundle)
        
        self.encryptedConfigHandler = try EncryptedConfigHandlerImpl(clientId: clientId, bundleId: bundleId)
    }
    
    func loadFromFile() throws -> ClientConfig {
        let jsonString = try encryptedConfigHandler.decrypt(encryptedConfig: encryptedConfig)
        return try decodeStringToDataModel(jsonString: jsonString)
    }
    
    func decrypt(encryptedConfig: String) throws -> ClientConfig {
        let jsonString = try encryptedConfigHandler.decrypt(encryptedConfig: encryptedConfig)
        return try decodeStringToDataModel(jsonString: jsonString)
    }
    
    private func decodeStringToDataModel(jsonString: String) throws -> ClientConfig {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ConfigFileError.invalidJsonConfig
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let dataModel = try decoder.decode(ClientConfig.self, from: jsonData)
            return dataModel
        } catch {
            throw ConfigFileError.invalidDecodeConfig
        }
    }
    
    static func fetchEncryptedConfig(fileConfigName: String, bundle: Bundle) throws -> String {
        guard let configPath = bundle.path(forResource: fileConfigName, ofType: ClientConfigHandlerImpl.configExtension) else {
            throw ConfigFileError.invalidConfigPath
        }
        
        guard let configString = try? String(contentsOfFile: configPath) else {
            throw ConfigFileError.convertingConfigFailed
        }
        
        return configString
    }
    
}
