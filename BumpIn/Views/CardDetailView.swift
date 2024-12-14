import SwiftUI

struct CardDetailView: View {
    let card: BusinessCard
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    BusinessCardPreview(card: card, showFull: true)
                        .padding()
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Section("Actions") {
                            ShareLink(
                                item: """
                                    Contact Card:
                                    \(card.name)
                                    \(card.title)
                                    \(card.company)
                                    \(card.email)
                                    \(card.phone)
                                    \(card.linkedin)
                                    \(card.website)
                                    """,
                                subject: Text("Business Card - \(card.name)"),
                                message: Text("Here's my business card!")
                            ) {
                                Label("Share Card", systemImage: "square.and.arrow.up")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [card.colorScheme.primary, card.colorScheme.secondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Your Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 