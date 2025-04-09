import Foundation

struct UnitDefinition: Codable, Hashable, Identifiable {
    var id: String { unitSymbol } // Use symbol as unique ID for Identifiable conformance
    let unitName: String
    let unitSymbol: String
    let conversionFactor: Double
    let offset: Double? // Optional offset for temperature conversion
    let isBase: Bool? // Optional flag for base unit
    let description: String? // Optional description of the unit

    // Helper to determine if this unit needs special temperature handling
    var isTemperature: Bool {
        offset != nil
    }
} 