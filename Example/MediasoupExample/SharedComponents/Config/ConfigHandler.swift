//
//  ConfigHandler.swift
//  SqeIdFramework
//
//  Created by Marthin Satrya Pasaribu on 05/02/24.
//

import Foundation

public protocol ConfigHandler {
    var crashReporter: CrashReporter? { get set }
    var sdkConfig: SDKConfig { get }

    func fetchClientConfig() throws -> ClientConfig
}

class ConfigHandlerImpl: ConfigHandler {
    var crashReporter: CrashReporter?
    var sdkConfig: SDKConfig

    private var service: SDKConfigurationService?
    private var serverTimeService: ServerTimeService?
    private let storage: Storage
    private let clientConfigHandler: ClientConfigHandler
    private var clientConfig: ClientConfig
    private let encryptedConfigKey: String
    private let lastUpdateTimeConfigKey: String
    private let clientId: String
    private let fallbackConfigExpiryTime: Double = 3600
    
    init(clientId: String,
         service: SDKConfigurationService? = nil,
         serverTimeService: ServerTimeService? = nil,
         storage: Storage? = nil,
         clientConfigHandler: ClientConfigHandler? = nil,
         sdkConfigHandler: SDKConfigHandler? = nil,
         encryptedConfigKey: String = SDKConfigKey.sqeEncryptedConfig,
         lastUpdateTimeConfigKey: String = SDKConfigKey.sqeLastUpdateEncryptedConfig) throws {
        self.clientId = clientId
        self.storage = storage ?? LocalStorage()
        self.encryptedConfigKey = encryptedConfigKey
        self.lastUpdateTimeConfigKey = lastUpdateTimeConfigKey
        self.clientConfigHandler = try! (clientConfigHandler ?? ClientConfigHandlerImpl(clientId: clientId))
        self.clientConfig = try! self.clientConfigHandler.loadFromFile()
        
        let sdkConfigHandler = try! (sdkConfigHandler ?? SDKConfigHandlerImpl(env: self.clientConfig.environment))
        self.sdkConfig = sdkConfigHandler.sdkConfig
        
        self.service = service
        self.serverTimeService = serverTimeService
    }
    
    func fetchClientConfig() -> ClientConfig {
        defer {
            fetchClientConfigFromAPI()
        }
        return fetchClientConfigFromStorage()
    }
    
    private func fetchClientConfigFromStorage() -> ClientConfig {
        let encryptedConfigFromStorage: String? = storage.get(forKey: encryptedConfigKey)
        if let encryptedConfig = encryptedConfigFromStorage,
           let clientConfigModelFromStorage = try? clientConfigHandler.decrypt(encryptedConfig: encryptedConfig) {
            clientConfig = clientConfigModelFromStorage
        }
        return clientConfig
    }
    
    private func fetchClientConfigFromAPI() {
        let environment = SqeCommonEnvironment(rawValue: clientConfig.environment) ?? .production
        let apiService = service ?? SDKConfigurationServiceImpl(baseUrl: environment.apiBaseUrl.absoluteString, apiClient: nil)
        let apiServerTimeService = serverTimeService ?? ServerTimeServiceImpl(baseUrl: environment.apiBaseUrl.absoluteString)
        service = apiService
        serverTimeService = apiServerTimeService
        fetchTimeServerAndUpdateConfigFile(environment: environment)
    }
    
    private func fetchTimeServerAndUpdateConfigFile(environment: SqeCommonEnvironment) {
        serverTimeService?.getTime(timeoutInMilliseconds: Constants.DefaultNetworkTimeoutInMilliseconds) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let time):
                let lastUpdateDateTime: Double = self.storage.get(forKey: self.lastUpdateTimeConfigKey)
                let dateTimeNow = time.serverTime.timeIntervalSince1970
                
                var expiryTime: Double = self.fallbackConfigExpiryTime
                if let configExpiry = self.clientConfig.configExpiryTime {
                    expiryTime = configExpiry
                }
                
                if (dateTimeNow - lastUpdateDateTime) > expiryTime {
                    self.fetchConfigFromAPI(timeNow: time.serverTime, environment: environment)
                }
                
                break
            case .failure(let error):
                self.crashReporter?.sendErrorEvent(error: ErrorEvent.FailedFetchServerTimeForConfigFromAPI, detail: error.debugDescription, info: error.info)
                break
            }
        }
    }
    
    private func fetchConfigFromAPI(timeNow: Date, environment: SqeCommonEnvironment) {
        let requestParams = ClientConfigRequestParam(clientId: clientId, platform: AppConfiguration.platformName, env: environment.rawValue)
        
        let secret = PayloadUtil.createSecretKey(clientId: clientId, mobileClientId: clientConfig.mobileClientId, currentTime: timeNow)
        
        let signature = PayloadUtil.createTandaTangan(payload: requestParams.asDictionary(), rahasia: secret)
        
        service?.getSdkConfiguration(requestParam: requestParams, signature: signature) { result in
            switch result {
            case .success(let response):
                self.validateCipherAndSaveToLocalStorage(cipher: response.cipher, timeNow: timeNow)
            case .failure(let error):
                self.crashReporter?.sendErrorEvent(error: ErrorEvent.FailedFetchConfigFromAPI, detail: error.debugDescription, info: error.info)
                break
            }
        }
    }
    
    private func saveConfigurationInLocalStorage(encryptedConfig: String) {
        storage.set(encryptedConfig, forKey: encryptedConfigKey)
    }
    
    private func saveLastUpdateInLocalStorage(lastUpdateTime: Double) {
        storage.set(lastUpdateTime, forKey: lastUpdateTimeConfigKey)
    }
    
    private func validateCipherAndSaveToLocalStorage(cipher: String, timeNow: Date) {
        do {
            _ = try clientConfigHandler.decrypt(encryptedConfig: cipher)
            saveLastUpdateInLocalStorage(lastUpdateTime: timeNow.timeIntervalSince1970)
            saveConfigurationInLocalStorage(encryptedConfig: cipher)
        } catch (let error) {
            self.crashReporter?.sendErrorEvent(error: ErrorEvent.FailedDecodeConfigFromAPI, detail: error.localizedDescription, info: nil)
        }
    }
}
