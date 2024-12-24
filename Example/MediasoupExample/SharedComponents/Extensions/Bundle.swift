//
//  Bundle.swift
//  sqeid
//
//  Created by Fajriharish on 18/08/23.
//

import Foundation

extension Bundle {
    static func media() -> Bundle? {
        let url = Bundle.main.url(forResource: "Media", withExtension: "bundle")!
        return Bundle(url: url)
    }
    
    var displayName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? object(forInfoDictionaryKey: "CFBundleName") as? String
    }
    
    /// Return the main bundle when in the app or an app extension.
    static var app: Bundle {
        var components = main.bundleURL.path.split(separator: "/")
        var bundle: Bundle?

        if let index = components.lastIndex(where: { $0.hasSuffix(".app") }) {
            components.removeLast((components.count - 1) - index)
            bundle = Bundle(path: components.joined(separator: "/"))
        }

        return bundle ?? main
    }
}
