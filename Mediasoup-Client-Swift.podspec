Pod::Spec.new do |spec|
	spec.summary = "Swift client for Mediasoup 3"
	spec.description = "Swift wrapper for libmediasoupclient"
	spec.homepage = "https://github.com/VLprojects/mediasoup-client-swift"
	spec.license = "MIT"
	spec.author = {
		"Alexander Gorbunov" => "gorbunov.a@vlprojects.pro"
	}
	
	spec.name = "Mediasoup-Client-Swift"
	spec.version = "0.8.1"
	spec.platform = :ios, "13.0"
	spec.module_name = "Mediasoup"
	spec.module_map = "Mediasoup/Mediasoup.modulemap"

	spec.source = {
		:git => "https://github.com/VLprojects/mediasoup-client-swift.git",
		:tag => spec.version.to_s
	}
  
  spec.dependency 'NWWebSocket', '0.5.4'
  spec.dependency 'DatadogCore', '2.21.0'
  spec.dependency 'DatadogLogs', '2.21.0'
  spec.dependency 'Sentry', '8.36.0'

	spec.frameworks =
		"AVFoundation",
		"AudioToolbox",
		"CoreAudio",
		"CoreMedia",
		"CoreVideo"

	spec.vendored_frameworks =
		"bin/Mediasoup.xcframework",
		"bin/WebRTC.xcframework"
end
