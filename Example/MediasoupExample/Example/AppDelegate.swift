import UIKit
//import FlipperKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
	func application(
		_ application: UIApplication, didFinishLaunchingWithOptions
		launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            
        // Override point for customization after application launch.
//        let client = FlipperClient.shared()
//        let layoutDescriptorMapper = SKDescriptorMapper(defaults: ())
//        FlipperKitLayoutComponentKitSupport.setUpWith(layoutDescriptorMapper)
//        client?.add(FlipperKitLayoutPlugin(rootNode: application, with: layoutDescriptorMapper))
//        client?.add(FlipperKitNetworkPlugin(networkAdapter: SKIOSNetworkAdapter()))
//        client?.add(FlipperKitExamplePlugin.sharedInstance())
//        client?.add(FKUserDefaultsPlugin(suiteName: nil))
//        client?.start()
            
		return true
	}

	func application(
		_ application: UIApplication,
		configurationForConnecting connectingSceneSession: UISceneSession,
		options: UIScene.ConnectionOptions)
		-> UISceneConfiguration {

		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(
		_ application: UIApplication,
		didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
    
}
