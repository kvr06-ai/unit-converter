# Technical Design Document: Converter iOS App v1.0

**Author:** Principal Product Developer
**Date:** April 7, 2025
**Version:** 1.0

## 1. Introduction & Overview

This document outlines the technical design for **Converter**, a mobile unit conversion application for iOS. The primary goal is to create the *best* unit converter on the App Store by focusing on simplicity, speed, accuracy, elegance, and an intuitive user experience. It is designed as a Level 1 application: completely self-contained, requiring no internet access for its core functionality after installation. We will abstract away unnecessary complexity, presenting the user with only what they need, when they need it.

## 2. Goals

* **Simplicity:** Provide an incredibly intuitive and easy-to-use interface. Users should understand how to perform a conversion within seconds.
* **Speed:** The app must launch quickly and perform conversions instantaneously. UI interactions should be fluid and responsive.
* **Accuracy:** Conversion factors must be precise and reliable.
* **Elegance:** A clean, modern, minimalist aesthetic adhering to iOS design principles, but with its own refined identity.
* **Comprehensiveness (Balanced with Simplicity):** Support a wide range of common and useful unit categories and units without cluttering the interface.
* **Offline First:** Core functionality must work perfectly without any internet connection.
* **Privacy:** Collect absolutely no user data. No network calls are made.

## 3. Non-Goals (for v1.0)

* **Internet-Dependent Features:** No live currency rate updates (this would make it Level 1.5).
* **User Accounts or Syncing:** No cloud backup or synchronization.
* **Advanced History Tracking:** While the last conversion might be remembered, extensive history logs are out of scope for v1.
* **Custom Unit Creation:** Users cannot define their own units or conversion factors.
* **Themes or Advanced Customization:** Beyond potential Light/Dark mode support dictated by iOS system settings.
* **Ads or Complex Monetization:** The focus is purely on delivering the best free utility. Monetization can be explored *much* later if non-intrusive options align with the core philosophy.
* **iPad or watchOS Specific Layouts:** Focus solely on a universal iPhone layout first.

## 4. User Experience (UX) Design Philosophy

* **"It Just Works":** Conversions should feel effortless. Minimize taps and cognitive load.
* **Direct Manipulation:** Users should interact directly with the values and units they want to change.
* **Clarity over Features:** Prioritize a clear presentation of the essential conversion over packing in features.
* **Discoverability:** While comprehensive, finding the right unit should be easy via intuitive categories and search.
* **Feedback:** Provide subtle visual feedback for interactions (e.g., highlighting selected units, instant result updates).
* **Aesthetics:** Clean typography, appropriate use of whitespace, smooth animations.

## 5. Functional Requirements (User Stories)

* **As a user, I want to input a numerical value** so that I can specify the quantity to be converted.
* **As a user, I want to select an input unit** from a categorized and searchable list, so that I specify the origin unit.
* **As a user, I want to select an output unit** from the same category as the input unit, so that I specify the target unit.
* **As a user, I want to see the converted value instantly** update as I type the input value or change units.
* **As a user, I want to easily swap the input and output units** with a single tap.
* **As a user, I want to easily clear the current input value** to start a new conversion.
* **As a user, I want the app to remember the last used unit category and selected units** for convenience when I reopen the app.
* **As a user, I want to be able to copy the output value** to the clipboard with a simple gesture (e.g., tap/long press).
* **As a user, I want access to common unit categories** like Length, Weight/Mass, Volume, Temperature, Speed, Area, Time, Data Storage.

## 6. Non-Functional Requirements

* **Performance:** App launch time < 1 second. Conversions must appear instantaneous (< 50ms). UI animations smooth (60+ fps).
* **Reliability:** The app must not crash. Calculations must be consistently accurate based on defined factors.
* **Usability:** Adhere to iOS Human Interface Guidelines (HIG). High contrast ratios for accessibility. Dynamic Type support.
* **Security:** No external network connections. All data (unit definitions, minimal user prefs) stored locally.
* **Maintainability:** Code should be well-structured, commented, and testable.
* **Storage Footprint:** Keep the app size reasonable; unit data should be stored efficiently.

## 7. Architecture

* **Pattern:** MVVM (Model-View-ViewModel)
    * **Model:** Represents the data (Unit definitions, conversion factors) and the conversion logic. Contains no UI logic.
    * **View:** SwiftUI Views. Displays the data provided by the ViewModel. Sends user actions to the ViewModel. Minimal logic.
    * **ViewModel:** Acts as the intermediary. Fetches data from the Model, formats it for the View, handles user input (e.g., number typing, unit selection), performs conversions via the Model, and exposes state (`@Published` properties) for the View to observe.
* **Key Components:**
    * `UnitDataStore`: Loads and provides access to all unit definitions and conversion factors.
    * `ConversionEngine`: Contains the logic to perform conversions between units within the same category.
    * `ConverterViewModel`: Manages the state of the main conversion screen (input value, selected units, output value).
    * `ConverterView`: The main SwiftUI view displaying the input/output panels and unit selectors.
    * `UnitSelectionView`: A modal or sheet view for Browse/searching/selecting units.
    * `UnitSelectionViewModel`: Manages the state and logic for the unit selection view.

## 8. Data Model

* **Unit Definition Data:**
    * A structured format (e.g., JSON or Plist) bundled within the app.
    * Hierarchical Structure:
        * `Categories` (Array): e.g., "Length", "Mass", "Volume"
            * `Category Name` (String)
            * `Units` (Array):
                * `Unit Name` (String): e.g., "Meter", "Kilogram"
                * `Unit Symbol` (String): e.g., "m", "kg"
                * `Conversion Factor` (Double): Factor to convert *from this unit* to a designated *base unit* for the category (e.g., for Length, the base unit might be Meter. Kilometer would have a factor of 1000, Centimeter 0.01).
                * `Base Unit` (Bool - optional): Flag indicating if this is the base unit for the category.
    * *Example Snippet (JSON):*
        ```json
        [
          {
            "categoryName": "Length",
            "units": [
              {"unitName": "Meter", "unitSymbol": "m", "conversionFactor": 1.0, "isBase": true},
              {"unitName": "Kilometer", "unitSymbol": "km", "conversionFactor": 1000.0},
              {"unitName": "Centimeter", "unitSymbol": "cm", "conversionFactor": 0.01},
              {"unitName": "Mile", "unitSymbol": "mi", "conversionFactor": 1609.34},
              {"unitName": "Foot", "unitSymbol": "ft", "conversionFactor": 0.3048}
            ]
          },
          // ... other categories
        ]
        ```
* **User Preferences:**
    * Stored using `UserDefaults`.
    * Keys: `lastUsedCategoryName`, `lastInputUnitSymbol`, `lastOutputUnitSymbol`.

## 9. API Design (Internal)

* **`UnitDataStore`:**
    * `func loadCategories() -> [UnitCategory]`
    * `func findUnit(symbol: String, in category: UnitCategory) -> UnitDefinition?`
* **`ConversionEngine`:**
    * `func convert(value: Double, from inputUnit: UnitDefinition, to outputUnit: UnitDefinition, in category: UnitCategory) -> Double?` (Handles conversion via base units)
* **`ConverterViewModel` -> `View` Communication:** Primarily via `@Published` properties for reactive UI updates (e.g., `inputValueString`, `outputValueString`, `selectedInputUnit`, `selectedOutputUnit`).
* **`View` -> `ConverterViewModel` Communication:** Function calls for user actions (e.g., `func unitSelectorTapped(isInput: Bool)`, `func swapUnitsTapped()`, `func clearInputTapped()`, `func updateInputValue(_ newValue: String)`).

## 10. Key Components/Modules (Details)

* **`UnitDataStore`:**
    * Responsible for parsing the bundled JSON/Plist file on first access.
    * Holds the unit data in memory for fast access.
    * Provides methods to retrieve categories and specific units.
* **`ConversionEngine`:**
    * Takes input value, input unit, output unit.
    * Validates that units belong to the same category.
    * Converts input value to the category's base unit value (`value * inputUnit.conversionFactor`).
    * Converts base unit value to the output unit value (`baseValue / outputUnit.conversionFactor`).
    * Handles potential edge cases (division by zero, though unlikely with proper data). Handles Temperature conversions separately as they involve offsets (Celsius, Fahrenheit, Kelvin).
* **`ConverterViewModel`:**
    * Holds `@Published` state variables for `inputValueString`, `outputValueString`, `selectedCategory`, `selectedInputUnit`, `selectedOutputUnit`.
    * Uses Combine or async/await to react to changes in `inputValueString` or selected units, triggering recalculation via `ConversionEngine`.
    * Formats output numbers appropriately (e.g., limiting decimal places).
    * Saves/Loads last used units/category from `UserDefaults`.
* **`ConverterView`:**
    * Main screen layout (e.g., two main panels for Input and Output).
    * Displays values and unit symbols bound from `ConverterViewModel`.
    * Includes tappable areas for changing units (presents `UnitSelectionView`).
    * Includes buttons for Swap, Clear, potentially Copy.
    * Uses a custom numeric input view or leverages `TextField` with `.keyboardType(.decimalPad)`.
* **`UnitSelectionView`:**
    * Presented modally (sheet).
    * Displays list of categories first, or directly shows units of the current category.
    * Includes a search bar to filter units quickly by name or symbol.
    * Allows tapping a unit to select it and dismiss the view, updating the `ConverterViewModel`.

## 11. Technology Stack

* **Language:** Swift (latest stable version)
* **UI Framework:** SwiftUI (declarative, modern)
* **Architecture:** MVVM
* **Data Persistence:** Bundled JSON/Plist for unit data, `UserDefaults` for user preferences.
* **Concurrency:** Combine / Swift Concurrency (async/await) for handling user input and state updates reactively.

## 12. Data Persistence Strategy

* **Unit Data:** A read-only JSON or Plist file included in the app bundle. Loaded once by `UnitDataStore`. Updates require an app update.
* **User Preferences:** Simple key-value storage using `UserDefaults` for remembering the last selected category and units. Minimal data, non-critical.

## 13. Offline Strategy

The app is designed to be fully offline. All necessary data (unit definitions, conversion factors) is bundled within the application. No network calls are required or implemented for core functionality.

## 14. UI Design Mockups/Wireframes (Conceptual Description)

* **Main Screen (`ConverterView`):**
    * Split vertically or horizontally into two main sections: "From" (Input) and "To" (Output).
    * Each section contains:
        * A large, clear display area for the numerical value. The input area is editable (e.g., looks like a `TextField` or custom input). The output area is read-only.
        * A tappable element showing the currently selected unit name/symbol (e.g., "Kilometer | km"). Tapping this opens the `UnitSelectionView`.
    * A prominent "Swap" button (e.g., arrows icon) positioned centrally between the sections.
    * Potentially a subtle "Clear" button associated with the input area.
    * Copy functionality might be triggered by tapping/long-pressing the output value area.
* **Unit Selection Screen (`UnitSelectionView`):**
    * Presented as a modal sheet.
    * Top: Search Bar.
    * Content: List of units belonging to the currently selected category. Each row shows unit name and symbol. If no category is selected initially, it might show a list of Categories first.
    * Tapping a unit selects it and dismisses the sheet.

## 15. Error Handling

* **Invalid Input:** Handle non-numeric input gracefully in the input field (e.g., filter characters or show a subtle warning). Prevent calculation if input is invalid.
* **Conversion Errors:** The `ConversionEngine` should handle potential mathematical errors (though unlikely with factors), perhaps returning `nil` or throwing an error caught by the ViewModel. Log internal errors for debugging. For the user, invalid conversions (e.g., trying to convert meters to kilograms) are prevented by the UI design (only showing units from the same category).
* **Data Loading Errors:** Handle potential failure when parsing the bundled unit data file (e.g., log error, show a user-friendly message, though this should ideally never happen with bundled data).

## 16. Testing Strategy

* **Unit Tests:**
    * Test `ConversionEngine` extensively with various units, values, edge cases (zero, large numbers), and temperature conversions.
    * Test `UnitDataStore` parsing logic (if complex) or simply verify data integrity.
    * Test `ConverterViewModel` logic: state updates, saving/loading preferences, interaction with `ConversionEngine`.
* **UI Tests:**
    * Automate basic user flows: entering values, selecting units, swapping, clearing.
    * Verify UI elements display correct data based on ViewModel state.
    * Test responsiveness and layout on different device sizes (simulators).

## 17. Future Considerations / Potential Enhancements (Post v1.0)

* **History:** Store recent conversions locally.
* **Favorites:** Allow users to mark frequently used units for quicker access.
* **Custom Units:** Allow advanced users to define their own units and factors (increases complexity significantly).
* **Themes:** Offer appearance customization (requires careful design).
* **Currency Conversion:** Add live currency rates (makes it L1.5, requires API integration, subscription key management, offline caching strategy).
* **iPad Layout:** Create a dedicated layout taking advantage of the larger screen.
* **watchOS App:** A companion app for quick conversions on the wrist.
* **Spotlight Integration:** Allow searching for conversions directly from iOS search.

## 18. Open Questions

* Final list of unit categories and units for v1.0? (Needs curation - balance comprehensiveness and simplicity).
* Specific visual design language/style guide? (Needs collaboration with a UI/UX designer).
* Exact formatting rules for large numbers and decimal precision?