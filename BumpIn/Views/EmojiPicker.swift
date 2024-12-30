import SwiftUI

struct EmojiPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedEmoji: String
    @State private var tempEmoji: String = ""
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select a symbol:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                TextField("", text: $tempEmoji)
                    .font(.system(size: 50))
                    .frame(height: 60)
                    .multilineTextAlignment(.center)
                    .onChange(of: tempEmoji) { newValue in
                        if let firstEmoji = newValue.first {
                            tempEmoji = String(firstEmoji)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Select Symbol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if !tempEmoji.isEmpty {
                            selectedEmoji = tempEmoji
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                tempEmoji = selectedEmoji
            }
        }
    }
} 