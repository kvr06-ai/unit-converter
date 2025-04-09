// app-development/unit-converter/Views/ConverterView.swift
import SwiftUI
import Combine // Needed for keyboard handling publisher and Publishers.Just
import os.log

struct ConverterView: View {
    // Logger for UI events and performance tracking
    private let logger = Logger(subsystem: "com.converter.app", category: "ConverterView")
    
    // Use @StateObject to create and keep the ViewModel alive for the lifetime of the view
    @StateObject private var viewModel = ConverterViewModel()
    @FocusState private var inputIsFocused: Bool // To control keyboard focus
    @State private var showCopied: Bool = false // For copy feedback animation
    @State private var showFeedbackAlert: Bool = false // Alert for when email can't be sent
    
    // Track when view appears for performance monitoring
    @State private var viewDidAppear = false

    var body: some View {
        NavigationView {
            // Replace Form with a VStack for more control over spacing
            VStack(spacing: 16) {                
                // Category selection with horizontal scrolling chips
                CategorySelector(viewModel: viewModel)
                    .padding(.horizontal)
                
                // Input section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Input")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 16) {
                        ZStack(alignment: .trailing) {
                            TextField("Enter a value", text: $viewModel.inputValueString)
                                .keyboardType(.decimalPad)
                                .focused($inputIsFocused) // Connect TextField to focus state
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .accessibilityLabel("Input value")
                                .onChange(of: inputIsFocused) { oldValue, newValue in
                                    logger.debug("Input field focus changed: \(newValue)")
                                }
                            
                            if !viewModel.inputValueString.isEmpty {
                                Button(action: {
                                    logger.debug("Clear input button tapped")
                                    viewModel.clearInput()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 16)
                                }
                                .transition(.opacity)
                                .animation(.easeInOut, value: !viewModel.inputValueString.isEmpty)
                                .accessibilityLabel("Clear input")
                            }
                        }
                        
                        HStack {
                            Picker("From Unit", selection: $viewModel.fromUnit) {
                                ForEach(viewModel.availableUnits) { unit in
                                    Text(unit.unitSymbol).tag(unit as UnitDefinition?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            
                            Spacer()
                            
                            Text(viewModel.fromUnit?.unitSymbol ?? "")
                                .foregroundColor(.gray)
                                .padding(.trailing, 8)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Visual conversion direction indicator - REMOVED BLUE ARROW
                // Now using empty space with padding to maintain layout spacing
                Spacer()
                    .frame(height: 16)
                
                // Output section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Output")
                        .font(.headline)
                        .foregroundColor(.gray)
                        
                    VStack(spacing: 16) {
                        ZStack(alignment: .trailing) {
                            Text(viewModel.outputValueString.isEmpty ? "Result will appear here" : viewModel.outputValueString)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .foregroundColor(viewModel.outputValueString.isEmpty ? .gray : .primary)
                            
                            if showCopied {
                                Text("Copied!")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                                    .padding(.trailing, 16)
                                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                            }
                        }
                        
                        HStack {
                            Picker("To Unit", selection: $viewModel.toUnit) {
                                ForEach(viewModel.availableUnits) { unit in
                                    Text(unit.unitSymbol).tag(unit as UnitDefinition?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            
                            Spacer()
                            
                            Text(viewModel.toUnit?.unitSymbol ?? "")
                                .foregroundColor(.gray)
                                .padding(.trailing, 8)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Swap Units button
                Button(action: {
                    logger.debug("Swap units button tapped")
                    viewModel.swapUnits()
                }) {
                    Label("Swap Units", systemImage: "arrow.left.arrow.right")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Copy button with animation feedback
                Button(action: {
                    logger.debug("Copy result button tapped")
                    UIPasteboard.general.string = viewModel.outputValueString
                    
                    // Show and hide the "Copied!" message
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showCopied = true
                    }
                    
                    // Provide haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // Auto-hide the copied message after 1.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            showCopied = false
                        }
                    }
                }) {
                    Label("Copy Result", systemImage: "doc.on.doc")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                .disabled(viewModel.outputValueString.isEmpty)
                .opacity(viewModel.outputValueString.isEmpty ? 0.5 : 1.0)
                .padding(.horizontal)
                
                // Feedback button
                Button(action: {
                    sendFeedback()
                }) {
                    HStack {
                        Image(systemName: "envelope")
                            .font(.caption)
                        Text("Send Feedback")
                            .font(.caption)
                    }
                    .padding(8)
                    .foregroundColor(.gray)
                }
                .padding(.top, 4)
                .alert("Cannot Send Email", isPresented: $showFeedbackAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Your device is not configured to send email. Please make sure you have the Mail app set up, or you can send feedback directly to fs.kvr06@gmail.com")
                }
                
                Spacer()
            }
            .navigationTitle("Unit Converter")
            // Apply the gesture recognizer to the entire navigation view content
            .contentShape(Rectangle())
            .onTapGesture {
                // Dismiss keyboard when tapping anywhere
                if inputIsFocused {
                    logger.debug("View tapped, dismissing keyboard")
                    inputIsFocused = false
                }
            }
            // Present the Unit Selection View as a sheet
            .sheet(isPresented: $viewModel.showingUnitSelector) {
                // Pass the necessary data and actions to the selection view
                UnitSelectionView(
                    allCategories: viewModel.unitCategories,
                    availableUnits: viewModel.availableUnits,
                    selectedCategory: viewModel.selectedUnitCategoryBinding(),
                    currentlySelectedUnit: viewModel.selectingForInput ? viewModel.fromUnit : viewModel.toUnit,
                    onUnitSelected: { selectedUnit in
                        viewModel.unitSelected(selectedUnit)
                    }
                )
            }
        } // End NavigationView
        .navigationViewStyle(.stack) // Use stack style for consistency on iPhone
        .onAppear {
            if !viewDidAppear {
                let startTime = Date()
                logger.debug("ConverterView appeared")
                viewDidAppear = true
                
                // Wait for UI to settle, then log performance
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let timeElapsed = Date().timeIntervalSince(startTime)
                    logger.debug("ConverterView fully rendered in \(timeElapsed) seconds")
                }
            }
        }
    }
    
    // Function to handle sending feedback via email
    private func sendFeedback() {
        logger.debug("Send feedback button tapped")
        
        // Device info for better feedback
        let device = UIDevice.current
        let systemVersion = device.systemVersion
        let model = device.model
        
        // Create email content
        let recipient = "fs.kvr06@gmail.com"
        let subject = "Unit Converter App Feedback"
        let body = "Hi,\n\nI'd like to provide feedback about the Unit Converter app.\n\n-- Please add your feedback here --\n\n\nDevice information:\n\(model) iOS \(systemVersion)"
        
        // URL encode components
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Create mailto URL
        let mailtoString = "mailto:\(recipient)?subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let mailtoURL = URL(string: mailtoString), UIApplication.shared.canOpenURL(mailtoURL) {
            UIApplication.shared.open(mailtoURL, options: [:], completionHandler: nil)
        } else {
            // Show alert if mail can't be sent (e.g., no mail account configured)
            showFeedbackAlert = true
        }
    }
}

// MARK: - Preview
#Preview { // Using the new #Preview macro
    ConverterView()
}

// Previous duplicate CategorySelector has been removed as it's now in its own file 