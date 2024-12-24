//
//  AuthenticationBaseViewModel.swift
//  SqeId
//
//  Created by Fajriharish on 02/10/23.
//

import Foundation

protocol AuthenticationBaseViewModel {
    var dependencies: AuthenticationDependencies { get }
    
    func trackEvent(with eventName: String, properties: [String: Any])
}

extension AuthenticationBaseViewModel {
    func trackEvent(with eventName: String, properties: [String: Any]) {
        dependencies.analytic?.sendEvent(name: eventName, properties: properties)
    }
}
