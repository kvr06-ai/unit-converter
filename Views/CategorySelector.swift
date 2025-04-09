import SwiftUI
import os.log

struct CategorySelector: View {
    @ObservedObject var viewModel: ConverterViewModel
    private let logger = Logger(subsystem: "com.converter.app", category: "CategorySelector")
    
    // Cache the list of categories to avoid recomputation
    private let categories: [Category]
    
    init(viewModel: ConverterViewModel) {
        self.viewModel = viewModel
        self.categories = viewModel.categories
        logger.debug("CategorySelector initialized with \(categories.count) categories")
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(categories) { category in
                    let categoryId = category.id
                    let categoryName = category.name
                    
                    CategoryButton(
                        category: category,
                        isSelected: viewModel.selectedCategory?.id == categoryId,
                        action: {
                            logger.debug("Category selected: \(categoryName)")
                            viewModel.selectedCategory = category
                        }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// Separate component for category button to improve performance
struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.name)
                .font(.system(size: 15, weight: .medium))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.15))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
} 