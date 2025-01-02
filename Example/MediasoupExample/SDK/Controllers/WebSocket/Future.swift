//
//  Future.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 02/01/25.
//

import Foundation

class Future<Value> {
    var result: Result<Value, Error>? {
        // Observe whenever a result is assigned, and report it
        didSet {
            result.map(report)
        }
    }
    
    private lazy var callbacks = [(Result<Value, Error>) -> Void]()
    
    func observe(with callback: @escaping (Result<Value, Error>) -> Void) {
        callbacks.append(callback)
        
        // If a result has already been set, call the callback directly
        result.map(callback)
    }
    
    private func report(result: Result<Value, Error>) {
        for callback in callbacks {
            callback(result)
        }
    }
}

extension Future {
    func chained<NextValue>(with closure: @escaping (Value) throws -> Future<NextValue>) -> Future<NextValue> {
        // Start by constructing a "wrapper" promise that will be
        // returned from this method
        let promise = Promise<NextValue>()
        // Observe the current future
        observe { result in
            switch result {
            case .success(let value):
                do {
                    // Attempt to construct a new future given
                    // the value from the first one
                    let future = try closure(value)
                    // Observe the "nested" future, and once it
                    // completes, resolve/reject the "wrapper" future
                    future.observe { result in
                        switch result {
                        case .success(let value):
                            promise.resolve(with: value)
                        case .failure(let error):
                            promise.reject(with: error)
                        }
                    }
                } catch {
                    promise.reject(with: error)
                }
            case .failure(let error):
                promise.reject(with: error)
            }
        }
        return promise
    }
}
