//
//  Promise.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 02/01/25.
//

import Foundation

class Promise<Value>: Future<Value> {
    override init() {
        super.init()
    }
    
    init(value: Value) {
        super.init()
        
        // If the value was already known at the time the promise
        // was constructed, we can report the value directly
        result = .success(value)
    }
    
    func resolve(with value: Value) {
        result = .success(value)
    }
    
    func reject(with error: Error) {
        result = .failure(error)
    }
}
