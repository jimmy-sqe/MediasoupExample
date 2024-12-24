import UIKit
import Network
import Mediasoup
import AVFoundation
import WebRTC

final class ViewController: UIViewController {
	private let peerConnectionFactory = RTCPeerConnectionFactory()
	private var mediaStream: RTCMediaStream?
	private var audioTrack: RTCAudioTrack?

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    private var device: Device?
	private var sendTransport: SendTransport?
	private var producer: Producer?
    
    private let makeCall = MakeCall(env: .staging, wsToken: "e6776bf9-ca05-4b57-94db-5003949f81e5", loggerController: LoggerController())
    
    deinit {
//        socket?.disconnect()
    }
    
    @IBAction func makeACallButtonTapped(_ sender: Any) {
        let currentDate = Date()

        // Create a DateFormatter instance
        let dateFormatter = DateFormatter()

        // Set the desired date and time format
        dateFormatter.dateFormat = "dd/HH:mm"

        // Format the current date
        let formattedDate = dateFormatter.string(from: currentDate)

        let name = "Jimmy - \(formattedDate)"
        nameLabel.text = name
        makeCall.doAuthAndConnectWebSocket(name: name, phone: "085959011905")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        makeCall.setup()
        
        makeCall.onStatusUpdated = { [weak self] status in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.statusLabel.text = status
            }
        }
    }
        
    private func sendSocketJoinMeetingRoom() {

//        let uuid = UUID().uuidString
//        
//        let payload: [String: String] = [
//            "event": "JOIN_MEETING_ROOM",
//            "meetingRoomId": Constants.MeetingRoomId,
//            "originalRequestId": uuid
//        ]
//        
//        let payloadJSON = convertDictionaryToJSON(payload)!
//        print("DEBUG:WebSocket Send Signal -> \(payloadJSON)")
//        
//        sendSocketMessage(message: payloadJSON)
    }
    
//	override func viewDidLoad() {
//		super.viewDidLoad()
//
//		guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
//			self.label.text = "accept all permission requests and restart the app"
//			AVCaptureDevice.requestAccess(for: .audio) { _ in
//			}
//			return
//		}
//
//		mediaStream = peerConnectionFactory.mediaStream(withStreamId: TestData.MediaStream.mediaStreamId)
//		let audioTrack = peerConnectionFactory.audioTrack(withTrackId: TestData.MediaStream.audioTrackId)
//		mediaStream?.addAudioTrack(audioTrack)
//		self.audioTrack = audioTrack
//
//
//		let device = Device()
//		do {
//			print("isLoaded: \(device.isLoaded())")
//
//            //TODO: Get from BE via WebSocket -
//			try device.load(with: TestData.Device.rtpCapabilities)
//			print("isLoaded: \(device.isLoaded())")
//
//			let canProduceVideo = try device.canProduce(.video)
//			print("can produce video: \(canProduceVideo)")
//
//			let canProduceAudio = try device.canProduce(.audio)
//			print("can produce audio: \(canProduceAudio)")
//
//			let sctpCapabilities = try device.sctpCapabilities()
//			print("SCTP capabilities: \(sctpCapabilities)")
//
//			let rtpCapabilities = try device.rtpCapabilities()
//			print("RTP capabilities: \(rtpCapabilities)")
//
//			let sendTransport = try device.createSendTransport(
//				id: TestData.SendTransport.transportId,
//				iceParameters: TestData.SendTransport.iceParameters,
//				iceCandidates: TestData.SendTransport.iceCandidates,
//				dtlsParameters: TestData.SendTransport.dtlsParameters,
//				sctpParameters: nil,
//				appData: nil)
//			sendTransport.delegate = self
//			self.sendTransport = sendTransport
//            
//			print("transport id: \(sendTransport.id)")
//			print("transport is closed: \(sendTransport.closed)")
//
//			DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//				if let producer = try? sendTransport.createProducer(for: audioTrack, encodings: nil, codecOptions: nil, codec: nil, appData: nil) {
//					self.producer = producer
//					producer.delegate = self
//					print("producer created")
//					producer.resume()
//				}
//			}
//
////			try sendTransport.updateICEServers("[]")
////			print("ICE servers updated")
////
////			try sendTransport.restartICE(with: "{}")
////			print("ICE restarted")
//
//			DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
//				sendTransport.close()
//				print("transport is closed: \(sendTransport.closed)")
//			}
//
//			label.text = "OK"
//		} catch let error as MediasoupError {
//			switch error {
//				case let .unsupported(message):
//					label.text = "unsupported: \(message)"
//				case let .invalidState(message):
//					label.text = "invalid state: \(message)"
//				case let .invalidParameters(message):
//					label.text = "invalid parameters: \(message)"
//				case let .mediasoup(underlyingError):
//					label.text = "mediasoup: \(underlyingError)"
//				case .unknown(let underlyingError):
//					label.text = "unknown: \(underlyingError)"
//				@unknown default:
//					label.text = "unknown"
//			}
//		} catch {
//			label.text = error.localizedDescription
//		}
//
//		self.device = device
//		DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
//			print("Deallocating SendTransport...")
//			self.sendTransport = nil
//			self.device = nil
//			print("device deallocated")
//		}
//	}
    
}


// Kita hrus listen MediaServerProducer dari WebSocket


//extension ViewController: SendTransportDelegate {
//	func onProduce(transport: Transport, kind: MediaKind, rtpParameters: String, appData: String,
//		callback: @escaping (String?) -> Void) {
//
//		print("on produce \(kind)")
//        //TODO:
//        //rtpParameters: diubah sedikit ditambah manual baris 150
//        //newRtpParam: masukin lagi
//        //balikin lagi ke BE pakai WebSocket
//        //BE balikin originalRequestID
//        //Save producerId dari res.data.producer.id
//        //Panggil callback
//        
//        
//	}
//
//	func onProduceData(transport: Transport, sctpParameters: String, label: String,
//		protocol dataProtocol: String, appData: String, callback: @escaping (String?) -> Void) {
//
//		print("on produce data \(label)")
//	}
//
//	func onConnect(transport: Transport, dtlsParameters: String) {
//        //TODO: Harus panggil BE pakai WebSocket
//        // Dapat originalRequestId dari BE trus kasih id nya ke SDK
//		print("on connect")
//	}
//
//	func onConnectionStateChange(transport: Transport, connectionState: TransportConnectionState) {
//		print("on connection state change: \(connectionState)")
//	}
//}
//
//
//extension ViewController: ProducerDelegate {
//	func onTransportClose(in producer: Producer) {
//		print("on transport close in \(producer)")
//	}
//}
