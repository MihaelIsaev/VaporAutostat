import Foundation

public typealias AustModification = AutostatModification

public struct AutostatModification: Codable {
    public let capacity: Double
    public let gearbox: AutostatGearboxType
    public let hp: Int64
    public let fuelType: AutostatFuelType
    public let wheelDriveType: AutostatWheelDriveType
    
    public init (capacity: Double, gearbox: AutostatGearboxType, hp: Int64, fuelType: AutostatFuelType, wheelDriveType: AutostatWheelDriveType) {
        self.capacity = capacity
        self.gearbox = gearbox
        self.hp = hp
        self.fuelType = fuelType
        self.wheelDriveType = wheelDriveType
    }
    
    public static func from(raw: String) throws -> AutostatModification {
        let raw = raw.replacingOccurrences(of: " ", with: "/")
        var components = raw.components(separatedBy: "/")
        guard components.count == 5 else { throw AutostatModificationError.wrongRawValue }
        guard let capacity = Double(components.removeFirst()) else { throw AutostatModificationError.wrongCapacity }
        guard let gearbox = AutostatGearboxType(rawValue: components.removeFirst()) else { throw AutostatModificationError.wrongGearbox }
        guard let hp = Int64(components.removeFirst()) else { throw AutostatModificationError.wrongHP }
        guard let fuelType = AutostatFuelType(rawValue: components.removeFirst()) else { throw AutostatModificationError.wrongFuelType }
        guard let wheelDriveType = AutostatWheelDriveType(rawValue: components.removeFirst()) else { throw AutostatModificationError.wrongWheelDriveType }
        return AutostatModification(capacity: capacity, gearbox: gearbox, hp: hp, fuelType: fuelType, wheelDriveType: wheelDriveType)
    }
    
    public var str: String {
        let nf = NumberFormatter()
        nf.maximumFractionDigits = 1
        nf.minimumFractionDigits = 1
        nf.decimalSeparator = "."
        let capacity = nf.string(from: NSNumber(value: self.capacity)) ?? ""
        let gearbox = self.gearbox.rawValue
        let fuelType = self.fuelType.rawValue
        let wheelDriveType = self.wheelDriveType.rawValue
        return capacity + " \(gearbox)/\(hp)/\(fuelType)/\(wheelDriveType)" //3.0 AT/381/Дизель/Полный
    }
}
