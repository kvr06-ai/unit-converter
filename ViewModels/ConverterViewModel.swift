// app-development/unit-converter/ViewModels/ConverterViewModel.swift
import Foundation
import Combine // For @Published and reactive updates
import SwiftUI // Needed for Binding, Color etc. (Optional, could be refactored)

@MainActor // Ensure UI updates happen on the main thread
class ConverterViewModel: ObservableObject {

    // MARK: - Dependencies
    private let unitDataStore = UnitDataStore.shared
    private let conversionEngine = ConversionEngine()
    private let userDefaults = UserDefaults.standard

    // MARK: - Published State Properties (for UI binding)
    @Published var inputValueString: String = ""
    @Published var outputValueString: String = ""
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category?
    @Published var availableUnits: [UnitDefinition] = []
    @Published var fromUnit: UnitDefinition?
    @Published var toUnit: UnitDefinition?

    // State for presenting the unit selection sheet
    @Published var showingUnitSelector: Bool = false
    var selectingForInput: Bool = true // Track which unit (input/output) is being selected

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init() {
        setupCategories()
        setupPublishers()
        loadPreferences() // Load last used settings
        // If no preferences loaded or data invalid, set initial defaults
        if selectedCategory == nil, let firstCategory = categories.first {
            selectedCategory = firstCategory // Default to the first category
            // fromUnit and toUnit will be set by selectedCategory's didSet
        } else if selectedCategory != nil {
            // Ensure loaded units are valid within the loaded category
            updateAvailableUnits() // Populate available units based on loaded category
            // Validate loaded units against the actual category data
             if let category = selectedCategory {
                 if fromUnit == nil || !category.units.contains(where: { $0.id == fromUnit?.id }) {
                     fromUnit = category.units.first // Select first unit as default
                 }
                 if toUnit == nil || !category.units.contains(where: { $0.id == toUnit?.id }) {
                     // Select second unit if available, else the first one again
                     toUnit = category.units.count > 1 ? category.units[1] : category.units.first
                 }
                 savePreferences() // Save new category selection
             }
        }
        performConversion() // Perform initial conversion
    }

    // MARK: - User Actions
    func updateInputValue(_ newValue: String) {
        // Basic filtering could be added here if needed (e.g., allow only numbers/decimal separator)
        if inputValueString != newValue { // Avoid redundant updates
            inputValueString = newValue
            performConversion()
        }
    }

    func swapUnits() {
        guard let currentFrom = fromUnit, let currentTo = toUnit else { return }
        // Swap units without triggering individual didSet logic until both are set
        let tempFrom = currentFrom
        let tempTo = currentTo
        objectWillChange.send() // Manually notify SwiftUI about the impending change
        fromUnit = tempTo
        toUnit = tempFrom
        // Preferences are saved within the individual didSet observers
        performConversion() // Recalculate after swap
    }

    func clearInput() {
        inputValueString = ""
        outputValueString = "" // Clear output as well
    }

    // Called when user taps on a unit selector button
    func unitSelectorTapped(isInput: Bool) {
        selectingForInput = isInput
        showingUnitSelector = true
    }

    // Called from UnitSelectionView when a unit is chosen
    func unitSelected(_ unit: UnitDefinition) {
        if selectingForInput {
             // Ensure we don't select the same unit for both input and output if possible
             if unit.id == toUnit?.id && availableUnits.count > 1 {
                 // If the selected input unit is the same as the current output unit,
                 // and there's another unit available, swap them instead of just setting.
                 swapUnits()
             } else {
                 fromUnit = unit
             }
        } else {
             if unit.id == fromUnit?.id && availableUnits.count > 1 {
                 swapUnits()
             } else {
                 toUnit = unit
             }
        }
        showingUnitSelector = false // Dismiss the sheet
        // performConversion is triggered by didSet of selected units
        // savePreferences is triggered by didSet of selected units
    }

    // MARK: - Core Logic
    func performConversion() {
        guard let value = Double(inputValueString), !inputValueString.isEmpty else {
            outputValueString = "" // Clear output if input is invalid or units not set
            return
        }

        // Ensure units are from the same category (should be guaranteed by UI flow)
        if let category = selectedCategory,
           category.units.contains(where: {$0.id == fromUnit?.id}),
           category.units.contains(where: {$0.id == toUnit?.id}) {

            if let result = conversionEngine.convert(value: value, from: fromUnit!, to: toUnit!) {
                outputValueString = formatValue(result)
            } else {
                outputValueString = "Error" // Indicate conversion failure
            }
        } else {
             outputValueString = "Error" // Indicate incompatible units (shouldn't happen ideally)
        }
    }

    private func updateAvailableUnits() {
        if let category = selectedCategory {
            availableUnits = category.units
        } else {
            availableUnits = []
        }
    }

    // MARK: - Formatting
    private func formatValue(_ value: Double) -> String {
        // Use NumberFormatter for locale-aware formatting and precision control
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6 // Adjust precision as needed
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true // e.g., 1,000.5
        formatter.locale = Locale.current

        // Handle very large or very small numbers potentially with scientific notation
        // Or clamp to a reasonable range if preferred. For now, standard decimal.

        return formatter.string(from: NSNumber(value: value)) ?? "\(value)" // Fallback to simple string representation
    }

    // MARK: - User Preferences (UserDefaults)
    private struct PrefKeys {
        static let lastCategory = "lastUsedCategoryName"
        static let lastInputUnit = "lastInputUnitSymbol"
        static let lastOutputUnit = "lastOutputUnitSymbol"
    }

    private func savePreferences() {
        userDefaults.set(selectedCategory?.name, forKey: PrefKeys.lastCategory)
        userDefaults.set(fromUnit?.unitSymbol, forKey: PrefKeys.lastInputUnit)
        userDefaults.set(toUnit?.unitSymbol, forKey: PrefKeys.lastOutputUnit)
        // UserDefaults automatically saves periodically, but force save if needed:
        // userDefaults.synchronize() // Generally not required anymore
    }

    private func loadPreferences() {
        if let categoryName = userDefaults.string(forKey: PrefKeys.lastCategory) {
            self.selectedCategory = categories.first(where: { $0.name == categoryName })
        }

        // Important: Load units only *after* setting the category,
        // as findUnit(symbol:) requires the category context if using that specific variant.
        // Or use a findUnit that searches all categories.
         if let inputSymbol = userDefaults.string(forKey: PrefKeys.lastInputUnit),
            let (unit, _) = unitDataStore.findUnit(symbol: inputSymbol) {
              // Check if the loaded unit belongs to the loaded category
             if let category = self.selectedCategory, category.units.contains(where: { $0.id == unit.id }) {
                self.fromUnit = unit
             } else if self.selectedCategory == nil {
                 // If category wasn't saved/found, but units were, try finding the category from the unit
                 if let (foundUnit, foundCategory) = unitDataStore.findUnit(symbol: inputSymbol) {
                     self.selectedCategory = categories.first(where: { $0.name == foundCategory.categoryName })
                     self.fromUnit = foundUnit
                 }
             }
         }


        if let outputSymbol = userDefaults.string(forKey: PrefKeys.lastOutputUnit),
           let (unit, _) = unitDataStore.findUnit(symbol: outputSymbol) {
             // Check if the loaded unit belongs to the loaded category
            if let category = self.selectedCategory, category.units.contains(where: { $0.id == unit.id }) {
               self.toUnit = unit
            }
             // No need to find category again if input unit already did
        }

        // If after loading, units are still nil within a valid category, set defaults
        if let category = selectedCategory {
            if fromUnit == nil {
                fromUnit = category.units.first
            }
             if toUnit == nil {
                 toUnit = category.units.count > 1 ? category.units[1] : category.units.first
             }
             // Ensure loaded input/output units are not the same initially if possible
            if fromUnit?.id == toUnit?.id && category.units.count > 1 {
                 toUnit = category.units[1] // Change output to second unit
            }
        }
    }

    private func setupCategories() {
        // Get categories from UnitDataStore
        let dataStoreCategories = UnitDataStore.shared.categories
        
        // Convert UnitCategory to Category for our ViewModel
        categories = dataStoreCategories.map { unitCategory in
            Category(id: unitCategory.id, name: unitCategory.categoryName, iconName: getCategoryIcon(for: unitCategory.categoryName), units: unitCategory.units)
        }
        
        // Default to first category
        if let firstCategory = categories.first {
            selectedCategory = firstCategory
            updateAvailableUnits()
        }
    }
    
    private func getCategoryIcon(for categoryName: String) -> String {
        switch categoryName {
        case "Length": return "ruler"
        case "Mass": return "scalemass"
        case "Volume": return "cup.and.saucer"
        case "Temperature": return "thermometer"
        case "Time": return "clock"
        case "Speed": return "speedometer"
        case "Area": return "square.on.square"
        case "Data": return "internaldrive"
        default: return "questionmark.circle"
        }
    }
    
    private func setupPublishers() {
        // Observe changes to inputValueString, fromUnit, and toUnit
        Publishers.CombineLatest3($inputValueString, $fromUnit, $toUnit)
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.performConversion()
            }
            .store(in: &cancellables)
        
        // Observe changes to selectedCategory
        $selectedCategory
            .dropFirst() // Skip the initial value
            .sink { [weak self] category in
                if let category = category {
                    self?.updateAvailableUnits()
                    // Set default from/to units if needed
                    if self?.fromUnit == nil {
                        self?.fromUnit = category.units.first
                    }
                    if self?.toUnit == nil {
                        self?.toUnit = category.units.count > 1 ? category.units[1] : category.units.first
                    }
                    self?.performConversion()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Models

struct Category: Identifiable, Hashable {
    let id: String
    let name: String
    let iconName: String
    let units: [UnitDefinition]
    
    // Helper method to convert to UnitCategory
    func toUnitCategory() -> UnitCategory {
        return UnitCategory(categoryName: name, units: units)
    }
}

// Helper for the view model to provide UnitCategory versions of its data
extension ConverterViewModel {
    var unitCategories: [UnitCategory] {
        return categories.map { $0.toUnitCategory() }
    }
    
    var selectedUnitCategory: UnitCategory? {
        return selectedCategory?.toUnitCategory()
    }
    
    // Binding wrapper for selectedCategory that works with UnitCategory
    func selectedUnitCategoryBinding() -> Binding<UnitCategory?> {
        return Binding<UnitCategory?>(
            get: { [weak self] in
                return self?.selectedCategory?.toUnitCategory()
            },
            set: { [weak self] newValue in
                if let newValue = newValue {
                    // Find matching category by name
                    self?.selectedCategory = self?.categories.first(where: { $0.name == newValue.categoryName })
                } else {
                    self?.selectedCategory = nil
                }
            }
        )
    }
} 