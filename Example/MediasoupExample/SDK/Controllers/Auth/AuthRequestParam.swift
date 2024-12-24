//
//  AuthRequestParam.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 23/12/24.
//

struct AuthRequestParam: DictionaryConvertible {
    let name: String
    let phone: String
    
    init(name: String, phone: String) {
        self.name = name
        self.phone = phone
    }
    
    enum CodingKeys: String {
        case name
        case phone
        
        var keyName: String {
            self.rawValue.snakeCased()
        }
    }
}
