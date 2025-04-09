// app-development/unit-converter/ViewModels/ConverterViewModel.swift
import Foundation
import Combine // For @Published and reactive updates
import SwiftUI // Needed for Binding, Color etc. (Optional, could be refactored)
import os.log // For structured logging

@MainActor // Ensure UI updates happen on the main thread
class ConverterViewModel: ObservableObject {
    // MARK: - Logger
    private let logger = Logger(subsystem: "com.converter.app", category: "ConverterViewModel")

    // MARK: - Dependencies
    private let unitDataStore = UnitDataStore.shared
    private let conversionEngine = ConversionEngine()
    private let userDefaults = UserDefaults.standard

    // MARK: - Published State Properties (for UI binding)
    @Published var inputValueString: String = ""
    @Published var outputValueString: String = ""
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category? {
        didSet {
            logger.debug("Category changed to: \(self.selectedCategory?.name ?? "nil")")
            if selectedCategory != oldValue {
                Task {
                    await updateForCategoryChange()
                }
            }
        }
    }
    @Published var availableUnits: [UnitDefinition] = []
    @Published var fromUnit: UnitDefinition? {
        didSet {
            if fromUnit != oldValue {
                logger.debug("From unit changed to: \(self.fromUnit?.unitName ?? "nil")")
                savePreferences()
            }
        }
    }
    @Published var toUnit: UnitDefinition? {
        didSet {
            if toUnit != oldValue {
                logger.debug("To unit changed to: \(self.toUnit?.unitName ?? "nil")")
                savePreferences()
            }
        }
    }

    // State for presenting the unit selection sheet
    @Published var showingUnitSelector: Bool = false
    var selectingForInput: Bool = true // Track which unit (input/output) is being selected

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init() {
        logger.info("ConverterViewModel initializing")
        setupCategories()
        setupPublishers()
        loadPreferences() // Load last used settings
        // If no preferences loaded or data invalid, set initial defaults
        if selectedCategory == nil, let firstCategory = categories.first {
            logger.debug("No saved category, defaulting to first category")
            selectedCategory = firstCategory // Default to the first category
            // fromUnit and toUnit will be set by selectedCategory's didSet
        } else if selectedCategory != nil {
            // Ensure loaded units are valid within the loaded category
            logger.debug("Found saved category, updating available units")
            updateAvailableUnits() // Populate available units based on loaded category
            // Validate loaded units against the actual category data
             if let category = selectedCategory {
                 if fromUnit == nil || !category.units.contains(where: { $0.id == fromUnit?.id }) {
                     logger.debug("Setting default fromUnit")
                     fromUnit = category.units.first // Select first unit as default
                 }
                 if toUnit == nil || !category.units.contains(where: { $0.id == toUnit?.id }) {
                     // Select second unit if available, else the first one again
                     logger.debug("Setting default toUnit")
                     toUnit = category.units.count > 1 ? category.units[1] : category.units.first
                 }
                 savePreferences() // Save new category selection
             }
        }
        performConversion() // Perform initial conversion
        logger.info("ConverterViewModel initialization complete")
    }

    // MARK: - User Actions
    func updateInputValue(_ newValue: String) {
        // Basic filtering could be added here if needed (e.g., allow only numbers/decimal separator)
        if inputValueString != newValue { // Avoid redundant updates
            logger.debug("Input value changed: \(newValue)")
            inputValueString = newValue
            performConversion()
        }
    }

    func swapUnits() {
        guard let currentFrom = fromUnit, let currentTo = toUnit else { return }
        // Swap units without triggering individual didSet logic until both are set
        logger.debug("Swapping units")
        let tempFrom = currentFrom
        let tempTo = currentTo
        objectWillChange.send() // Manually notify SwiftUI about the impending change
        fromUnit = tempTo
        toUnit = tempFrom
        // Preferences are saved within the individual didSet observers
        performConversion() // Recalculate after swap
    }

    func clearInput() {
        logger.debug("Clearing input value")
        inputValueString = ""
        outputValueString = "" // Clear output as well
    }

    // Called when user taps on a unit selector button
    func unitSelectorTapped(isInput: Bool) {
        logger.debug("Unit selector tapped, isInput: \(isInput)")
        selectingForInput = isInput
        showingUnitSelector = true
    }

    // Called from UnitSelectionView when a unit is chosen
    func unitSelected(_ unit: UnitDefinition) {
        logger.debug("Unit selected: \(unit.unitName)")
        if selectingForInput {
             // Ensure we don't select the same unit for both input and output if possible
             if unit.id == toUnit?.id && availableUnits.count > 1 {
                 // If the selected input unit is the same as the current output unit,
                 // and there's another unit available, swap them instead of just setting.
                 logger.debug("Selected input unit matches output unit, swapping")
                 swapUnits()
             } else {
                 fromUnit = unit
             }
        } else {
             if unit.id == fromUnit?.id && availableUnits.count > 1 {
                 logger.debug("Selected output unit matches input unit, swapping")
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
        let startTime = Date()
        logger.debug("Starting conversion calculation")
        
        guard let value = Double(inputValueString), !inputValueString.isEmpty else {
            logger.debug("Invalid input value, clearing output")
            outputValueString = "" // Clear output if input is invalid or units not set
            return
        }

        // Ensure units are from the same category (should be guaranteed by UI flow)
        if let category = selectedCategory,
           let fromUnit = fromUnit,
           let toUnit = toUnit,
           category.units.contains(where: {$0.id == fromUnit.id}),
           category.units.contains(where: {$0.id == toUnit.id}) {

            logger.debug("Converting \(value) from \(fromUnit.unitName) to \(toUnit.unitName)")
            if let result = conversionEngine.convert(value: value, from: fromUnit, to: toUnit) {
                outputValueString = formatValue(result)
                logger.debug("Conversion result: \(result)")
            } else {
                outputValueString = "Error" // Indicate conversion failure
                logger.error("Conversion failed")
            }
        } else {
             outputValueString = "Error" // Indicate incompatible units (shouldn't happen ideally)
             logger.error("Incompatible units for conversion")
        }
        
        let timeElapsed = Date().timeIntervalSince(startTime)
        logger.debug("Conversion completed in \(timeElapsed) seconds")
    }
    
    private func updateForCategoryChange() async {
        let startTime = Date()
        logger.debug("Beginning category change update")
        
        // Update available units for the new category
        updateAvailableUnits()
        
        // Before setting new unit values, check if the current units are valid for the new category
        if let category = selectedCategory {
            var shouldPerformConversion = false
            
            // Check and update fromUnit if needed
            if fromUnit == nil || !availableUnits.contains(where: { $0.id == fromUnit?.id }) {
                logger.debug("Updating fromUnit for new category")
                fromUnit = availableUnits.first
                shouldPerformConversion = true
            }
            
            // Check and update toUnit if needed
            if toUnit == nil || !availableUnits.contains(where: { $0.id == toUnit?.id }) {
                logger.debug("Updating toUnit for new category")
                toUnit = availableUnits.count > 1 ? availableUnits[1] : availableUnits.first
                shouldPerformConversion = true
            }
            
            // Avoid same unit selection if possible
            if fromUnit?.id == toUnit?.id && availableUnits.count > 1 {
                logger.debug("Units are the same, selecting different toUnit")
                toUnit = availableUnits[1]
                shouldPerformConversion = true
            }
            
            if shouldPerformConversion {
                // Use await to ensure this runs on the main actor after the UI updates
                await MainActor.run {
                    performConversion()
                }
            }
        }
        
        let timeElapsed = Date().timeIntervalSince(startTime)
        logger.debug("Category change update completed in \(timeElapsed) seconds")
    }

    private func updateAvailableUnits() {
        let startTime = Date()
        logger.debug("Updating available units")
        
        if let category = selectedCategory {
            availableUnits = category.units
            logger.debug("Updated available units: \(category.units.count) units for category \(category.name)")
        } else {
            availableUnits = []
            logger.debug("No category selected, cleared available units")
        }
        
        let timeElapsed = Date().timeIntervalSince(startTime)
        logger.debug("Available units updated in \(timeElapsed) seconds")
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
        logger.debug("Saving user preferences")
        userDefaults.set(selectedCategory?.name, forKey: PrefKeys.lastCategory)
        userDefaults.set(fromUnit?.unitSymbol, forKey: PrefKeys.lastInputUnit)
        userDefaults.set(toUnit?.unitSymbol, forKey: PrefKeys.lastOutputUnit)
        // UserDefaults automatically saves periodically, but force save if needed:
        // userDefaults.synchronize() // Generally not required anymore
    }

    private func loadPreferences() {
        logger.debug("Loading user preferences")
        if let categoryName = userDefaults.string(forKey: PrefKeys.lastCategory) {
            logger.debug("Found saved category: \(categoryName)")
            self.selectedCategory = categories.first(where: { $0.name == categoryName })
        }

        // Important: Load units only *after* setting the category,
        // as findUnit(symbol:) requires the category context if using that specific variant.
        // Or use a findUnit that searches all categories.
         if let inputSymbol = userDefaults.string(forKey: PrefKeys.lastInputUnit),
            let (unit, _) = unitDataStore.findUnit(symbol: inputSymbol) {
              // Check if the loaded unit belongs to the loaded category
             logger.debug("Found saved input unit: \(inputSymbol)")
             if let category = self.selectedCategory, category.units.contains(where: { $0.id == unit.id }) {
                self.fromUnit = unit
             } else if self.selectedCategory == nil {
                 // If category wasn't saved/found, but units were, try finding the category from the unit
                 if let (foundUnit, foundCategory) = unitDataStore.findUnit(symbol: inputSymbol) {
                     logger.debug("Setting category based on found input unit")
                     self.selectedCategory = self.categories.first(where: { $0.name == foundCategory.categoryName })
                     self.fromUnit = foundUnit
                 }
             }
         }


        if let outputSymbol = userDefaults.string(forKey: PrefKeys.lastOutputUnit),
           let (unit, _) = unitDataStore.findUnit(symbol: outputSymbol) {
             // Check if the loaded unit belongs to the loaded category
            logger.debug("Found saved output unit: \(outputSymbol)")
            if let category = self.selectedCategory, category.units.contains(where: { $0.id == unit.id }) {
               self.toUnit = unit
            }
             // No need to find category again if input unit already did
        }

        // If after loading, units are still nil within a valid category, set defaults
        if let category = selectedCategory {
            logger.debug("Setting default units if needed")
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
        let startTime = Date()
        logger.debug("Setting up categories")
        
        // Get categories from UnitDataStore
        let dataStoreCategories = UnitDataStore.shared.categories
        
        // Convert UnitCategory to Category for our ViewModel
        categories = dataStoreCategories.map { unitCategory in
            Category(id: unitCategory.id, name: unitCategory.categoryName, iconName: getCategoryIcon(for: unitCategory.categoryName), units: unitCategory.units)
        }
        
        logger.debug("Set up \(self.categories.count) categories")
        
        // Default to first category
        if let firstCategory = categories.first {
            selectedCategory = firstCategory
            updateAvailableUnits()
        }
        
        let timeElapsed = Date().timeIntervalSince(startTime)
        logger.debug("Categories setup completed in \(timeElapsed) seconds")
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
        logger.debug("Setting up Combine publishers")
        
        // Observe changes to inputValueString, fromUnit, and toUnit
        // Use debounce to avoid excessive updates during typing
        $inputValueString
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.logger.debug("Input value publisher triggered")
                self?.performConversion()
            }
            .store(in: &cancellables)
        
        // Handle unit changes without debounce for immediate response
        Publishers.CombineLatest($fromUnit, $toUnit)
            .sink { [weak self] _, _ in
                self?.logger.debug("Unit selection publisher triggered")
                self?.performConversion()
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