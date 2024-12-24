//
//  SDKConfigs.swift
//  SqeIdFramework
//
//  Created by Jimmy Suhartono on 12/07/24.
//

import Foundation

enum SDKConfigs: String {
    case development
    case staging
    case production
    
    var encrypted: String {
        switch self {
        case .development, .staging:
            return "jgJ+9zUUXfnOxJStNwXwE9UL7irXAuDsIhZP6K5MYl2GGbnI7tOZjTkaYzaRJbMgrV/dsEK850x3+dJ3gN0NIw1gzlyp6Ei/Ahzp"
        case .production:
            return "jgJ+9zUUXfnOxJStNwXwE9UL7irXAuDtIksb7K4ZNFvWH7qZ79DNgW5NY2zHJLIm+wyJshe84Ex3+dLenVLaItbmzudpXZvcKCkr"
        }
    }
    
    var primaryId: String {
        return "e701d40a-9a10-403d-823a-baa706bfd8bb"
    }
    
    var secondaryId: String {
        return "b2bdd97f-df39-41ef-8e98-24f2dd491af8"
    }
    
    var encryptedPrimaryId: String {
        return "jtnuVzeKhN94B8dXPjgt4Lhxiv9e+rY="
    }
    
    var encryptedSecondaryId: String {
        return "isz3SjLE2jCjmKbN0+ytC1B0gQ2rz9tmDQ=="
    }

}
