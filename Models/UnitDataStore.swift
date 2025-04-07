import Foundation

class UnitDataStore {
    static let shared = UnitDataStore() // Singleton instance

    private(set) var categories: [UnitCategory] = []

    private init() { // Private initializer for singleton pattern
        loadUnits()
    }

    private func loadUnits() {
        guard let url = Bundle.main.url(forResource: "Units", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            // In a real app, provide better error handling or default data
            print("Error: Failed to load Units.json from bundle.")
            self.categories = [] // Initialize with empty data on failure
            return
            // Alternatively, use fatalError if the app cannot function without this data:
            // fatalError("Failed to load Units.json from bundle.")
        }

        let decoder = JSONDecoder()
        guard let loadedCategories = try? decoder.decode([UnitCategory].self, from: data) else {
            print("Error: Failed to decode Units.json.")
            self.categories = [] // Initialize with empty data on failure
            return
            // Alternatively, use fatalError:
            // fatalError("Failed to decode Units.json.")
        }

        self.categories = loadedCategories
    }

    // Function to find a unit by symbol within a specific category (as specified in TDD)
    // Might not be strictly necessary if we always work with the loaded objects, but good to have.
    func findUnit(symbol: String, in category: UnitCategory) -> UnitDefinition? {
        return category.units.first { $0.unitSymbol == symbol }
    }

     // Function to find a unit by symbol across all categories
    func findUnit(symbol: String) -> (UnitDefinition, UnitCategory)? {
        for category in categories {
            if let unit = category.units.first(where: { $0.unitSymbol == symbol }) {
                return (unit, category)
            }
        }
        return nil
    }

    // Function to get a category by name
    func findCategory(name: String) -> UnitCategory? {
        return categories.first { $0.categoryName == name }
    }
} 