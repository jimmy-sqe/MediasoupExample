//
//  ClientConfigRequestParam.swift
//  SqeIdFramework
//
//  Created by Marthin Satrya Pasaribu on 05/02/24.
//

import Foundation

struct ClientConfigRequestParam: DictionaryConvertible {
    let clientId: String
    let platform: String
    let env: String
}

