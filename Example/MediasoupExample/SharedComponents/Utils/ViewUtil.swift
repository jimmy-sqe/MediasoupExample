//
//  ViewUtil.swift
//  sqekyc
//
//  Created by Jimmy Suhartono on 12/07/23.
//

import Foundation
import UIKit


public protocol ViewUtility {
    func getTopViewController() -> UIViewController?
    func createNavigationController() -> UINavigationController?
}

class ViewUtilityImpl: ViewUtility {
    
    func getTopViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        
        var topController = keyWindow?.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
    
    func createNavigationController() -> UINavigationController? {
        let topViewController = getTopViewController()
        let navigationController = UINavigationController()
        navigationController.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        topViewController?.present(navigationController, animated: false)

        return navigationController
    }
    
}
