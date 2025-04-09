import Foundation
import os.log

struct ConversionEngine {
    // Logger instance for tracking conversion operations
    private let logger = Logger(subsystem: "com.converter.app", category: "ConversionEngine")

    // Handles standard conversions (Length, Mass, Volume, Speed, etc.)
    private func performStandardConversion(value: Double, from inputUnit: UnitDefinition, to outputUnit: UnitDefinition) -> Double {
        let startTime = Date()
        logger.debug("Standard conversion: \(value) from \(inputUnit.unitName) to \(outputUnit.unitName)")
        
        // Convert input value to the base unit value
        let baseValue = value * inputUnit.conversionFactor
        logger.debug("Base value (in \(inputUnit.isBase == true ? "base unit" : "converted to base"): \(baseValue)")
        
        // Convert base unit value to the output unit value
        // Avoid division by zero, though factors should not be zero
        guard outputUnit.conversionFactor != 0 else { 
            logger.error("Zero conversion factor for \(outputUnit.unitName)")
            return Double.nan // Not a Number indicates error
        }
        
        let outputValue = baseValue / outputUnit.conversionFactor
        logger.debug("Output value: \(outputValue)")
        
        let timeElapsed = Date().timeIntervalSince(startTime)
        logger.debug("Standard conversion completed in \(timeElapsed) seconds")
        
        return outputValue
    }

    // Handles temperature conversions specifically
    private func performTemperatureConversion(value: Double, from inputUnit: UnitDefinition, to outputUnit: UnitDefinition) -> Double? {
        let startTime = Date()
        logger.debug("Temperature conversion: \(value) from \(inputUnit.unitName) to \(outputUnit.unitName)")
        
        // Ensure both units have offset values, indicating they are temperature units
        guard let inputOffset = inputUnit.offset, let outputOffset = outputUnit.offset else {
            logger.error("Temperature conversion attempted on non-temperature units")
            return nil // Should not happen if category check is done beforehand
        }

        // Strategy: Convert input temperature TO Celsius (our intermediate 'base' for temperature)
        // Formula: Celsius = (Value + Offset_Input) * Factor_Input
        let valueInCelsius = (value + inputOffset) * inputUnit.conversionFactor
        logger.debug("Value in Celsius: \(valueInCelsius)")

        // Now, convert Celsius TO the target output unit
        // Formula: OutputValue = (Celsius / Factor_Output) - Offset_Output
        guard outputUnit.conversionFactor != 0 else { 
            logger.error("Zero conversion factor for \(outputUnit.unitName)")
            return Double.nan 
        }
        
        let outputValue = (valueInCelsius / outputUnit.conversionFactor) - outputOffset
        logger.debug("Output value: \(outputValue)")
        
        let timeElapsed = Date().timeIntervalSince(startTime)
        logger.debug("Temperature conversion completed in \(timeElapsed) seconds")

        return outputValue
    }

    // Public conversion function
    func convert(value: Double, from inputUnit: UnitDefinition, to outputUnit: UnitDefinition) -> Double? {
        let startTime = Date()
        logger.debug("Beginning conversion from \(inputUnit.unitName) to \(outputUnit.unitName)")
        
        // Basic validation: Ensure units are compatible (implicitly done by ViewModel ensuring they are from the same category)
        // We rely on the ViewModel selecting units from the same category.

        var result: Double?
        
        // Check if it's a temperature conversion
        if inputUnit.isTemperature {
            // Ensure the output unit is also a temperature unit
            guard outputUnit.isTemperature else {
                logger.error("Cannot convert between temperature and non-temperature units")
                return nil // Invalid conversion attempt
            }
            result = performTemperatureConversion(value: value, from: inputUnit, to: outputUnit)
        } else {
            // Ensure output unit is NOT a temperature unit if input isn't
            guard !outputUnit.isTemperature else {
                logger.error("Cannot convert between non-temperature and temperature units")
                return nil // Invalid conversion attempt
            }
            // Perform standard conversion for non-temperature units
            result = performStandardConversion(value: value, from: inputUnit, to: outputUnit)
        }
        
        let timeElapsed = Date().timeIntervalSince(startTime)
        logger.debug("Total conversion completed in \(timeElapsed) seconds")
        
        return result
    }
} 