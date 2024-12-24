import UIKit
import Network
import Mediasoup
import AVFoundation
import WebRTC
import NWWebSocket

final class ViewController: UIViewController {
	@IBOutlet var label: UILabel!
    
    private var socket: NWWebSocket?

	private let peerConnectionFactory = RTCPeerConnectionFactory()
	private var mediaStream: RTCMediaStream?
	private var audioTrack: RTCAudioTrack?

	private var device: Device?
	private var sendTransport: SendTransport?
	private var producer: Producer?
    
    private let makeCall = MakeCall(env: .staging, wsToken: "e6776bf9-ca05-4b57-94db-5003949f81e5", loggerController: LoggerController())
    
    deinit {
//        socket?.disconnect()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        makeCall.setup()
        makeCall.doAuthAndConnectWebSocket(name: "Jimmy Suhartono", phone: "085959011905")
    }
    
        
//        API: POST - https://sqecc-be.stg.squantumengine.com/v1/widget/website-token/e6776bf9-ca05-4b57-94db-5003949f81e5/conversation/AUDIO_VIDEO
        // Authorization -> jwt accessToken
//    }
    
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
    
    private func sendSocketMessage(message: String) {
        socket?.send(string: message)
    }
    
    func convertDictionaryToJSON(_ dictionary: [String: Any]) -> String? {
       guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted) else {
          print("Something is wrong while converting dictionary to JSON data.")
          return nil
       }

       guard let jsonString = String(data: jsonData, encoding: .utf8) else {
          print("Something is wrong while converting JSON data to JSON string.")
          return nil
       }

       return jsonString
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

extension ViewController: WebSocketConnectionDelegate {
    func webSocketDidConnect(connection: WebSocketConnection) {
        print("DEBUG:WebSocket On Connected")
    }
    
    func webSocketDidDisconnect(connection: WebSocketConnection, closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        print("DEBUG:WebSocket On Disconnected")
    }
    
    func webSocketViabilityDidChange(connection: WebSocketConnection, isViable: Bool) {
        print("DEBUG:WebSocket On Viability Change")
    }
    
    func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketConnection, NWError>) {
        print("DEBUG:WebSocket On Connection migrates to a better network path")
    }
    
    func webSocketDidReceiveError(connection: WebSocketConnection, error: NWError) {
        print("DEBUG:WebSocket On Error with error \(error.debugDescription)")
    }
    
    func webSocketDidReceivePong(connection: WebSocketConnection) {
        print("DEBUG:WebSocket On Receive Pong")
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        print("DEBUG:WebSocket On Receive Message string: \(string)")
        
        let dictionary = convertToDictionary(text: string)
        
        if dictionary?["event"] as? String == "WEBSOCKET_CONNECTED" {
            sendSocketJoinMeetingRoom()
        }
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        print("DEBUG:WebSocket On Receive Message data: \(data)")
    }
    
    private func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
}
