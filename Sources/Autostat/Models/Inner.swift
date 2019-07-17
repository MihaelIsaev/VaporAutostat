import Foundation

class AutostatInner: Codable {
    let name: AutostatInnerName
    let type: AutostatInnerType
    let value: String?
    let inner: AutostatInner?
    
    init (name: AutostatInnerName, type: AutostatInnerType, value: String? = nil, inner: AutostatInner? = nil) {
        self.name = name
        self.type = type
        self.value = value
        self.inner = inner
    }
}
