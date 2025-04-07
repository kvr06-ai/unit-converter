// app-development/unit-converter/UnitConverterApp.swift
import SwiftUI

@main // Marks this struct as the entry point of the application
struct UnitConverterApp: App {
    var body: some Scene {
        WindowGroup {
            // The initial view to display when the app launches
            ConverterView()
        }
    }
} 