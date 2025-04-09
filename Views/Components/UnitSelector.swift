import SwiftUI

struct UnitSelector: View {
    @Binding var selectedUnit: UnitDefinition
    let units: [UnitDefinition]
    let label: String
    let direction: ConversionDirection
    
    @State private var isShowingUnitSheet = false
    
    var body: some View {
        Button(action: {
            isShowingUnitSheet = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Text(selectedUnit.unitSymbol)
                                .font(.subheadline.bold())
                                .foregroundColor(.accentColor)
                            
                            Text(selectedUnit.unitName)
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: direction == .from ? "arrow.down" : "arrow.up")
                    .font(.caption2)
                    .foregroundColor(direction == .from ? .blue : .green)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color(direction == .from ? .systemBlue : .systemGreen).opacity(0.1))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isShowingUnitSheet) {
            UnitSelectionSheet(
                selectedUnit: $selectedUnit,
                units: units,
                title: "Select \(label)"
            )
        }
    }
}

struct UnitSelectionSheet: View {
    @Binding var selectedUnit: UnitDefinition
    let units: [UnitDefinition]
    let title: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(units) { unit in
                    Button(action: {
                        selectedUnit = unit
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(unit.unitName)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text(unit.unitSymbol)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color(.tertiarySystemBackground))
                                        )
                                }
                                
                                if let description = unit.description, !description.isEmpty {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            if unit.id == selectedUnit.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

enum ConversionDirection {
    case from
    case to
}

struct UnitSelector_Previews: PreviewProvider {
    static let sampleUnits: [UnitDefinition] = [
        UnitDefinition(unitName: "Meters", unitSymbol: "m", conversionFactor: 1.0, offset: nil, isBase: true, description: "Base unit of length in SI"),
        UnitDefinition(unitName: "Kilometers", unitSymbol: "km", conversionFactor: 1000.0, offset: nil, isBase: false, description: "1000 meters"),
        UnitDefinition(unitName: "Centimeters", unitSymbol: "cm", conversionFactor: 0.01, offset: nil, isBase: false, description: "0.01 meters"),
        UnitDefinition(unitName: "Millimeters", unitSymbol: "mm", conversionFactor: 0.001, offset: nil, isBase: false, description: "0.001 meters")
    ]
    
    static var previews: some View {
        VStack(spacing: 20) {
            UnitSelector(
                selectedUnit: .constant(sampleUnits[0]),
                units: sampleUnits,
                label: "From",
                direction: .from
            )
            
            UnitSelector(
                selectedUnit: .constant(sampleUnits[1]),
                units: sampleUnits,
                label: "To",
                direction: .to
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}