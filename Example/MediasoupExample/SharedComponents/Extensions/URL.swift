//
//  URL.swift
//  SqeOcrFramework
//
//  Created by Jimmy Suhartono on 16/04/24.
//

import Foundation

extension URL {

    static func httpsURL(from domain: String) -> URL {
        let prefix = !domain.hasPrefix("https") ? "https://" : ""
        let suffix = !domain.hasSuffix("/") ? "/" : ""
        let urlString = "\(prefix)\(domain)\(suffix)"
        return URL(string: urlString)!
    }
    
    static func wssURL(from domain: String) -> URL {
        let prefix = !domain.hasPrefix("wss") ? "wss://" : ""
        let suffix = !domain.hasSuffix("/") ? "/" : ""
        let urlString = "\(prefix)\(domain)\(suffix)"
        return URL(string: urlString)!
    }
    
    func addParameters(_ parameters: NetworkRequestParams) -> URL? {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let urlParams = parameters.urlParameters, !urlParams.isEmpty else { return nil }
        
        urlComponents.queryItems = [URLQueryItem]()
        
        for (key, value) in urlParams{
            if let valueString = value as? String {
                let queryItem = URLQueryItem(name: key, value: valueString)
                urlComponents.queryItems?.append(queryItem)
            }
        }
        
        urlComponents.percentEncodedQuery = urlComponents.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return urlComponents.url
    }
    
}
