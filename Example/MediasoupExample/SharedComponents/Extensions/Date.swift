//
//  Date.swift
//  sqeid
//
//  Created by Jimmy Suhartono on 22/06/23.
//

import Foundation

extension Date {
    func roundDownSecondsToZero() -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"

        let dateWithZeroSeconds = formatter.date(from: formatter.string(from: self))
        return dateWithZeroSeconds ?? Date()
    }
}
