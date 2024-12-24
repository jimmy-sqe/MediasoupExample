//
//  AnalyticsUtil.swift
//  SqeIdFramework
//
//  Created by Samuel Maynard on 05/11/24.
//

import Foundation

class AnalyticsUtil {

    static func updatePropertiesWithError(properties: [String: Any], error: String) -> [String: Any] {
        let errorValues = [
            "error": error
        ]
        let propertiesWithError = properties.merging(errorValues) { (_, new) in new }
        return propertiesWithError

    }
}
