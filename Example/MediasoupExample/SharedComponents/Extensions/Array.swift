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

extension Array where Element == UInt8 {
    
    func derEncode(as dataType: UInt8) -> [UInt8] {
        var encodedBytes: [UInt8] = [dataType]
        var numberOfBytes = count
        if numberOfBytes < 128 {
            encodedBytes.append(UInt8(numberOfBytes))
        } else {
            let lengthData = Data(bytes: &numberOfBytes, count: MemoryLayout.size(ofValue: numberOfBytes))
            let lengthBytes = [UInt8](lengthData).filter({ $0 != 0 }).reversed()
            encodedBytes.append(UInt8(truncatingIfNeeded: lengthBytes.count) | 0b10000000)
            encodedBytes.append(contentsOf: lengthBytes)
        }
        encodedBytes.append(contentsOf: self)
        return encodedBytes
    }
    
}
