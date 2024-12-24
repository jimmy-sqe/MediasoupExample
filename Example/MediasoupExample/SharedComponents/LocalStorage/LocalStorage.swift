//
//  LocalStorage.swift
//  sqeid
//
//  Created by Jimmy Suhartono on 03/08/23.
//

import Foundation

public protocol Storage {
    func get(forKey key: String) -> [String: Any]?
    func get(forKey key: String) -> String?
    func get(forKey key: String) -> Int
    func get(forKey key: String) -> Bool
    func get(forKey key: String) -> Double

    func set(_ data: Any, forKey key: String)
    
    func remove(forKey key: String)
}

class LocalStorage: Storage {
    
    private let userDefaults = UserDefaults.standard
    
    func get(forKey key: String) -> String? {
        userDefaults.string(forKey: key)
    }
    
    func get(forKey key: String) -> [String: Any]? {
        userDefaults.dictionary(forKey: key)
    }
    
    func get(forKey key: String) -> Int {
        userDefaults.integer(forKey: key)
    }
    
    func get(forKey key: String) -> Double {
        userDefaults.double(forKey: key)
    }
    
    func get(forKey key: String) -> Bool {
        userDefaults.bool(forKey: key)
    }
    
    func set(_ value: Any, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }    
    
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}
