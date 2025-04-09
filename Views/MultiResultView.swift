import SwiftUI
import os.log

struct MultiResultView: View {
    let results: [ConversionResult]
    let inputValue: String
    let inputUnit: UnitDefinition?
    @Environment(\.dismiss) var dismiss
    
    private let logger = Logger(subsystem: "com.converter.app", category: "MultiResultView")
    
    var body: some View {
        NavigationView {
            List {
                if let inputUnit = inputUnit, !inputValue.isEmpty, let inputValueDouble = Double(inputValue) {
                    Section(header: Text("Input Value")) {
                        HStack {
                            Text(inputValue)
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(inputUnit.unitSymbol)
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                        }
                        .padding(.vertical, 4)
                        
                        if let description = inputUnit.description, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Results")) {
                    ForEach(results, id: \.unit.id) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(result.formattedValue)
                                    .font(.system(.body, design: .monospaced))
                                
                                Spacer()
                                
                                Text(result.unit.unitSymbol)
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.accentColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(.tertiarySystemBackground))
                                    )
                            }
                            
                            Text(result.unit.unitName)
                                .font(.callout)
                            
                            if let description = result.unit.description, !description.isEmpty {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            UIPasteboard.general.string = result.formattedValue
                            logger.debug("Copied value: \(result.formattedValue)")
                            
                            // Provide haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("All Conversions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MultiResultView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleUnit = UnitDefinition(
            unitName: "Meters",
            unitSymbol: "m",
            conversionFactor: 1.0,
            offset: nil,
            isBase: true,
            description: "The base unit of length in the SI system",
            isInverse: false
        )
        
        let sampleResults: [ConversionResult] = [
            ConversionResult(value: 1.0, unit: sampleUnit),
            ConversionResult(value: 1000.0, unit: UnitDefinition(
                unitName: "Kilometers",
                unitSymbol: "km",
                conversionFactor: 1000.0,
                offset: nil,
                isBase: false,
                description: "One thousand meters",
                isInverse: false
            )),
            ConversionResult(value: 0.001, unit: UnitDefinition(
                unitName: "Millimeters",
                unitSymbol: "mm",
                conversionFactor: 0.001,
                offset: nil,
                isBase: false,
                description: "One thousandth of a meter",
                isInverse: false
            ))
        ]
        
        MultiResultView(
            results: sampleResults,
            inputValue: "1.0",
            inputUnit: sampleUnit
        )
    }
} 