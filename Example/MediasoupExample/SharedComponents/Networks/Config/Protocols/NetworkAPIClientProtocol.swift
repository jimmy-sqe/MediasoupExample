//
//  NetworkAPIClientProtocol.swift
//  SqeIdFramework
//
//  Created by Marthin Satrya Pasaribu on 12/02/24.
//

import Foundation

protocol NetworkAPIClient {
    func call<T: Codable>(request: NetworkAPIData,
                           basePath: String,
                           keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy,
                           completionHandler: @escaping ((Result<T, NetworkError>) -> Void))
}
