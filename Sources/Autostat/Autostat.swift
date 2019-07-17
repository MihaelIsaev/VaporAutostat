import Vapor
import Foundation

public class Autostat: Service {
    public static var authURL = "https://auth.autostat.ru"
    public static var dataURL = "https://price.autostat.ru"
    
    
    public let user, password: String
    let authURL, dataURL: String
    
    // MARK: Initialization
    
    public init(user: String, password: String, authURL: String = Autostat.authURL, dataURL: String = Autostat.dataURL) {
        self.user = user
        self.password = password
        self.authURL = authURL
        self.dataURL = dataURL
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
    
    // MARK: Authorization
    
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
    
    public func authorize(on container: Container) throws -> Future<String> {
        let requestPaylaod = TokenRequest(query: "mutation{generateToken(User:{username:\"\(user)\", password:\"\(password)\"}){value}}")
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/json")
        return try executeRequest(on: container, url: authURL, method: .POST, headers: headers) {
            try $0.content.encode(requestPaylaod, as: .json)
        }.flatMap {
            try $0.content.decode(TokenResponse.self).map { $0.data.generateToken.value }
        }
    }
    
    func authHeaders(token: String) -> HTTPHeaders {
        var headers = HTTPHeaders()
        headers.add(name: "token", value: token)
        return headers
    }
    
    // MARK: Get all brands
    
    public func allBrands(on container: Container, token: String) throws -> Future<[String]> {
        return try executeRequest(on: container, url: dataURL + "/priceCalc/param", method: .POST, headers: authHeaders(token: token)) {
            struct Payload: Content {
                let paramHierarchy = AutostatInner(name: .bandModel,
                                                         type: .folder,
                                                         inner: .init(name: .brand,
                                                                         type: .param))
            }
            try $0.content.encode(Payload(), as: .json)
        }.flatMap {
            struct Response: Codable {
                struct Value: Codable {
                    let value: String
                }
                let values: [Value]
            }
            return try $0.content.decode(Response.self).map { $0.values.map { $0.value } }
        }
    }
    
    // MARK: Get all models
    
    public func allModels(on container: Container, token: String, brand: String) throws -> Future<[String]> {
        return try executeRequest(on: container, url: dataURL + "/priceCalc/param", method: .POST, headers: authHeaders(token: token)) {
            struct Payload: Content {
                let paramHierarchy: AutostatInner
                init (brand: String) {
                    paramHierarchy = .init(name: .bandModel,
                                                      type: .folder,
                                                      inner: .init(name: .brand,
                                                                       type: .paramFolder,
                                                                       value: brand,
                                                                       inner: .init(name: .model,
                                                                                        type: .param)))
                }
            }
            try $0.content.encode(Payload(brand: brand), as: .json)
        }.flatMap {
            struct Response: Codable {
                struct Value: Codable {
                    let value: String
                }
                let values: [Value]
            }
            return try $0.content.decode(Response.self).map { $0.values.map { $0.value } }
        }
    }
    
    // MARK: Get all generations
    
    public func allGenerations(on container: Container, token: String, brand: String, model: String, byYear: String?) throws -> Future<[String]> {
        return try executeRequest(on: container, url: dataURL + "/priceCalc/param", method: .POST, headers: authHeaders(token: token)) {
            struct Payload: Content {
                let paramHierarchy: AutostatInner
                let selectionParams: [AutostatInner]
                
                init (brand: String, model: String, year: String?) {
                    paramHierarchy = .init(name: .bandModel,
                                                      type: .folder,
                                                      inner: .init(name: .brand,
                                                                       type: .paramFolder,
                                                                       value: brand,
                                                                       inner: .init(name: .model,
                                                                                        type: .paramFolder,
                                                                                        value: model,
                                                                                        inner: .init(name: .generation,
                                                                                                        type: .param))))
                    var sp: [AutostatInner] = []
                    if let year = year {
                        sp.append(.init(name: .year,
                                               type: .folder,
                                               inner: .init(name: .years,
                                                                type: .param,
                                                                value: year)))
                    }
                    selectionParams = sp
                }
            }
            try $0.content.encode(Payload(brand: brand, model: model, year: byYear), as: .json)
        }.flatMap {
            struct Response: Codable {
                struct Value: Codable {
                    let value: String
                }
                let values: [Value]
            }
            return try $0.content.decode(Response.self).map { $0.values.map { $0.value } }
        }
    }
    
    // MARK: Get all generations
    
    public func allModifications(on container: Container, token: String, brand: String, model: String, year: String, generation: String) throws -> Future<[String]> {
        return try executeRequest(on: container, url: dataURL + "/priceCalc/param", method: .POST, headers: authHeaders(token: token)) {
            struct Payload: Content {
                let paramHierarchy: AutostatInner
                let selectionParams: [AutostatInner]
                
                init (brand: String, model: String, year: String, generation: String) {
                    paramHierarchy = .init(name: .bandModel,
                                                      type: .folder,
                                                      inner: .init(name: .brand,
                                                                       type: .paramFolder,
                                                                       value: brand,
                                                                       inner: .init(name: .model,
                                                                                        type: .paramFolder,
                                                                                        value: model,
                                                                                        inner: .init(name: .generation,
                                                                                                         type: .paramFolder,
                                                                                                         value: generation,
                                                                                                         inner: .init(name: .modification,
                                                                                                                          type: .param)))))
                    selectionParams = [.init(name: .year,
                                                        type: .folder,
                                                        inner: .init(name: .years,
                                                                        type: .param,
                                                                        value: year))]
                }
            }
            try $0.content.encode(Payload(brand: brand, model: model, year: year, generation: generation), as: .json)
        }.flatMap {
            struct Response: Codable {
                struct Value: Codable {
                    let value: String
                }
                let values: [Value]
            }
            return try $0.content.decode(Response.self).map { $0.values.map { $0.value } }
        }
    }
    
    public func allModificationsStruct(on container: Container, token: String, brand: String, model: String, year: String, generation: String) throws -> Future<[AutostatModification]> {
        return try allModifications(on: container, token: token, brand: brand, model: model, year: year, generation: generation).map { try $0.map { try AutostatModification.from(raw: $0) } }
    }
    
    public func measures(on container: Container, token: String, brand: String, model: String, year: String, generation: String, modification: String) throws -> Future<[AutostatMeasureValue]> {
        return try executeRequest(on: container, url: dataURL + "/priceCalc/measuresValues", method: .POST, headers: authHeaders(token: token)) {
            struct Payload: Codable {
                var params: [AutostatSource] = []
            }
            var payload = Payload()
            payload.params.append(AutostatSource(sourceType: .measure, description: .measure(.priceMiddle)))
            payload.params.append(AutostatSource(sourceType: .measure, description: .measure(.priceMiddleTradeIn)))
            payload.params.append(AutostatSource(sourceType: .measure, description: .measure(.priceBase)))
            payload.params.append(AutostatSource(sourceType: .measure, description: .measure(.priceBaseTradeIn)))
            payload.params.append(AutostatSource(sourceType: .measure, description: .measure(.priceMax)))
            payload.params.append(AutostatSource(sourceType: .measure, description: .measure(.priceMaxTradeIn)))
            payload.params.append(AutostatSource(sourceType: .measure, description: .measure(.mileageMiddle)))
            let car: AutostatInner = .init(name: .bandModel,
                                          type: .folder,
                                          inner: .init(name: .brand,
                                                           type: .paramFolder,
                                                           value: brand,
                                                           inner: .init(name: .model,
                                                                            type: .paramFolder,
                                                                            value: model,
                                                                            inner: .init(name: .generation,
                                                                                            type: .paramFolder,
                                                                                            value: generation,
                                                                                            inner: .init(name: .modification,
                                                                                                         type: .param,
                                                                                                         value: modification)))))
            payload.params.append(AutostatSource(sourceType: .param, description: .inner(car)))
            let year: AutostatInner = .init(name: .year,
                                            type: .folder,
                                            inner: .init(name: .years,
                                                            type: .param,
                                                            value: year))
            payload.params.append(AutostatSource(sourceType: .param, description: .inner(year)))
            try $0.content.encode(payload, as: .json)
        }.flatMap {
            struct Response: Codable {
                let values: [AutostatMeasureValue]
            }
            return try $0.content.decode(Response.self).map { $0.values }
        }
    }
}

extension String {
    public var autostatBrand: String {
        switch self.lowercased() {
        case "газ": return "GAZ"
        case "иж": return "Izh"
        case "лада": return "Lada"
        case "ваз": return "Lada"
        case "тагаз": return "TagAZ"
        case "уаз": return "UAZ"
        case "заз": return "ZAZ"
        default: return self
        }
    }
}
