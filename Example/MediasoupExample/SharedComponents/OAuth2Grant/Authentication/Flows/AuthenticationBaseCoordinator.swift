//
//  AuthenticationDependencies.swift
//  SqeId
//
//  Created by Fajriharish on 02/10/23.
//

import Foundation

protocol Dependencies {}

struct AuthenticationDependencies: Dependencies {
    let clientId: String
    let mobileClientId: String
    let apiBaseUrl: URL
    let analytic: Analytic?
}
