import Foundation

public enum AutostatFuelType: String, Codable {
    case petrol = "Бензин"
    case diesel = "Дизель"
    case gas = "Газ"
    case hydrogen = "Водород"
    case hybrid = "Гибрид"
    case electricity = "Электричество"
}
