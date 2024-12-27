//
//  DynamicValue.swift
//  MediasoupExample
//
//  Created by Jimmy Suhartono on 27/12/24.
//

// Enum to represent dynamic types (String, Int, Bool, Array, or Nested Dictionary)
enum DynamicValue: Codable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case array([DynamicValue])  // Supports an array of dynamic values
    case dictionary(DynamicDictionary)  // Supports nested dictionaries
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let arrayValue = try? container.decode([DynamicValue].self) {
            self = .array(arrayValue)
        } else if let dictionaryValue = try? container.decode(DynamicDictionary.self) {
            self = .dictionary(dictionaryValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        }
    }
    
    // Convert the value to a string
    var string: String {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return "\(value)"
        case .bool(let value):
            return "\(value)"
        case .array(let values):
            let arrayStrings = values.map { $0.string }
            return "[" + arrayStrings.joined(separator: ", ") + "]"
        case .dictionary(let dictionary):
            let dictStrings = dictionary.values.map { "\($0)" }
            return "{" + dictStrings.joined(separator: ", ") + "}"
        }
    }
}

// A model to decode dynamic key-value pairs (supports nested dictionaries)
struct DynamicDictionary: Codable {
    var values: [String: DynamicValue]
    
    enum CodingKeys: String, CodingKey {
        case values = "values"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var values = [String: DynamicValue]()
        
        // Decoding all dynamic key-value pairs from the container
        let keys = container.allKeys
        for key in keys {
            let value = try container.decode(DynamicValue.self, forKey: key)
            values[key.stringValue] = value
        }
        
        self.values = values
    }
}
