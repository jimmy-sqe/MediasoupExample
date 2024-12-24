//
//  DatadogLogs.swift
//  SqeIdFramework
//
//  Created by Jimmy Suhartono on 13/05/24.
//

import DatadogCore
import DatadogInternal
import DatadogLogs
import Foundation

class DatadogLogs: Analytic {
    
    static let instanceName = CoreRegistry.defaultInstanceName
    static var userId: String?
    static var userProperties: [String: Any]?
    
    private let logger: LoggerProtocol
    private let cfNumberTypes: [CFNumberType]
    
    init(env: SqeCommonEnvironment, clientToken: String, clientId: String) {
        Datadog.initialize(
            with: Datadog.Configuration(
                clientToken: clientToken,
                env: env.rawValue,
                service: "mobile-sdk"
            ),
            trackingConsent: .granted,
            instanceName: DatadogLogs.instanceName
        )
        
        Logs.enable(in: Datadog.sdkInstance(named: DatadogLogs.instanceName))
        
        Datadog.verbosityLevel = .debug
        
        self.logger = Logger.create(
            with: Logger.Configuration(
                name: "\(AppConfiguration.sdkName) - \(clientId)",
                networkInfoEnabled: true,
                remoteLogThreshold: .info
            ),
            in: Datadog.sdkInstance(named: DatadogLogs.instanceName)
        )
        
        self.cfNumberTypes = [.sInt8Type, .sInt16Type, .sInt32Type, .sInt64Type]
    }
    
    func setUserInfo(phoneNumber: String, properties: [String : Any]?) {
        DatadogLogs.userId = phoneNumber
        DatadogLogs.userProperties = properties
    }
    
    func sendEvent(name: String, properties: [String: Any]?) {
        var dict: Dictionary<String, Encodable> = Dictionary<String, Encodable>()
        properties?.forEach{ key, value in
            switch value{
            case let numberValue as NSNumber:
                dict[key] = handleNSNumber(numberValue)
            default:
                dict[key] = "\(value)"
            }
        }
        
        if let userId = DatadogLogs.userId {
            dict["userId"] = userId
        }
        
        DatadogLogs.userProperties?.forEach{ key, value in
            if let encodableValue = value as? Encodable {
                dict[key] = encodableValue
            }
        }
        
        self.logger.info(name, attributes: dict)
    }
    
    func handleNSNumber(_ numberValue: NSNumber) -> Encodable {
        if CFGetTypeID(numberValue) == CFBooleanGetTypeID() {
            return numberValue.boolValue
        } else if cfNumberTypes.contains(CFNumberGetType(numberValue)) {
            return numberValue.intValue
        } else {
            return numberValue.doubleValue
        }
    }
    
}
