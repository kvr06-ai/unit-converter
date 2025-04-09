import SwiftUI

struct ValueInput: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    let isOutput: Bool
    let hasFocus: Bool
    
    @State private var showCopiedIndicator = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                if isOutput {
                    Text(text.isEmpty ? placeholder : text)
                        .font(.title2)
                        .foregroundColor(text.isEmpty ? .gray.opacity(0.5) : .primary)
                        .frame(minHeight: 36)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !text.isEmpty {
                                copyToClipboard()
                            }
                        }
                } else {
                    TextField(placeholder, text: $text)
                        .font(.title2)
                        .keyboardType(.decimalPad)
                        .frame(minHeight: 36)
                }
                
                Spacer()
                
                if isOutput && !text.isEmpty {
                    Button(action: copyToClipboard) {
                        Image(systemName: showCopiedIndicator ? "checkmark" : "doc.on.doc")
                            .foregroundColor(showCopiedIndicator ? .green : .gray)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if !isOutput && !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(hasFocus ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: hasFocus ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
            )
        }
    }
    
    private func copyToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
        
        withAnimation {
            showCopiedIndicator = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopiedIndicator = false
            }
        }
    }
}

struct ValueInput_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ValueInput(
                label: "From",
                text: .constant("123.45"),
                placeholder: "Enter value",
                isOutput: false,
                hasFocus: true
            )
            
            ValueInput(
                label: "Result",
                text: .constant("678.90"),
                placeholder: "Result will appear here",
                isOutput: true,
                hasFocus: false
            )
            
            ValueInput(
                label: "Empty Input",
                text: .constant(""),
                placeholder: "Enter a value",
                isOutput: false,
                hasFocus: false
            )
            
            ValueInput(
                label: "Empty Output",
                text: .constant(""),
                placeholder: "Result will appear here",
                isOutput: true,
                hasFocus: false
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 