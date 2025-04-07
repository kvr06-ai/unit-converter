// app-development/unit-converter/Views/ConverterView.swift
import SwiftUI
import Combine // Needed for keyboard handling publisher

struct ConverterView: View {
    // Use @StateObject to create and keep the ViewModel alive for the lifetime of the view
    @StateObject private var viewModel = ConverterViewModel()
    @FocusState private var inputIsFocused: Bool // To control keyboard focus

    var body: some View {
        NavigationView { // Embed in NavigationView for title and potential future navigation
            Form { // Using Form for standard iOS styling and spacing
                // MARK: - Category Selection
                Section(header: Text("Category")) {
                    Picker("Select Category", selection: $viewModel.selectedCategory) {
                        ForEach(viewModel.allCategories) { category in
                            Text(category.categoryName).tag(category as UnitCategory?) // Tag must match selection type
                        }
                    }
                    .pickerStyle(.menu) // Or .automatic, .inline etc.
                    .labelsHidden() // Hide the "Select Category" label visually
                }

                // MARK: - Input Section
                Section(header: Text("From")) {
                    HStack {
                        TextField("Enter value", text: $viewModel.inputValueString)
                            .font(.system(size: 24, weight: .regular)) // Larger font for value
                            .keyboardType(.decimalPad)
                            .focused($inputIsFocused)
                            .toolbar { // Add toolbar for Done button
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer() // Push button to the right
                                    Button("Done") {
                                        inputIsFocused = false // Dismiss keyboard
                                    }
                                }
                            }
                            .accessibilityLabel("Input value")


                        Spacer() // Pushes unit selector to the right

                        Button {
                            viewModel.unitSelectorTapped(isInput: true)
                        } label: {
                            VStack(alignment: .trailing) {
                                Text(viewModel.selectedInputUnit?.unitName ?? "Select Unit")
                                    .font(.headline)
                                Text(viewModel.selectedInputUnit?.unitSymbol ?? "-")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain) // Use plain style to avoid default button appearance in Form
                        .accessibilityLabel("Select input unit")
                        .accessibilityHint("Opens the unit selection screen")

                    }
                     // Clear Button (Optional, could be integrated differently)
                     if !viewModel.inputValueString.isEmpty {
                         HStack {
                              Spacer()
                              Button("Clear") {
                                  viewModel.clearInput()
                              }
                              .buttonStyle(.borderless) // Less prominent style
                              .foregroundColor(.red)
                         }
                     }
                }

                // MARK: - Swap Button
                HStack {
                   Spacer()
                   Button {
                       viewModel.swapUnits()
                       // Optionally provide haptic feedback
                       #if canImport(UIKit)
                       UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                       #endif
                   } label: {
                       Image(systemName: "arrow.up.arrow.down.circle.fill")
                           .font(.title)
                           .foregroundColor(.accentColor) // Use theme color
                   }
                   .accessibilityLabel("Swap input and output units")
                   Spacer()
                }
                .padding(.vertical, -5) // Adjust spacing around swap button


                // MARK: - Output Section
                Section(header: Text("To")) {
                     HStack {
                        // Use Text for output as it's not directly editable
                        Text(viewModel.outputValueString.isEmpty ? " " : viewModel.outputValueString) // Show space if empty to maintain height
                            .font(.system(size: 24, weight: .bold))
                            .lineLimit(1)
                             .minimumScaleFactor(0.5) // Allow text to shrink if needed
                             .frame(maxWidth: .infinity, alignment: .leading) // Take available width
                            .contentTransition(.numericText(countsDown: false)) // Animate changes smoothly
                             .animation(.easeInOut, value: viewModel.outputValueString)
                             .accessibilityLabel("Output value")
                             .accessibilityValue(viewModel.outputValueString)


                        Spacer() // Pushes unit selector to the right

                         Button {
                             viewModel.unitSelectorTapped(isInput: false)
                         } label: {
                             VStack(alignment: .trailing) {
                                 Text(viewModel.selectedOutputUnit?.unitName ?? "Select Unit")
                                     .font(.headline)
                                 Text(viewModel.selectedOutputUnit?.unitSymbol ?? "-")
                                     .font(.subheadline)
                                     .foregroundColor(.secondary)
                             }
                            .padding(.vertical, 4)
                         }
                         .buttonStyle(.plain)
                         .accessibilityLabel("Select output unit")
                         .accessibilityHint("Opens the unit selection screen")
                     }
                     // Copy Button (Integrated with output text)
                     .contentShape(Rectangle()) // Make HStack tappable
                     .onTapGesture {
                        // Simple tap-to-copy for output
                         #if canImport(UIKit)
                         if !viewModel.outputValueString.isEmpty && viewModel.outputValueString != "Error" {
                             UIPasteboard.general.string = viewModel.outputValueString
                             // Optional: Show brief confirmation like a subtle overlay or haptic feedback
                             UINotificationFeedbackGenerator().notificationOccurred(.success)
                         }
                         #endif
                     }
                     .accessibilityHint("Tap to copy output value")

                }


            } // End Form
            .navigationTitle("Unit Converter")
            // Present the Unit Selection View as a sheet
            .sheet(isPresented: $viewModel.showingUnitSelector) {
                // Pass the necessary data and actions to the selection view
                UnitSelectionView(
                    allCategories: viewModel.allCategories,
                    availableUnits: viewModel.availableUnits,
                    selectedCategory: $viewModel.selectedCategory, // Binding for category changes
                    currentlySelectedUnit: viewModel.selectingForInput ? viewModel.selectedInputUnit : viewModel.selectedOutputUnit,
                    onUnitSelected: { selectedUnit in
                        viewModel.unitSelected(selectedUnit)
                    }
                )
                 // Consider presentation detents for more flexible sheet height on iOS 16+
                 // .presentationDetents([.medium, .large])
            }
            // Dismiss keyboard when tapping outside the TextField
             .onTapGesture {
                 inputIsFocused = false
             }

        } // End NavigationView
        .navigationViewStyle(.stack) // Use stack style for consistency on iPhone

    }
}

// MARK: - Preview
#Preview { // Using the new #Preview macro
    ConverterView()
} 