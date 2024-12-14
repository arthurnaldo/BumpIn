import SwiftUI

struct BusinessCardPreview: View {
    let card: BusinessCard
    let showFull: Bool
    let selectedImage: UIImage?
    @State private var profileImage: UIImage?
    @StateObject private var storageService = StorageService()
    
    init(card: BusinessCard, showFull: Bool, selectedImage: UIImage? = nil) {
        self.card = card
        self.showFull = showFull
        self.selectedImage = selectedImage
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Group {
                switch card.layoutStyle {
                case .classic:
                    classicLayout
                case .modern:
                    modernLayout
                case .compact:
                    compactLayout
                case .centered:
                    centeredLayout
                case .minimal:
                    minimalLayout
                case .elegant:
                    elegantLayout
                case .professional:
                    professionalLayout
                }
            }
            .transition(.opacity.combined(with: .scale))
        }
        .padding(showFull ? 30 : 20)
        .frame(maxWidth: .infinity)
        .aspectRatio(1.75, contentMode: .fit)
        .background(card.colorScheme.backgroundView(style: card.backgroundStyle))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: card.layoutStyle)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: card.colorScheme)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: card.fontStyle)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: card.backgroundStyle)
        .task {
            if let imageURL = card.profileImageURL {
                do {
                    profileImage = try await storageService.loadProfileImage(from: imageURL)
                } catch {
                    print("Error loading profile image: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private var profileImageView: some View {
        let size = 60 * card.textScale
        return Group {
            if let image = selectedImage ?? profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(card.colorScheme.accentColor.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(card.colorScheme.accentColor)
                            .padding(12 * card.textScale)
                    )
            }
        }
    }
    
    private var classicLayout: some View {
        VStack(spacing: showFull ? 4 : 2) {
            profileImageView
                .padding(.bottom, showFull ? 4 : 2)
            
            Text(card.name)
                .font(card.fontStyle.scaledTitleFont(card.textScale))
                .foregroundColor(card.colorScheme.textColor)
                .textCase(card.fontStyle.textCase)
                .tracking(card.fontStyle.letterSpacing)
                .padding(.bottom, card.fontStyle.titleSpacing * card.textScale)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if !card.title.isEmpty {
                Text(card.title)
                    .font(card.fontStyle.scaledBodyFont(card.textScale))
                    .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                    .textCase(card.fontStyle.textCase)
                    .tracking(card.fontStyle.letterSpacing)
                    .lineSpacing(card.fontStyle.lineSpacing * card.textScale)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            if !card.company.isEmpty {
                Text(card.company)
                    .font(card.fontStyle.scaledBodyFont(card.textScale))
                    .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                    .textCase(card.fontStyle.textCase)
                    .tracking(card.fontStyle.letterSpacing)
                    .lineSpacing(card.fontStyle.lineSpacing * card.textScale)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            VStack(spacing: showFull ? 12 : 6) {
                if !card.email.isEmpty {
                    ContactRow(icon: "envelope.fill", text: card.email, colorScheme: card.colorScheme)
                }
                if !card.phone.isEmpty {
                    ContactRow(icon: "phone.fill", text: card.phone, colorScheme: card.colorScheme)
                }
                if !card.linkedin.isEmpty {
                    ContactRow(icon: "link", text: card.linkedin, colorScheme: card.colorScheme)
                }
                if !card.website.isEmpty {
                    ContactRow(icon: "globe", text: card.website, colorScheme: card.colorScheme)
                }
            }
            .padding(.top, showFull ? 8 : 4)
        }
    }
    
    private var modernLayout: some View {
        HStack(alignment: .top, spacing: showFull ? 20 : 12) {
            profileImageView
            
            VStack(alignment: .leading, spacing: showFull ? 4 : 2) {
                Text(card.name)
                    .font(card.fontStyle.scaledTitleFont(card.textScale))
                    .foregroundColor(card.colorScheme.textColor)
                    .textCase(card.fontStyle.textCase)
                    .tracking(card.fontStyle.letterSpacing)
                    .padding(.bottom, card.fontStyle.titleSpacing * card.textScale)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if !card.title.isEmpty {
                    Text(card.title)
                        .font(card.fontStyle.scaledBodyFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .textCase(card.fontStyle.textCase)
                        .tracking(card.fontStyle.letterSpacing)
                        .lineSpacing(card.fontStyle.lineSpacing * card.textScale)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                if !card.company.isEmpty {
                    Text(card.company)
                        .font(card.fontStyle.scaledBodyFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .textCase(card.fontStyle.textCase)
                        .tracking(card.fontStyle.letterSpacing)
                        .lineSpacing(card.fontStyle.lineSpacing * card.textScale)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                VStack(alignment: .leading, spacing: showFull ? 8 : 4) {
                    if !card.email.isEmpty {
                        ContactRow(icon: "envelope.fill", text: card.email, colorScheme: card.colorScheme)
                    }
                    if !card.phone.isEmpty {
                        ContactRow(icon: "phone.fill", text: card.phone, colorScheme: card.colorScheme)
                    }
                    if !card.linkedin.isEmpty {
                        ContactRow(icon: "link", text: card.linkedin, colorScheme: card.colorScheme)
                    }
                    if !card.website.isEmpty {
                        ContactRow(icon: "globe", text: card.website, colorScheme: card.colorScheme)
                    }
                }
                .padding(.top, showFull ? 8 : 4)
            }
        }
    }
    
    private var compactLayout: some View {
        HStack(spacing: showFull ? 15 : 10) {
            profileImageView
            
            VStack(alignment: .leading, spacing: showFull ? 4 : 2) {
                Text(card.name)
                    .font(card.fontStyle.scaledTitleFont(card.textScale))
                    .foregroundColor(card.colorScheme.textColor)
                    .textCase(card.fontStyle.textCase)
                    .tracking(card.fontStyle.letterSpacing)
                    .padding(.bottom, card.fontStyle.titleSpacing * card.textScale)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if !card.title.isEmpty {
                    Text(card.title)
                        .font(card.fontStyle.scaledBodyFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .textCase(card.fontStyle.textCase)
                        .tracking(card.fontStyle.letterSpacing)
                        .lineSpacing(card.fontStyle.lineSpacing * card.textScale)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                if !card.company.isEmpty {
                    Text(card.company)
                        .font(card.fontStyle.scaledBodyFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .textCase(card.fontStyle.textCase)
                        .tracking(card.fontStyle.letterSpacing)
                        .lineSpacing(card.fontStyle.lineSpacing * card.textScale)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                VStack(alignment: .leading, spacing: showFull ? 4 : 2) {
                    if !card.email.isEmpty {
                        Text(card.email)
                            .font(card.fontStyle.scaledDetailFont(card.textScale))
                            .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    if !card.phone.isEmpty {
                        Text(card.phone)
                            .font(card.fontStyle.scaledDetailFont(card.textScale))
                            .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    if !card.linkedin.isEmpty {
                        Text(card.linkedin)
                            .font(card.fontStyle.scaledDetailFont(card.textScale))
                            .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    if !card.website.isEmpty {
                        Text(card.website)
                            .font(card.fontStyle.scaledDetailFont(card.textScale))
                            .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .padding(.top, showFull ? 4 : 2)
            }
        }
    }
    
    private var centeredLayout: some View {
        VStack(spacing: showFull ? 15 : 8) {
            profileImageView
            
            Text(card.name)
                .font(card.fontStyle.scaledTitleFont(card.textScale))
                .foregroundColor(card.colorScheme.textColor)
                .textCase(card.fontStyle.textCase)
                .tracking(card.fontStyle.letterSpacing)
                .padding(.bottom, card.fontStyle.titleSpacing * card.textScale)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if !card.title.isEmpty || !card.company.isEmpty {
                Text([card.title, card.company].filter { !$0.isEmpty }.joined(separator: " • "))
                    .font(card.fontStyle.scaledBodyFont(card.textScale))
                    .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                    .textCase(card.fontStyle.textCase)
                    .tracking(card.fontStyle.letterSpacing)
                    .lineSpacing(card.fontStyle.lineSpacing * card.textScale)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }
            
            Divider()
                .background(card.colorScheme.textColor.opacity(0.5))
                .padding(.horizontal)
            
            VStack(spacing: showFull ? 8 : 4) {
                if !card.email.isEmpty {
                    Text(card.email)
                        .font(card.fontStyle.scaledDetailFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if !card.phone.isEmpty {
                    Text(card.phone)
                        .font(card.fontStyle.scaledDetailFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if !card.linkedin.isEmpty {
                    Text(card.linkedin)
                        .font(card.fontStyle.scaledDetailFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if !card.website.isEmpty {
                    Text(card.website)
                        .font(card.fontStyle.scaledDetailFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }
    
    private var minimalLayout: some View {
        VStack(alignment: .leading, spacing: showFull ? 15 : 8) {
            Text(card.name)
                .font(card.fontStyle.scaledTitleFont(card.textScale))
                .foregroundColor(card.colorScheme.textColor)
                .textCase(card.fontStyle.textCase)
                .tracking(card.fontStyle.letterSpacing)
                .padding(.bottom, card.fontStyle.titleSpacing * card.textScale)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Divider()
                .background(card.colorScheme.textColor.opacity(0.5))
            
            if !card.title.isEmpty || !card.company.isEmpty {
                Text([card.title, card.company].filter { !$0.isEmpty }.joined(separator: " • "))
                    .font(card.fontStyle.scaledBodyFont(card.textScale))
                    .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                    .textCase(card.fontStyle.textCase)
                    .tracking(card.fontStyle.letterSpacing)
                    .lineSpacing(card.fontStyle.lineSpacing * card.textScale)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            VStack(alignment: .leading, spacing: showFull ? 4 : 2) {
                if !card.email.isEmpty {
                    Text(card.email)
                        .font(card.fontStyle.scaledDetailFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if !card.phone.isEmpty {
                    Text(card.phone)
                        .font(card.fontStyle.scaledDetailFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if !card.linkedin.isEmpty {
                    Text(card.linkedin)
                        .font(card.fontStyle.scaledDetailFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if !card.website.isEmpty {
                    Text(card.website)
                        .font(card.fontStyle.scaledDetailFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }
    
    private var elegantLayout: some View {
        VStack(spacing: showFull ? 20 : 10) {
            Text(card.name)
                .font(card.fontStyle.scaledTitleFont(card.textScale))
                .foregroundColor(card.colorScheme.textColor)
                .textCase(card.fontStyle.textCase)
                .tracking(card.fontStyle.letterSpacing)
                .padding(.top, showFull ? 8 : 4)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if !card.title.isEmpty || !card.company.isEmpty {
                Text([card.title, card.company].filter { !$0.isEmpty }.joined(separator: "\n"))
                    .font(card.fontStyle.scaledBodyFont(card.textScale))
                    .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                    .textCase(card.fontStyle.textCase)
                    .tracking(card.fontStyle.letterSpacing)
                    .lineSpacing(card.fontStyle.lineSpacing * card.textScale)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }
            
            profileImageView
                .padding(.vertical, showFull ? 8 : 4)
            
            VStack(spacing: showFull ? 8 : 4) {
                if !card.email.isEmpty {
                    Text(card.email)
                        .font(card.fontStyle.scaledDetailFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if !card.phone.isEmpty {
                    Text(card.phone)
                        .font(card.fontStyle.scaledDetailFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if !card.linkedin.isEmpty {
                    Text(card.linkedin)
                        .font(card.fontStyle.scaledDetailFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if !card.website.isEmpty {
                    Text(card.website)
                        .font(card.fontStyle.scaledDetailFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }
    
    private var professionalLayout: some View {
        HStack(spacing: showFull ? 20 : 12) {
            VStack(alignment: .leading, spacing: showFull ? 15 : 8) {
                Text(card.name)
                    .font(card.fontStyle.scaledTitleFont(card.textScale))
                    .foregroundColor(card.colorScheme.textColor)
                    .textCase(card.fontStyle.textCase)
                    .tracking(card.fontStyle.letterSpacing)
                    .padding(.bottom, card.fontStyle.titleSpacing * card.textScale)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if !card.title.isEmpty || !card.company.isEmpty {
                    Text([card.title, card.company].filter { !$0.isEmpty }.joined(separator: "\n"))
                        .font(card.fontStyle.scaledBodyFont(card.textScale))
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .textCase(card.fontStyle.textCase)
                        .tracking(card.fontStyle.letterSpacing)
                        .lineSpacing(card.fontStyle.lineSpacing * card.textScale)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Divider()
                    .background(card.colorScheme.textColor.opacity(0.5))
                
                VStack(alignment: .leading, spacing: showFull ? 8 : 4) {
                    if !card.email.isEmpty {
                        ContactRow(icon: "envelope.fill", text: card.email, colorScheme: card.colorScheme)
                    }
                    if !card.phone.isEmpty {
                        ContactRow(icon: "phone.fill", text: card.phone, colorScheme: card.colorScheme)
                    }
                    if !card.linkedin.isEmpty {
                        ContactRow(icon: "link", text: card.linkedin, colorScheme: card.colorScheme)
                    }
                    if !card.website.isEmpty {
                        ContactRow(icon: "globe", text: card.website, colorScheme: card.colorScheme)
                    }
                }
            }
            
            Spacer(minLength: 0)
            profileImageView
        }
    }
} 