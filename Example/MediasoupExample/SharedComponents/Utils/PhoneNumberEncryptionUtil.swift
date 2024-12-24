//
//  PhoneNumberEncryptionUtil.swift
//  SqeIdSDK
//
//  Created by Jimmy Suhartono on 25/10/24.
//

class PhoneNumberEncryptionUtil {
    
    private static var phoneNumberData: [String: String] = [:]
    
    static func encrypt(_ phoneNumber: String) -> String? {
        if let storedEncryptedPhoneNumber = phoneNumberData[phoneNumber] {
            return storedEncryptedPhoneNumber
        }
        
        guard let encryptedPhoneNumber = phoneNumber.encodeSHA256() else { return nil }
        phoneNumberData[phoneNumber] = encryptedPhoneNumber
        return encryptedPhoneNumber
    }
    
}
