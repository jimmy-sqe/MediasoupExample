//
//  NetworkProviderUtil.swift
//  sqeid
//
//  Created by Jimmy Suhartono on 21/07/23.
//

import Foundation

class NetworkProviderUtil {
    
    var ispName: String?
    
    static let shared = NetworkProviderUtil()
    
    private let UNKNOWN_ISP = "unknown"
    
    init() {
        Task {
            let ispName = await loadIspData()
            self.ispName = ispName
        }
    }
    
    private func loadIspData() async -> String {
        guard let url = URL(string: "https://ipinfo.io/org") else { return UNKNOWN_ISP }
            
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let ispName = String(data: data, encoding: .utf8) {
                return ispName
            } else {
                return UNKNOWN_ISP
            }
        } catch {
            return UNKNOWN_ISP
        }
    }
    
}
