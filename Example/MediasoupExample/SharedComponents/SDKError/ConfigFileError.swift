//
//  Untitled.swift
//  SqeKycSDK
//
//  Created by Jimmy Suhartono on 19/09/24.
//

public enum ConfigFileError: Error {
    case invalidConfigPath
    case convertingConfigFailed
    case invalidEncryptedKeyAndIv
    case invalidForDecrypted
    case invalidJsonConfig
    case invalidDecodeConfig
}
