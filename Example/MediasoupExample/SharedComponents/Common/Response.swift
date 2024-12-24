import Foundation

struct Response<E: APIError> {
    let data: Data?
    let response: HTTPURLResponse?
    let error: Error?

    func result() throws -> Any? {
        guard error == nil else { throw E(cause: error!, statusCode: response?.statusCode ?? 0) }
        guard let response = self.response else { throw E(description: nil, statusCode: response?.statusCode ?? 0) }
        guard (200...300).contains(response.statusCode) else {
            if let json = json(data) as? [String: Any] {
                throw E(info: json, statusCode: response.statusCode)
            }
            throw E(from: self)
        }
        guard let data = self.data, !data.isEmpty else {
            if response.statusCode == 204 {
                return nil
            }
            // Not using the custom initializer because data could be empty
            throw E(description: nil, statusCode: response.statusCode)
        }
        if let json = json(data) {
            return json
        }
        // This piece of code is dedicated to our friends the backend devs :)
        if response.url?.lastPathComponent == "change_password" {
            return nil
        }
        throw E(from: self)
    }
    
    func json(_ data: Data?) -> Any? {
        guard let data = data else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: [])
    }

}

