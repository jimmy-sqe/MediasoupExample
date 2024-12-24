//
//  NetworkManagerProtocol.swift
//  SqeIdFramework
//
//  Created by Marthin Satrya Pasaribu on 12/02/24.
//

import Foundation

protocol NetworkManager {
    func startRequest(request: NetworkAPIData, basePath: String, completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void)
}
