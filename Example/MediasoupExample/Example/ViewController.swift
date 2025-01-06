
import Combine
import UIKit

final class ViewController: UIViewController {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    private var cancellables = Set<AnyCancellable>()
    
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
        manageRoom.joinMeetingRoom()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manageRoom.setup()
        
        manageRoom.username.sink { [weak self] name in
            DispatchQueue.main.async {
                self?.nameLabel.text = name
            }
        }.store(in: &cancellables)
        
        manageRoom.roomStatus.sink { [weak self] status in
            DispatchQueue.main.async {
                self?.statusLabel.text = status
            }
        }.store(in: &cancellables)
    }
    
}
