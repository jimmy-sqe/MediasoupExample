//
//  DictionaryConvertible.swift
//  SqeIdFramework
//
//  Created by Marthin Satrya Pasaribu on 22/02/24.
//

import Foundation

protocol DictionaryConvertible {
    func asDictionary() -> [String: Any]
}

extension DictionaryConvertible {
    func asDictionary() -> [String: Any] {
        let mirrorObject = Mirror(reflecting: self)
        var result = [String: String]()
        
        for (label, value) in mirrorObject.children {
            guard let label = label?.snakeCased(), let value = value as? String else {
                continue
            }
            result[label] = value
        }
        
        return result
    }
}
