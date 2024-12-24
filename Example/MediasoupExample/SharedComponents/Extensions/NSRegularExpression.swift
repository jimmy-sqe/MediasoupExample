//
//  NSRegularExpression.swift
//  SqeIdFramework
//
//  Created by Jimmy Suhartono on 19/02/24.
//

import Foundation

extension NSRegularExpression {
    func matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}
