import UIKit

extension UIApplication {

    static func shared() -> UIApplication? {
        return UIApplication.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue() as? UIApplication
    }

    static var topMostViewController: UIViewController? {
        return UIApplication.shared.windows.last { $0.isKeyWindow }?.rootViewController?.visibleViewController
    }
}
