//
//  DeviceInfoGenerator.swift
//  SqeIdFramework
//
//  Created by Marthin Satrya Pasaribu on 15/12/23.
//

import Foundation
import UIKit

public protocol DeviceInfoGenerator {
    func queryItemsWithDeviceInfo(queryItems: [URLQueryItem]) -> [URLQueryItem]
    func deviceInfo() -> [String: Any]
    func generateEncryptedDeviceInfo() -> String?
}

public class DeviceInfoGeneratorImpl: DeviceInfoGenerator {
    
    public static let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    
    private let storage: Storage
    private let bundleIdentifier = AppConfiguration.bundleIdentifier
    private let libraryName = AppConfiguration.sdkName
    
    public init(storage: Storage? = nil) {
        self.storage = storage ?? LocalStorage()
    }
    
    public func queryItemsWithDeviceInfo(queryItems: [URLQueryItem]) -> [URLQueryItem] {
        var items = queryItems
        if let value = generateEncryptedDeviceInfo() {
            items.append(URLQueryItem(name: "auth_client", value: value))
        }
        return items
    }
    
    public func generateEncryptedDeviceInfo() -> String? {
        let deviceInfo = deviceInfo()
        let data = try? JSONSerialization.data(withJSONObject: deviceInfo, options: [])
        return data?.encodeBase64URLSafe()
    }
    
    public func deviceInfo() -> [String: Any] {
        var dict: [String: Any] = [
            "name": libraryName,
            "version": versionInfo(),
            "platform": AppConfiguration.platformName,
            "env": generateEnviroment()
        ]
        
        if let userInfo = generateUserInfo() {
            dict["user-info"] = userInfo
        }
        
        return dict
    }
    
    private func generateUserInfo() -> [String: Any]? {
        var userInfo: [String: Any] = [:]
        if let phoneNumber = getUserPhoneNumber() {
            userInfo["phone-number"] = phoneNumber
        }
        if let properties = getUserProperties() {
            userInfo.merge(properties) { _, new in new }
        }
        
        if userInfo.isEmpty {
            return nil
        } else {
            return userInfo
        }
    }
    
    private func getUserPhoneNumber() -> String? {
        return storage.get(forKey: LocalStorageKey.sqeUserPhoneNumber)
    }
    
    private func getUserProperties() -> [String: Any]? {
        return storage.get(forKey: LocalStorageKey.sqeUserProperties)
    }
    
    private func versionInfo() -> String {
        guard let version = Bundle.init(identifier: bundleIdentifier)?.infoDictionary?["CFBundleShortVersionString"] as? String else { return "unknown" }
        return version
    }
    
    private func generateEnviroment() -> [String: String] {
        let env = [
            "os": osInfo(),
            "model": modelInfo(),
            "unique-id": DeviceInfoGeneratorImpl.deviceId,
            "network-provider": networkProviderInfo()
        ]
        return env
    }
    
    private func osInfo() -> String {
        return "iOS \(ProcessInfo().operatingSystemVersion.majorVersion).\(ProcessInfo().operatingSystemVersion.minorVersion)"
    }
    
    private func modelInfo() -> String {
        return UIDevice.modelName
    }
        
    private func networkProviderInfo() -> String {
        let timeoutInSeconds: Double = 3
        let deadline = Date.timeIntervalSinceReferenceDate + timeoutInSeconds
        
        while (NetworkProviderUtil.shared.ispName == nil) {
            let isTimeoutReached = Date.timeIntervalSinceReferenceDate > deadline
            if isTimeoutReached {
                break
            }
        }
        
        return NetworkProviderUtil.shared.ispName ?? "unkonwn"
    }
}
