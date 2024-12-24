//
//  Analytic.swift
//  sqeid
//
//  Created by Jimmy Suhartono on 05/07/23.
//

import Foundation

public protocol Analytic {
    
    func setUserInfo(phoneNumber: String, properties: [String: Any]?)
    func sendEvent(name: String, properties: [String: Any]?)
    
}
