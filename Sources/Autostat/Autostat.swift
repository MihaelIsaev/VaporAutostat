import Vapor
import Foundation

public class Autostat: Service {
    let authURL = "https://auth.autostat.ru"
    let dataURL = "https://price.autostat.ru"
    
    public let user, password: String
    
    // MARK: Initialization
    
    public init(user: String, password: String) {
        self.user = user
        self.password = password
    }
    
    struct TokenRequest: Content {
        var query: String
    }
    
    struct TokenResponse: Content {
        struct Data: Codable {
            struct GenerateToken: Codable {
                let value: String
            }
            let generateToken: GenerateToken
        }
        let data: Data
    }
    
    func authorize(on container: Container) throws -> Future<String> {
        let requestPaylaod = TokenRequest(query: "mutation{generateToken(User:{username:\"\(user)\", password:\"\(password)\"}){value}}")
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/json")
        return try executeRequest(on: container, url: authURL, method: .POST, headers: headers) {
            try $0.content.encode(requestPaylaod, as: .json)
        }.flatMap {
            try $0.content.decode(TokenResponse.self).map { $0.data.generateToken.value }
        }
    }
    
    // MARK: Request
    
    typealias BeforeSend = (Request) throws -> Void
    
    func executeRequest(on container: Container, url: String, method: HTTPMethod, headers: HTTPHeaders, beforeSend: BeforeSend) throws -> Future<Response> {
        debugPrint("AUTOSTAT: sending request to \(url)")
        let client = try container.make(Client.self)
        switch method {
        case .GET: return client.get(url, headers: headers, beforeSend: beforeSend)
        case .POST: return client.post(url, headers: headers, beforeSend: beforeSend)
        case .PUT: return client.put(url, headers: headers, beforeSend: beforeSend)
        case .PATCH: return client.patch(url, headers: headers, beforeSend: beforeSend)
        case .DELETE: return client.delete(url, headers: headers, beforeSend: beforeSend)
        default: throw Abort(.internalServerError, reason: "Unsupportable HTTP method")
        }
    }
}
