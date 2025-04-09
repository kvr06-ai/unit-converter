import SwiftUI

struct CategorySelectorComponent: View {
    @Binding var selectedCategory: UnitCategory
    let categories: [UnitCategory]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories) { category in
                    Button(action: {
                        withAnimation {
                            selectedCategory = category
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: categoryIcon(for: category))
                                .font(.subheadline)
                            
                            Text(category.categoryName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedCategory.id == category.id 
                                      ? Color.accentColor 
                                      : Color(.secondarySystemBackground))
                        )
                        .foregroundColor(selectedCategory.id == category.id 
                                        ? .white 
                                        : .primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Helper function to get icon for category
    private func categoryIcon(for category: UnitCategory) -> String {
        switch category.categoryName {
        case "Length":
            return "ruler"
        case "Mass":
            return "scalemass"
        case "Volume":
            return "cup.and.saucer"
        case "Temperature":
            return "thermometer"
        case "Time":
            return "clock"
        case "Speed":
            return "speedometer"
        case "Area":
            return "square.grid.2x2"
        case "Fuel Efficiency":
            return "fuelpump"
        case "Currency":
            return "dollarsign.circle"
        case "Data Storage":
            return "externaldrive"
        case "Energy":
            return "bolt"
        case "Power":
            return "bolt.fill"
        default:
            return "questionmark.circle"
        }
    }
}

struct CategorySelectorComponent_Previews: PreviewProvider {
    static var previews: some View {
        CategorySelectorComponent(
            selectedCategory: .constant(UnitCategory(categoryName: "Length", units: [])),
            categories: [
                UnitCategory(categoryName: "Length", units: []),
                UnitCategory(categoryName: "Mass", units: []),
                UnitCategory(categoryName: "Volume", units: []),
                UnitCategory(categoryName: "Temperature", units: [])
            ]
        )
        .previewLayout(.sizeThatFits)
        .padding(.vertical)
    }
} 