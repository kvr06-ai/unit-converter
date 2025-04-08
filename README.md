# Unit Converter iOS App

[![Swift Version](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![Platform](https://img.shields.io/badge/Platform-iOS%2016.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM-green.svg)](#architecture)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE) <!-- Optional: Add a LICENSE file -->

A simple and fast unit conversion utility designed for iOS, built purely with SwiftUI.

## Features (v1.0)

*   **Wide Range of Categories:** Convert between common units for:
    *   Length
    *   Mass
    *   Temperature (Celsius, Fahrenheit, Kelvin)
    *   Volume
    *   Speed
    *   *(More categories like Area, Time, Data Storage can be easily added)*
*   **Instant Results:** Output updates automatically as you type or change units.
*   **Easy Unit Selection:** Tap to select input/output units from the current category via a searchable sheet.
*   **Category Switching:** Quickly switch between unit categories (e.g., Length to Mass) using a dropdown menu.
*   **Swap Units:** Instantly swap the 'From' and 'To' units with a single tap.
*   **Clear Input:** Easily clear the current input value.
*   **Tap-to-Copy:** Tap the output value to copy it to the clipboard.
*   **State Persistence:** Remembers the last used category and units for convenience (`UserDefaults`).
*   **Decimal Pad:** Uses the appropriate keyboard for numeric input.

## Screenshots (Conceptual)

*(Add screenshots here once the UI is visually complete)*

*   *Main conversion screen showing input/output.*
*   *Unit selection sheet showing searchable units for a category.*

## Architecture

This app follows the **Model-View-ViewModel (MVVM)** design pattern:

*   **Model:** Represents the data and business logic.
    *   `UnitDefinition.swift`: Defines a single unit (name, symbol, factor, offset).
    *   `UnitCategory.swift`: Defines a category containing multiple `UnitDefinition`s.
    *   `Units.json`: Data file storing all categories and units, bundled with the app.
    *   `UnitDataStore.swift`: Singleton responsible for loading and providing access to the unit data from `Units.json`.
    *   `ConversionEngine.swift`: Struct containing the core logic for performing conversions, including special handling for temperature.
*   **View:** Represents the UI elements (SwiftUI Views).
    *   `ConverterView.swift`: The main screen displaying input/output panels, category picker, unit selectors, and action buttons.
    *   `UnitSelectionView.swift`: A modal sheet view for selecting categories and units, including search functionality.
*   **ViewModel:** Acts as the intermediary between Model and View.
    *   `ConverterViewModel.swift`: An `ObservableObject` that holds the state for `ConverterView` (input/output values, selected units/category), handles user actions, interacts with `ConversionEngine` and `UnitDataStore`, and manages saving/loading preferences via `UserDefaults`.

## Technology Stack

*   **Language:** Swift (latest stable)
*   **UI Framework:** SwiftUI
*   **Architecture:** MVVM
*   **Data Persistence:** Bundled JSON (`Units.json`), `UserDefaults`
*   **Concurrency:** Combine (for `@Published` state), `@MainActor`

## Getting Started

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/kvr06-ai/unit-converter.git
    cd unit-converter
    ```
2.  **Open in Xcode:** Open the `UnitConverter.xcodeproj` file (You will need to create this project file first in the `app-development/unit-converter` directory and add all the generated Swift files, `Units.json`, and the directory structure).
3.  **Build & Run:** Select an iOS Simulator or connect a device and run the app (Cmd+R).

## Future Enhancements (Post v1.0)

*   History tracking
*   Favorite units
*   Custom unit creation
*   Themes/Appearance settings
*   Currency conversion (requires network access)
*   iPad-specific layout
*   watchOS companion app

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an Issue. (Optional: Add specific contribution guidelines if desired).

## License

This project is licensed under the MIT License - see the LICENSE file for details (Optional: Create a LICENSE file). 
