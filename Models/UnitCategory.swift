import Foundation

struct UnitCategory: Codable, Hashable, Identifiable {
    var id: String { categoryName } // Use category name as unique ID
    let categoryName: String
    var units: [UnitDefinition]
} 