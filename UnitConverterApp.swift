// app-development/unit-converter/UnitConverterApp.swift
import SwiftUI
import os.log
import QuartzCore // For CACurrentMediaTime()

@main // Marks this struct as the entry point of the application
struct UnitConverterApp: App {
    // Logger instance
    private let logger = Logger(subsystem: "com.converter.app", category: "AppLaunch")
    
    // Store the timestamp when app is initialized
    private let launchStartTime = CACurrentMediaTime()
    
    var body: some Scene {
        WindowGroup {
            // The initial view to display when the app launches
            ConverterView()
                .onAppear {
                    // Calculate and log the time taken from app initialization until the first view appears
                    let launchDuration = CACurrentMediaTime() - launchStartTime
                    logger.debug("🚀 App launch time: \(String(format: "%.3f", launchDuration)) seconds")
                    
                    #if DEBUG
                    print("App launch completed in \(String(format: "%.3f", launchDuration)) seconds")
                    #endif
                }
        }
    }
} 