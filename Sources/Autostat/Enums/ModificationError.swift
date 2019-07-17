import Foundation

public enum AutostatModificationError: Error {
    case wrongRawValue
    case wrongCapacity
    case wrongGearbox
    case wrongHP
    case wrongFuelType
    case wrongWheelDriveType
}
