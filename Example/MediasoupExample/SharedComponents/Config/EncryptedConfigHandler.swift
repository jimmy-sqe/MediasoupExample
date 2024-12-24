//
//  EncryptedConfigHandler.swift
//  SqeIdFramework
//
//  Created by Marthin Satrya Pasaribu on 15/02/24.
//

import Foundation
import CommonCrypto
import CryptoKit

public protocol EncryptedConfigHandler {
    func decrypt(encryptedConfig: String) throws -> String
}

class EncryptedConfigHandlerImpl: EncryptedConfigHandler {
    private let clientId: String
    private let bundleId: String
    
    init(clientId: String, bundleId: String) throws {
        self.clientId = clientId
        self.bundleId = bundleId
    }
    
    func decrypt(encryptedConfig: String) throws -> String {
        return try getDataConfig(encryptedConfig: encryptedConfig)
    }
    
    private func getDataConfig(encryptedConfig: String) throws -> String {
        guard let keyAndIv = getKeyAndIv() else {
            throw ConfigFileError.invalidEncryptedKeyAndIv
        }
        
        guard let decrypt = try decryptWithGCM(ciphertext: encryptedConfig, secret: keyAndIv.0, nonce: keyAndIv.1) else {
            throw ConfigFileError.invalidJsonConfig
        }
        
        let resultString = String(decoding: decrypt, as: UTF8.self)
        return resultString
    }
    
    private func getKeyAndIv() -> (String, String)? {
        guard let keyData = "\(clientId)$\(bundleId)$\(String(clientId.reversed()))".data(using: .utf8) else {
            return nil
        }
        
        let digest = SHA256.hash(data: keyData)
        
        let hashStringKey = digest
            .compactMap { String(format: "%02x", $0) }
            .joined()
        let secretKey = String(hashStringKey.prefix(32))
        
        let startIndex = hashStringKey.index(hashStringKey.startIndex, offsetBy: 32)
        let endIndex = hashStringKey.index(hashStringKey.startIndex, offsetBy: 64)
        let iv = String(hashStringKey[startIndex..<endIndex])
        
        return (secretKey, iv)
    }

    func decryptWithGCM(ciphertext: String, secret: String, nonce: String) throws -> Data? {
        do {
            let nonceEnc = nonce.encodeBase64()
            let nonce = try AES.GCM.Nonce(data: Data(base64Encoded: nonceEnc)!)
            let sec = secret.encodeBase64()
            let symKey = SymmetricKey(data: Data(base64Encoded: sec)!)
            
            guard let ciphertextData = Data(base64Encoded: ciphertext, options: .ignoreUnknownCharacters) else {
                return nil
            }
            
            let tagData = ciphertextData.suffix(16)
            
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertextData.prefix(ciphertextData.count - 16), tag: tagData)
            let decryptedData = try AES.GCM.open(sealedBox, using: symKey)
            
            return decryptedData
        } catch {
            print("Decryption error: \(error)")
            throw ConfigFileError.invalidForDecrypted
        }
    }
}
