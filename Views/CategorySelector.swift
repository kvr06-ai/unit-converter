import SwiftUI
import os.log

struct CategorySelector: View {
    @ObservedObject var viewModel: ConverterViewModel
    private let logger = Logger(subsystem: "com.converter.app", category: "CategorySelector")
    
    // Track if the group selector is expanded
    @State private var expandedGroup: String? = nil
    
    init(viewModel: ConverterViewModel) {
        self.viewModel = viewModel
        // Start with the first group expanded by default if available
        if let firstGroup = viewModel.categoryGroups.first {
            self._expandedGroup = State(initialValue: firstGroup.id)
        }
        logger.debug("CategorySelector initialized with \(viewModel.categories.count) categories in \(viewModel.categoryGroups.count) groups")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Group selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.categoryGroups) { group in
                        GroupButton(
                            groupName: group.name,
                            isSelected: expandedGroup == group.id,
                            action: {
                                withAnimation {
                                    expandedGroup = (expandedGroup == group.id) ? nil : group.id
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
            
            // Categories for the selected group
            if let expandedGroupId = expandedGroup,
               let selectedGroup = viewModel.categoryGroups.first(where: { $0.id == expandedGroupId }) {
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(selectedGroup.categories) { category in
                            CategoryButton(
                                category: category,
                                isSelected: viewModel.selectedCategory?.id == category.id,
                                action: {
                                    logger.debug("Category selected: \(category.name)")
                                    viewModel.selectedCategory = category
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

// Group selector button
struct GroupButton: View {
    let groupName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(groupName)
                .font(.system(size: 16, weight: .semibold))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// Separate component for category button to improve performance
struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: category.iconName)
                    .font(.system(size: 14))
                
                Text(category.name)
                    .font(.system(size: 15, weight: .medium))
            }
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