import Foundation

extension Array {

    func toJSONString() -> String? {
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: self) else {
            return nil
        }
        
        return String(data: theJSONData, encoding: .utf8)
    }
    
    func toData() -> Data? {
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: self) else {
            return nil
        }
        
        return theJSONData
    }
    
}
