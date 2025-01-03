//
//  LoggerController.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 23/12/24.
//

import Foundation

protocol LoggerControllerProtocol {
    func sendLog(name: String, properties: [String: Any]?)
}

class LoggerController: LoggerControllerProtocol {
    
    func sendLog(name: String, properties: [String : Any]?) {
        var logMessage = "DEBUG:\(name)"
        if let properties {
            logMessage += " with properties: \(properties as AnyObject)"
        }
        NSLog(logMessage)
    }
    
}
