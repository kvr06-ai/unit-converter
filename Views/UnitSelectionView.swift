// app-development/unit-converter/Views/UnitSelectionView.swift
import SwiftUI

struct UnitSelectionView: View {
    // MARK: - Environment & State
    @Environment(\.dismiss) var dismiss // Action to dismiss the sheet
    @State private var searchText = "" // State for the search bar text

    // MARK: - Passed Properties
    let allCategories: [UnitCategory]
    let availableUnits: [UnitDefinition] // Units for the *currently selected* category in ConverterViewModel
    @Binding var selectedCategory: UnitCategory? // Binding to update the category in ConverterViewModel
    let currentlySelectedUnit: UnitDefinition? // The unit currently active (input or output)
    let onUnitSelected: (UnitDefinition) -> Void // Closure to execute when a unit is tapped

    // MARK: - Computed Properties
    private var searchResults: [UnitDefinition] {
        if searchText.isEmpty {
            return availableUnits // No filter applied
        } else {
            // Filter units by name or symbol, case-insensitively
            return availableUnits.filter { unit in
                unit.unitName.localizedCaseInsensitiveContains(searchText) ||
                unit.unitSymbol.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView { // Embed in NavigationView for title, search bar, and dismiss button
            VStack(spacing: 0) { // Use VStack to combine Picker and List
                // MARK: - Category Picker
                 // Placed outside the List to always be visible
                 Picker("Category", selection: $selectedCategory) {
                      Text("Select Category...").tag(nil as UnitCategory?) // Optional placeholder
                     ForEach(allCategories) { category in
                         Text(category.categoryName).tag(category as UnitCategory?)
                     }
                 }
                 .pickerStyle(.menu) // Or .segmented for fewer categories
                 .padding(.horizontal)
                 .padding(.bottom, 5)
                 .onChange(of: selectedCategory) { _ in
                     // Reset search when category changes
                     searchText = ""
                 }


                // MARK: - Unit List
                List(searchResults) { unit in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(unit.unitName)
                                .font(.headline)
                            Text(unit.unitSymbol)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        // Show checkmark for the currently selected unit in the main view
                        if unit.id == currentlySelectedUnit?.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle()) // Make the whole row tappable
                    .onTapGesture {
                        onUnitSelected(unit) // Call the closure with the selected unit
                        // dismiss() // Dismissal is handled by showingUnitSelector=false in ViewModel
                    }
                }
                .listStyle(.plain) // Use plain style, Form adds its own styling

            } // End VStack
            .navigationTitle("Select Unit")
            .navigationBarTitleDisplayMode(.inline) // Keep title small
            .toolbar {
                // Add a Done/Dismiss button explicitly if needed (though swipe down works)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss() // Dismiss the sheet
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Units") // Add search bar

        } // End NavigationView
    }
}

// MARK: - Preview
// Create mock data for previewing UnitSelectionView
struct UnitSelectionView_Previews: PreviewProvider {
    // Sample data for preview
    static let previewCategories: [UnitCategory] = UnitDataStore.shared.categories // Use real data store for preview
    @State static var previewSelectedCategory: UnitCategory? = previewCategories.first // Start with Length selected
    static let previewAvailableUnits: [UnitDefinition] = previewSelectedCategory?.units ?? []
    static let previewSelectedUnit: UnitDefinition? = previewAvailableUnits.first // Meter

    static var previews: some View {
        // Ensure selectedCategory has a value for the preview list to populate
        // This setup can be tricky, might need refinement based on exact interaction.
         // If previewSelectedCategory starts as nil, the list might be empty initially.
        if previewSelectedCategory == nil && !previewCategories.isEmpty {
             // Initialize category for preview if needed
             previewSelectedCategory = previewCategories.first
        }


        UnitSelectionView(
            allCategories: previewCategories,
            availableUnits: previewSelectedCategory?.units ?? [], // Dynamically update based on picker
            selectedCategory: $previewSelectedCategory, // Pass the binding
            currentlySelectedUnit: previewSelectedUnit,
            onUnitSelected: { selectedUnit in
                print("Preview: Unit selected - \(selectedUnit.unitName)")
            }
        )
    }
} 