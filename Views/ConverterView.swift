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
    @State private var showFeedbackSheet: Bool = false // Show feedback form sheet
    @State private var showFeedbackThanks: Bool = false // Show thanks alert after submission
    @State private var showFeedbackError: Bool = false // Show error alert if submission fails
    
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
                
                // Feedback button - updated for in-app sheet
                Button(action: {
                    logger.debug("Feedback button tapped")
                    showFeedbackSheet = true
                }) {
                    HStack {
                        Image(systemName: "message")
                            .font(.caption)
                        Text("Send Feedback")
                            .font(.caption)
                    }
                    .padding(8)
                    .foregroundColor(.gray)
                }
                .padding(.top, 4)
                
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
            // Feedback submission sheet
            .sheet(isPresented: $showFeedbackSheet) {
                FeedbackFormView(isPresented: $showFeedbackSheet, showThanks: $showFeedbackThanks, showError: $showFeedbackError)
            }
            // Thanks alert
            .alert("Thank You", isPresented: $showFeedbackThanks) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your feedback has been sent. We appreciate your input!")
            }
            // Error alert
            .alert("Error Sending Feedback", isPresented: $showFeedbackError) {
                Button("Try Again", role: .cancel) {
                    showFeedbackSheet = true
                }
                Button("Cancel", role: .destructive) { }
            } message: {
                Text("There was a problem sending your feedback. Please try again later.")
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
}

// MARK: - Feedback Form View
struct FeedbackFormView: View {
    @Binding var isPresented: Bool
    @Binding var showThanks: Bool
    @Binding var showError: Bool
    
    @State private var feedback: String = ""
    @State private var emailAddress: String = ""
    @State private var isSubmitting: Bool = false
    @FocusState private var feedbackFieldFocused: Bool
    
    private let logger = Logger(subsystem: "com.converter.app", category: "FeedbackForm")
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Your Feedback")) {
                    TextEditor(text: $feedback)
                        .frame(height: 150)
                        .focused($feedbackFieldFocused)
                        .onChange(of: feedback) { _, _ in
                            // Automatically grow the field if needed
                            // Additional handling could be added here
                        }
                }
                
                Section(header: Text("Your Email (Optional)"), footer: Text("We'll only use this to follow up on your feedback if needed.")) {
                    TextField("email@example.com", text: $emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled(true)
                }
                
                Section {
                    Button(action: {
                        submitFeedback()
                    }) {
                        if isSubmitting {
                            HStack {
                                Text("Sending...")
                                Spacer()
                                ProgressView()
                            }
                        } else {
                            Text("Submit Feedback")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .bold()
                        }
                    }
                    .disabled(feedback.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                // Automatically focus the feedback field when the sheet appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    feedbackFieldFocused = true
                }
            }
        }
    }
    
    private func submitFeedback() {
        logger.debug("Submitting feedback")
        isSubmitting = true
        
        // Get device info
        let device = UIDevice.current
        let deviceInfo = "\(device.model) iOS \(device.systemVersion)"
        
        // Create request to Formspree with the user's actual form endpoint
        guard let url = URL(string: "https://formspree.io/f/mrbprzwk") else {
            handleSubmissionError()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the form data - Formspree will forward this to your email
        let formData: [String: String] = [
            "feedback": feedback,
            "email": emailAddress,
            "device": deviceInfo,
            "_subject": "Unit Converter App Feedback",
            "_replyto": emailAddress.isEmpty ? "No email provided" : emailAddress
        ]
        
        // Serialize to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: formData)
        } catch {
            logger.error("Error serializing feedback: \(error.localizedDescription)")
            handleSubmissionError()
            return
        }
        
        // Make the actual network request
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if let error = error {
                    logger.error("Network error: \(error.localizedDescription)")
                    handleSubmissionError()
                    return
                }
                
                // Check for successful response
                if let httpResponse = response as? HTTPURLResponse, 
                   (200...299).contains(httpResponse.statusCode) {
                    // Success
                    isPresented = false
                    
                    // Show thanks message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showThanks = true
                    }
                    
                    logger.debug("Feedback sent successfully")
                } else {
                    // Server returned an error
                    logger.error("Server error: \(String(describing: response))")
                    handleSubmissionError()
                }
            }
        }.resume()
    }
    
    private func handleSubmissionError() {
        isSubmitting = false
        isPresented = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showError = true
        }
    }
}

// MARK: - Preview
#Preview { // Using the new #Preview macro
    ConverterView()
}

// Previous duplicate CategorySelector has been removed as it's now in its own file 