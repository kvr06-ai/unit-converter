import Foundation

// Define a struct to represent CategoryGroup
struct CategoryGroup: Codable, Identifiable {
    var id: String { categoryGroup }
    let categoryGroup: String
    let categories: [UnitCategory]
}

class UnitDataStore {
    static let shared = UnitDataStore() // Singleton instance

    private(set) var categoryGroups: [CategoryGroup] = []
    private(set) var categories: [UnitCategory] = []

    private init() { // Private initializer for singleton pattern
        loadUnits()
    }

    private func loadUnits() {
        guard let url = Bundle.main.url(forResource: "Units", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            // In a real app, provide better error handling or default data
            print("Error: Failed to load Units.json from bundle.")
            self.categoryGroups = []
            self.categories = [] // Initialize with empty data on failure
            return
        }

        let decoder = JSONDecoder()
        do {
            // Decode the JSON file as an array of CategoryGroup
            let loadedCategoryGroups = try decoder.decode([CategoryGroup].self, from: data)
            
            // Store the category groups
            self.categoryGroups = loadedCategoryGroups
            
            // Also flatten the categories for backward compatibility
            self.categories = loadedCategoryGroups.flatMap { $0.categories }
        } catch {
            print("Error: Failed to decode Units.json. Details: \(error)")
            self.categoryGroups = []
            self.categories = [] // Initialize with empty data on failure
        }
    }

    // Function to find a unit by symbol within a specific category (as specified in TDD)
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
    
    // Function to get categories in a specific group
    func getCategories(inGroup groupName: String) -> [UnitCategory] {
        return categoryGroups.first(where: { $0.categoryGroup == groupName })?.categories ?? []
    }
} 