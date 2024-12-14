import SwiftUI

struct CardDetailView: View {
    let card: BusinessCard
    let selectedImage: UIImage?
    @State private var showFullScreen = false
    @State private var isFlipped = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var animation
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Card preview with full screen button
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        // Front of card
                        BusinessCardPreview(card: card, showFull: true, selectedImage: selectedImage)
                            .frame(height: 220)
                            .opacity(isFlipped ? 0 : 1)
                            .scaleEffect(isFlipped ? 0.9 : 1)
                            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(!isFlipped ?
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let delta = value / lastScale
                                            lastScale = value
                                            scale = min(max(scale * delta, 1), 4)
                                        }
                                        .onEnded { _ in
                                            lastScale = 1.0
                                        },
                                    DragGesture()
                                        .onChanged { value in
                                            if scale > 1 {
                                                offset = CGSize(
                                                    width: lastOffset.width + value.translation.width,
                                                    height: lastOffset.height + value.translation.height
                                                )
                                            }
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                            if scale <= 1 {
                                                withAnimation {
                                                    offset = .zero
                                                    lastOffset = .zero
                                                }
                                            }
                                        }
                                ) : nil
                            )
                            .gesture(!isFlipped ?
                                TapGesture(count: 2)
                                    .onEnded {
                                        withAnimation {
                                            if scale > 1 {
                                                scale = 1
                                                offset = .zero
                                                lastOffset = .zero
                                            } else {
                                                scale = 2
                                            }
                                        }
                                    } : nil
                            )
                        
                        // Back of card (About Me)
                        if !card.aboutMe.isEmpty {
                            VStack(spacing: 8) {
                                Text(card.aboutMe)
                                    .font(card.fontStyle.bodyFont)
                                    .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                                    .lineSpacing(4)
                                    .multilineTextAlignment(.leading)
                                    .padding(24)
                            }
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .background(card.colorScheme.backgroundView(style: card.backgroundStyle))
                            .cornerRadius(16)
                            .opacity(isFlipped ? 1 : 0)
                            .scaleEffect(isFlipped ? 1 : 0.9)
                            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                        }
                    }
                    .padding(.horizontal)
                    .onTapGesture {
                        if !card.aboutMe.isEmpty && scale <= 1 {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isFlipped.toggle()
                                // Reset zoom when flipping
                                scale = 1
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                    }
                    
                    Button(action: { showFullScreen = true }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.5))
                            .font(.system(size: 18))
                            .padding(8)
                            .background(colorScheme == .dark ? Color(uiColor: .systemGray6) : .white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4)
                    }
                    .padding()
                }
                
                // Contact Information Boxes
                VStack(spacing: 16) {
                    if !card.aboutMe.isEmpty {
                        InfoBox(
                            title: "About",
                            content: card.aboutMe,
                            icon: "person.text.rectangle.fill",
                            color: card.colorScheme.primary
                        )
                    }
                    
                    if !card.email.isEmpty {
                        InfoBox(
                            title: "Email",
                            content: card.email,
                            icon: "envelope.fill",
                            color: card.colorScheme.primary
                        )
                    }
                    
                    if !card.phone.isEmpty {
                        InfoBox(
                            title: "Phone",
                            content: card.phone,
                            icon: "phone.fill",
                            color: card.colorScheme.primary
                        )
                    }
                    
                    if !card.linkedin.isEmpty {
                        InfoBox(
                            title: "LinkedIn",
                            content: card.linkedin,
                            icon: "link.circle.fill",
                            color: card.colorScheme.primary
                        )
                    }
                    
                    if !card.website.isEmpty {
                        InfoBox(
                            title: "Website",
                            content: card.website,
                            icon: "globe",
                            color: card.colorScheme.primary
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFullScreen) {
            ZoomableCardView(card: card, selectedImage: selectedImage)
        }
    }
}

struct ZoomableCardView: View {
    let card: BusinessCard
    let selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(colorScheme == .dark ? 1 : 0.9)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text(card.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Zoomable Card
                    BusinessCardPreview(card: card, showFull: true, selectedImage: selectedImage)
                        .frame(height: min(geometry.size.width / 1.8, geometry.size.height * 0.6))
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = min(max(scale * delta, 1), 4)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1 {
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                        if scale <= 1 {
                                            withAnimation {
                                                offset = .zero
                                                lastOffset = .zero
                                            }
                                        }
                                    }
                            )
                        )
                        .gesture(
                            TapGesture(count: 2)
                                .onEnded {
                                    withAnimation {
                                        if scale > 1 {
                                            scale = 1
                                            offset = .zero
                                            lastOffset = .zero
                                        } else {
                                            scale = 2
                                        }
                                    }
                                }
                        )
                    
                    Spacer()
                    
                    // Zoom instructions at bottom
                    Text("Pinch to zoom • Double tap to reset")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 16)
                        .background(
                            Color.black.opacity(0.7)
                                .ignoresSafeArea()
                        )
                }
            }
        }
    }
}

struct InfoBox: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(colorScheme == .dark ? Color(uiColor: .systemGray6) : .white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
}

#Preview {
    NavigationView {
        CardDetailView(
            card: BusinessCard(
                name: "John Doe",
                title: "Software Engineer",
                company: "Tech Corp",
                email: "john@example.com",
                phone: "123-456-7890",
                linkedin: "linkedin.com/in/johndoe",
                website: "johndoe.com",
                aboutMe: "Passionate about creating great software and building amazing user experiences. Always learning and growing in the tech industry.",
                colorScheme: CardColorScheme(
                    primary: Color(red: 0.1, green: 0.3, blue: 0.5),
                    secondary: Color(red: 0.2, green: 0.4, blue: 0.6)
                )
            ),
            selectedImage: nil
        )
    }
} 