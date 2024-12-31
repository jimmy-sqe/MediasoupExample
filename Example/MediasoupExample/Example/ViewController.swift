import UIKit

final class ViewController: UIViewController {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    private let manageRoom = ManageRoom(env: .staging, wsToken: "e6776bf9-ca05-4b57-94db-5003949f81e5", loggerController: LoggerController(), storage: LocalStorage())
    
    @IBAction func createRoomButtonTapped(_ sender: Any) {
        func getFormattedDate() -> String {
            let currentDate = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/HH:mm"
            return dateFormatter.string(from: currentDate)
        }
        
        let name = "Jimmy - \(getFormattedDate())"
        nameLabel.text = name
        manageRoom.doAuthAndConnectWebSocket(name: name, phone: "085959011905")
    }
    
    @IBAction func joinRoomButtonTapped(_ sender: Any) {
//        manageRoom.joinMeetingRoom()
//        manageRoom.getRTPCapabilities()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manageRoom.setup()
        
        manageRoom.onRoomStatusUpdated = { [weak self] status in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.statusLabel.text = status
            }
        }
    }
    
}
