# Unit Converter iOS App

[![Swift Version](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![Platform](https://img.shields.io/badge/Platform-iOS%2016.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM-green.svg)](#architecture)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

A powerful, intuitive unit conversion app designed to simplify your daily calculations with a clean, modern interface.

## ✨ What Makes This App Special

- **Organized Unit Groups**: Units are logically arranged in groups (Basic, Science, Misc) for faster, more intuitive navigation
- **Multi-Unit Results View**: See conversions to ALL units in a category at once - save time and avoid switching back and forth
- **Rich Unit Descriptions**: Learn what each unit actually represents with detailed descriptions
- **Smart Conversion Engine**: Special handling for temperature units and inverse conversions (like L/100km)
- **Remember Your Preferences**: The app remembers your most recently used categories and units

## 📱 Screenshots

<div align="center">
  <p>
    <img src="Demo screenshots/IMG_0492.PNG" width="200" alt="Main Conversion Screen"/>
    <img src="Demo screenshots/IMG_0493.PNG" width="200" alt="Multi-unit Results View"/>
    <img src="Demo screenshots/IMG_0494.PNG" width="200" alt="Category Selection"/>
    <img src="Demo screenshots/IMG_0495.PNG" width="200" alt="Unit Selection with Descriptions"/>
  </p>
</div>

## 🎯 User Benefits

### Save Time
- **Quick Category Navigation**: Find units faster with our intuitive category groups
- **See All Results at Once**: No more switching between units - see all possible conversions with one tap
- **Instant Calculations**: Results update in real-time as you type

### Improve Understanding
- **Learn About Units**: Each unit includes a helpful description
- **Clear Visual Hierarchy**: Clean design helps you focus on what matters
- **Intuitive Controls**: Easily swap units, copy results, and navigate between categories

### Enhanced Functionality
- **Comprehensive Coverage**: Convert between units across multiple categories
- **Special Conversion Types**: Proper handling of temperature and inverse units
- **Smart Memory**: The app remembers your preferences for a more personalized experience

## 📊 Supported Categories

This app supports a wide range of unit categories to cover your everyday needs:

- **Measurement**
  - Length
  - Mass/Weight
  - Volume
  - Area
  - Temperature
  
- **Time & Speed**
  - Time
  - Speed
  - Acceleration
  
- **Technical Units**
  - Data Storage
  - Energy
  - Power
  - Pressure
  - Fuel Economy

## 🔍 How It Works

1. **Select a Category Group**: Choose from Basic, Science, or Misc
2. **Pick a Category**: Select from options like Length, Temperature, etc.
3. **Enter Your Value**: Type in the number you want to convert
4. **View the Result**: See the converted value instantly
5. **Explore All Conversions**: Tap "View All Results" to see all possible conversions

## ⚙️ Technology & Architecture

This app follows the **Model-View-ViewModel (MVVM)** design pattern:

- **Built with SwiftUI**: Modern, declarative UI framework from Apple
- **Clean Architecture**: Separation of concerns for better maintainability
- **JSON Data Structure**: Easily extensible unit definitions
- **Combine Framework**: Reactive updates for a responsive experience

## 🚀 Future Enhancements

- History tracking of recent conversions
- Favorite units for quick access
- Custom unit creation
- Dark mode and theme options
- Live currency conversion with API integration (current version includes static reference rates)
- iPad-optimized layout
- watchOS companion app

## 💱 Currency Conversion

The app includes currency conversion functionality with a practical approach:

- **Comprehensive Coverage**: Conversion between major world currencies
- **Reference Rates**: Well-documented static conversion rates with source information
- **Works Offline**: No internet connection required for conversions
- **Clear Timestamps**: All rates include "as of [date]" information
- **Intuitive Interface**: Currencies organized by region with symbols and flags

*Note: Future versions will include live API-based rates while maintaining offline functionality*

## 🧑‍💻 Development

### Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/kvr06-ai/unit-converter.git
   cd unit-converter
   ```
2. **Open in Xcode:** Open the `UnitConverter.xcodeproj` file
3. **Build & Run:** Select an iOS Simulator or connect a device and run the app (Cmd+R)

### Project Structure

- **Models**: Unit definitions, categories, and conversion logic
- **Views**: SwiftUI interface components
- **ViewModels**: State management and business logic
- **Resources**: JSON data files and assets

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

<div align="center">
  <p><em>Need a fast, intuitive unit converter? Download today!</em></p>
</div> 