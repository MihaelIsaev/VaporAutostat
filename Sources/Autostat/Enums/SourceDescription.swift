import Foundation

enum AutostatSourceDescription: Codable {
    case measure(AutostatMeasure)
    case inner(AutostatInner)
    
    func encode(to encoder: Encoder) throws {
        var single = encoder.singleValueContainer()
        switch self {
        case .measure(let measure):
            try single.encode(measure)
        case .inner(let inner):
            try single.encode(inner)
        }
    }
    
    init(from decoder: Decoder) throws {
        if let measure = try? decoder.singleValueContainer().decode(AutostatMeasure.self) {
            self = .measure(measure)
            return
        }
        
        if let inner = try? decoder.singleValueContainer().decode(AutostatInner.self) {
            self = .inner(inner)
            return
        }
        
        throw AutostatSourceDescriptionError.missingValue
    }
}
