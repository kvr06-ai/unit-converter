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
    @Published var inputValueString: String = "1" // Start with a default value
    @Published var outputValueString: String = ""
    @Published var selectedCategory: UnitCategory? {
        didSet {
            // When category changes, update available units and potentially reset selected units
            updateAvailableUnits()
            // If the old units aren't in the new category, select defaults
            if let category = selectedCategory {
                if selectedInputUnit == nil || !category.units.contains(where: { $0.id == selectedInputUnit?.id }) {
                    selectedInputUnit = category.units.first // Select first unit as default
                }
                if selectedOutputUnit == nil || !category.units.contains(where: { $0.id == selectedOutputUnit?.id }) {
                    // Select second unit if available, else the first one again
                    selectedOutputUnit = category.units.count > 1 ? category.units[1] : category.units.first
                }
                savePreferences() // Save new category selection
            }
            performConversion()
        }
    }
    @Published var selectedInputUnit: UnitDefinition? {
        didSet {
             guard selectedInputUnit != selectedOutputUnit else { return } // Avoid unnecessary updates if same
             savePreferences()
             performConversion()
        }
    }
    @Published var selectedOutputUnit: UnitDefinition? {
         didSet {
             guard selectedOutputUnit != selectedInputUnit else { return } // Avoid unnecessary updates if same
             savePreferences()
             performConversion()
         }
    }

    @Published var availableUnits: [UnitDefinition] = [] // Units for the selected category
    @Published var allCategories: [UnitCategory] = [] // All available categories

    // State for presenting the unit selection sheet
    @Published var showingUnitSelector: Bool = false
    var selectingForInput: Bool = true // Track which unit (input/output) is being selected

    // MARK: - Internal State
    private var inputValue: Double? {
        // Use a specific NumberFormatter for robust parsing
        let formatter = NumberFormatter()
        formatter.locale = Locale.current // Use user's locale
        formatter.numberStyle = .decimal
        return formatter.number(from: inputValueString)?.doubleValue ?? Double(inputValueString) // Fallback for simple numbers
    }

    // MARK: - Initializer
    init() {
        self.allCategories = unitDataStore.categories
        loadPreferences() // Load last used settings
        // If no preferences loaded or data invalid, set initial defaults
        if selectedCategory == nil, let firstCategory = allCategories.first {
            selectedCategory = firstCategory // Default to the first category
            // selectedInputUnit and selectedOutputUnit will be set by selectedCategory's didSet
        } else if selectedCategory != nil {
            // Ensure loaded units are valid within the loaded category
            updateAvailableUnits() // Populate available units based on loaded category
            // Validate loaded units against the actual category data
             if let category = selectedCategory {
                 if selectedInputUnit == nil || !category.units.contains(where: {$0.id == selectedInputUnit!.id}) {
                     selectedInputUnit = category.units.first
                 }
                 if selectedOutputUnit == nil || !category.units.contains(where: {$0.id == selectedOutputUnit!.id}) {
                      selectedOutputUnit = category.units.count > 1 ? category.units[1] : category.units.first
                 }
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
        guard let currentInput = selectedInputUnit, let currentOutput = selectedOutputUnit else { return }
        // Swap units without triggering individual didSet logic until both are set
        let tempInput = currentInput
        let tempOutput = currentOutput
        objectWillChange.send() // Manually notify SwiftUI about the impending change
        selectedInputUnit = tempOutput
        selectedOutputUnit = tempInput
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
             if unit.id == selectedOutputUnit?.id && availableUnits.count > 1 {
                 // If the selected input unit is the same as the current output unit,
                 // and there's another unit available, swap them instead of just setting.
                 swapUnits()
             } else {
                 selectedInputUnit = unit
             }
        } else {
             if unit.id == selectedInputUnit?.id && availableUnits.count > 1 {
                 swapUnits()
             } else {
                 selectedOutputUnit = unit
             }
        }
        showingUnitSelector = false // Dismiss the sheet
        // performConversion is triggered by didSet of selected units
        // savePreferences is triggered by didSet of selected units
    }


    // MARK: - Core Logic
    private func performConversion() {
        guard let value = inputValue,
              let inputUnit = selectedInputUnit,
              let outputUnit = selectedOutputUnit else {
            outputValueString = "" // Clear output if input is invalid or units not set
            return
        }

        // Ensure units are from the same category (should be guaranteed by UI flow)
        if let category = selectedCategory,
           category.units.contains(where: {$0.id == inputUnit.id}),
           category.units.contains(where: {$0.id == outputUnit.id}) {

            if let result = conversionEngine.convert(value: value, from: inputUnit, to: outputUnit) {
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
        userDefaults.set(selectedCategory?.categoryName, forKey: PrefKeys.lastCategory)
        userDefaults.set(selectedInputUnit?.unitSymbol, forKey: PrefKeys.lastInputUnit)
        userDefaults.set(selectedOutputUnit?.unitSymbol, forKey: PrefKeys.lastOutputUnit)
        // UserDefaults automatically saves periodically, but force save if needed:
        // userDefaults.synchronize() // Generally not required anymore
    }

    private func loadPreferences() {
        if let categoryName = userDefaults.string(forKey: PrefKeys.lastCategory) {
            self.selectedCategory = unitDataStore.findCategory(name: categoryName)
        }

        // Important: Load units only *after* setting the category,
        // as findUnit(symbol:) requires the category context if using that specific variant.
        // Or use a findUnit that searches all categories.
         if let inputSymbol = userDefaults.string(forKey: PrefKeys.lastInputUnit),
            let (unit, _) = unitDataStore.findUnit(symbol: inputSymbol) {
              // Check if the loaded unit belongs to the loaded category
             if let category = self.selectedCategory, category.units.contains(where: { $0.id == unit.id }) {
                self.selectedInputUnit = unit
             } else if self.selectedCategory == nil {
                 // If category wasn't saved/found, but units were, try finding the category from the unit
                 if let (foundUnit, foundCategory) = unitDataStore.findUnit(symbol: inputSymbol) {
                     self.selectedCategory = foundCategory
                     self.selectedInputUnit = foundUnit
                 }
             }
         }


        if let outputSymbol = userDefaults.string(forKey: PrefKeys.lastOutputUnit),
           let (unit, _) = unitDataStore.findUnit(symbol: outputSymbol) {
             // Check if the loaded unit belongs to the loaded category
            if let category = self.selectedCategory, category.units.contains(where: { $0.id == unit.id }) {
               self.selectedOutputUnit = unit
            }
             // No need to find category again if input unit already did
        }

        // If after loading, units are still nil within a valid category, set defaults
        if let category = selectedCategory {
            if selectedInputUnit == nil {
                selectedInputUnit = category.units.first
            }
             if selectedOutputUnit == nil {
                 selectedOutputUnit = category.units.count > 1 ? category.units[1] : category.units.first
             }
             // Ensure loaded input/output units are not the same initially if possible
            if selectedInputUnit?.id == selectedOutputUnit?.id && category.units.count > 1 {
                 selectedOutputUnit = category.units[1] // Change output to second unit
            }
        }
    }
} 