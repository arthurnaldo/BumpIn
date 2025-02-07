import SwiftUI

struct BusinessCard: Codable, Identifiable {
    var id: String
    var userId: String
    var name: String
    var title: String
    var company: String
    var email: String
    var phone: String
    var linkedin: String
    var website: String
    var aboutMe: String
    var profilePictureURL: String?
    var qrCodeURL: String?
    var colorScheme: CardColorScheme
    var fontStyle: FontStyles
    var layoutStyle: LayoutStyles
    var textScale: CGFloat
    var backgroundStyle: BackgroundStyle
    var showSymbols: Bool
    var isVertical: Bool
    
    init(
        id: String = UUID().uuidString,
        userId: String = "",
        name: String = "",
        title: String = "",
        company: String = "",
        email: String = "",
        phone: String = "",
        linkedin: String = "",
        website: String = "",
        aboutMe: String = "",
        profilePictureURL: String? = nil,
        qrCodeURL: String? = nil,
        colorScheme: CardColorScheme = CardColorScheme(),
        fontStyle: FontStyles = .modern,
        layoutStyle: LayoutStyles = .classic,
        textScale: CGFloat = 1.0,
        backgroundStyle: BackgroundStyle = .gradient,
        showSymbols: Bool = false,
        isVertical: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.title = title
        self.company = company
        self.email = email
        self.phone = phone
        self.linkedin = linkedin
        self.website = website
        self.aboutMe = aboutMe
        self.profilePictureURL = profilePictureURL
        self.qrCodeURL = qrCodeURL
        self.colorScheme = colorScheme
        self.fontStyle = fontStyle
        self.layoutStyle = layoutStyle
        self.textScale = textScale
        self.backgroundStyle = backgroundStyle
        self.showSymbols = showSymbols
        self.isVertical = isVertical
    }
}

struct CardColorScheme: Codable, Equatable {
    var primary: Color = Color(red: 0.1, green: 0.3, blue: 0.5)
    var secondary: Color = Color(red: 0.2, green: 0.4, blue: 0.6)
    var textColor: Color = .white
    var accentColor: Color = .white.opacity(0.8)
    var emoticon: String = "💫"
    var borderColor: Color = .clear
    var borderWidth: CGFloat = 0
    
    private enum CodingKeys: String, CodingKey {
        case primary, secondary, textColor, accentColor, emoticon, borderColor, borderWidth
    }
    
    init() {
        self.primary = Color(red: 0.1, green: 0.3, blue: 0.5)
        self.secondary = Color(red: 0.2, green: 0.4, blue: 0.6)
        self.textColor = .white
        self.accentColor = .white.opacity(0.8)
        self.emoticon = "💫"
        self.borderColor = .clear
        self.borderWidth = 0
    }
    
    init(primary: Color, secondary: Color, textColor: Color = .white, accentColor: Color = .white.opacity(0.8), emoticon: String = "💫", borderColor: Color = .clear, borderWidth: CGFloat = 0) {
        self.primary = primary
        self.secondary = secondary
        self.textColor = textColor
        self.accentColor = accentColor
        self.emoticon = emoticon
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }
    
    func backgroundView(style: BackgroundStyle) -> some View {
        let background = switch style {
        case .solid:
            AnyView(primary)
        case .gradient:
            AnyView(
                LinearGradient(
                    colors: [primary, secondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .horizontalSplit:
            AnyView(
                HStack(spacing: 0) {
                    primary
                    secondary
                }
            )
        case .verticalSplit:
            AnyView(
                VStack(spacing: 0) {
                    primary
                    secondary
                }
            )
        case .emoticonPattern:
            AnyView(
                ZStack {
                    LinearGradient(
                        colors: [primary, secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    GeometryReader { geometry in
                        let columns = Int(geometry.size.width / 40)
                        let rows = Int(geometry.size.height / 40)
                        ForEach(0..<rows, id: \.self) { row in
                            ForEach(0..<columns, id: \.self) { column in
                                Text(emoticon)
                                    .font(.system(size: 20))
                                    .opacity(0.1)
                                    .position(
                                        x: CGFloat(column) * 40 + 20,
                                        y: CGFloat(row) * 40 + 20
                                    )
                            }
                        }
                    }
                }
            )
        }
        
        return background
            .overlay(
                Rectangle()
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode arrays of color components
        let primaryComponents = try container.decode([Double].self, forKey: .primary)
        let secondaryComponents = try container.decode([Double].self, forKey: .secondary)
        let textComponents = try container.decode([Double].self, forKey: .textColor)
        let accentComponents = try container.decode([Double].self, forKey: .accentColor)
        let borderComponents = try? container.decode([Double].self, forKey: .borderColor)
        self.emoticon = try container.decodeIfPresent(String.self, forKey: .emoticon) ?? "💫"
        self.borderWidth = try container.decodeIfPresent(CGFloat.self, forKey: .borderWidth) ?? 0
        
        // Create colors from components
        self.primary = Color(red: primaryComponents[0], green: primaryComponents[1], blue: primaryComponents[2])
        self.secondary = Color(red: secondaryComponents[0], green: secondaryComponents[1], blue: secondaryComponents[2])
        self.textColor = Color(red: textComponents[0], green: textComponents[1], blue: textComponents[2])
        self.accentColor = Color(red: accentComponents[0], green: accentComponents[1], blue: accentComponents[2])
        self.borderColor = borderComponents.map { Color(red: $0[0], green: $0[1], blue: $0[2]) } ?? .clear
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let primaryComponents = UIColor(self.primary).cgColor.components ?? [0, 0, 0]
        let secondaryComponents = UIColor(self.secondary).cgColor.components ?? [0, 0, 0]
        let textComponents = UIColor(self.textColor).cgColor.components ?? [1, 1, 1]
        let accentComponents = UIColor(self.accentColor).cgColor.components ?? [1, 1, 1]
        let borderComponents = UIColor(self.borderColor).cgColor.components ?? [0, 0, 0]
        
        try container.encode([primaryComponents[0], primaryComponents[1], primaryComponents[2]], forKey: .primary)
        try container.encode([secondaryComponents[0], secondaryComponents[1], secondaryComponents[2]], forKey: .secondary)
        try container.encode([textComponents[0], textComponents[1], textComponents[2]], forKey: .textColor)
        try container.encode([accentComponents[0], accentComponents[1], accentComponents[2]], forKey: .accentColor)
        try container.encode([borderComponents[0], borderComponents[1], borderComponents[2]], forKey: .borderColor)
        try container.encode(emoticon, forKey: .emoticon)
        try container.encode(borderWidth, forKey: .borderWidth)
    }
}

enum ColorSchemes: String, CaseIterable {
    case ocean = "Ocean"
    case sunset = "Sunset"
    case forest = "Forest"
    case lavender = "Lavender"
    case midnight = "Midnight"
    case professional = "Professional"
    case elegant = "Elegant"
    case modern = "Modern"
    case ruby = "Ruby"
    case emerald = "Emerald"
    case arctic = "Arctic"
    case gold = "Gold"
    case violet = "Violet"
    case coral = "Coral"
    case slate = "Slate"
    case olive = "Olive"
    case wine = "Wine"
    case sage = "Sage"
    case plum = "Plum"
    case bronze = "Bronze"
    case teal = "Teal"
    
    var colors: CardColorScheme {
        switch self {
        case .ocean:
            return CardColorScheme(
                primary: Color(red: 0.1, green: 0.3, blue: 0.5),
                secondary: Color(red: 0.2, green: 0.4, blue: 0.6)
            )
        case .sunset:
            return CardColorScheme(
                primary: Color(red: 0.8, green: 0.3, blue: 0.3),
                secondary: Color(red: 0.9, green: 0.5, blue: 0.3)
            )
        case .forest:
            return CardColorScheme(
                primary: Color(red: 0.2, green: 0.5, blue: 0.3),
                secondary: Color(red: 0.3, green: 0.6, blue: 0.4)
            )
        case .lavender:
            return CardColorScheme(
                primary: Color(red: 0.4, green: 0.3, blue: 0.6),
                secondary: Color(red: 0.5, green: 0.4, blue: 0.7)
            )
        case .midnight:
            return CardColorScheme(
                primary: Color(red: 0.1, green: 0.1, blue: 0.3),
                secondary: Color(red: 0.2, green: 0.2, blue: 0.4)
            )
        case .professional:
            return CardColorScheme(
                primary: Color.white,
                secondary: Color(white: 0.98),
                textColor: .black,
                accentColor: Color(red: 0.2, green: 0.2, blue: 0.2)
            )
        case .elegant:
            return CardColorScheme(
                primary: Color(white: 0.15),
                secondary: Color(white: 0.1),
                textColor: Color(red: 0.9, green: 0.8, blue: 0.5),
                accentColor: Color(red: 0.9, green: 0.8, blue: 0.5).opacity(0.8)
            )
        case .modern:
            return CardColorScheme(
                primary: Color.white,
                secondary: Color(white: 0.95),
                textColor: Color(red: 0.2, green: 0.2, blue: 0.25),
                accentColor: Color(red: 0.3, green: 0.3, blue: 0.35)
            )
        case .ruby:
            return CardColorScheme(
                primary: Color(red: 0.7, green: 0.1, blue: 0.2),
                secondary: Color(red: 0.8, green: 0.2, blue: 0.3)
            )
        case .emerald:
            return CardColorScheme(
                primary: Color(red: 0.0, green: 0.5, blue: 0.4),
                secondary: Color(red: 0.1, green: 0.6, blue: 0.5)
            )
        case .arctic:
            return CardColorScheme(
                primary: Color(red: 0.7, green: 0.9, blue: 1.0),
                secondary: Color(red: 0.8, green: 1.0, blue: 1.0),
                textColor: .black,
                accentColor: Color.black.opacity(0.8)
            )
        case .gold:
            return CardColorScheme(
                primary: Color(red: 0.8, green: 0.7, blue: 0.2),
                secondary: Color(red: 0.9, green: 0.8, blue: 0.3),
                textColor: .black,
                accentColor: Color.black.opacity(0.8)
            )
        case .violet:
            return CardColorScheme(
                primary: Color(red: 0.4, green: 0.2, blue: 0.6),
                secondary: Color(red: 0.5, green: 0.3, blue: 0.7)
            )
        case .coral:
            return CardColorScheme(
                primary: Color(red: 1.0, green: 0.5, blue: 0.4),
                secondary: Color(red: 1.0, green: 0.6, blue: 0.5)
            )
        case .slate:
            return CardColorScheme(
                primary: Color(red: 0.4, green: 0.5, blue: 0.6),
                secondary: Color(red: 0.5, green: 0.6, blue: 0.7)
            )
        case .olive:
            return CardColorScheme(
                primary: Color(red: 0.5, green: 0.5, blue: 0.2),
                secondary: Color(red: 0.6, green: 0.6, blue: 0.3)
            )
        case .wine:
            return CardColorScheme(
                primary: Color(red: 0.5, green: 0.1, blue: 0.2),
                secondary: Color(red: 0.6, green: 0.2, blue: 0.3)
            )
        case .sage:
            return CardColorScheme(
                primary: Color(red: 0.5, green: 0.6, blue: 0.5),
                secondary: Color(red: 0.6, green: 0.7, blue: 0.6)
            )
        case .plum:
            return CardColorScheme(
                primary: Color(red: 0.5, green: 0.2, blue: 0.4),
                secondary: Color(red: 0.6, green: 0.3, blue: 0.5)
            )
        case .bronze:
            return CardColorScheme(
                primary: Color(red: 0.7, green: 0.5, blue: 0.3),
                secondary: Color(red: 0.8, green: 0.6, blue: 0.4),
                textColor: .black,
                accentColor: Color.black.opacity(0.8)
            )
        case .teal:
            return CardColorScheme(
                primary: Color(red: 0.1, green: 0.5, blue: 0.5),
                secondary: Color(red: 0.2, green: 0.6, blue: 0.6)
            )
        }
    }
}

enum FontStyles: String, Codable, CaseIterable {
    case executive = "Executive"
    case corporate = "Corporate"
    case modern = "Modern"
    case classic = "Classic"
    case elegant = "Elegant"
    case minimalist = "Minimalist"
    case bold = "Bold"
    case creative = "Creative"
    case traditional = "Traditional"
    case contemporary = "Contemporary"
    case tech = "Tech"
    case retro = "Retro"
    case futuristic = "Future"
    
    var titleFont: Font {
        switch self {
        case .modern:
            return .system(size: 18, weight: .medium, design: .rounded)
        case .classic:
            return .system(size: 18, design: .serif)
        case .executive:
            return .system(size: 18, weight: .semibold, design: .serif)
        case .corporate:
            return .system(size: 18, weight: .medium)
        case .elegant:
            return .system(size: 18, weight: .regular, design: .serif).italic()
        case .minimalist:
            return .system(size: 18, weight: .light)
        case .bold:
            return .system(size: 18, weight: .bold)
        case .creative:
            return .system(size: 18, weight: .semibold, design: .rounded)
        case .traditional:
            return .system(size: 18, weight: .medium, design: .serif)
        case .contemporary:
            return .system(size: 18, weight: .regular, design: .rounded)
        case .tech:
            return .system(size: 18, weight: .medium, design: .monospaced)
        case .retro:
            return .system(size: 18, weight: .bold, design: .serif)
        case .futuristic:
            return .system(size: 18, weight: .thin, design: .rounded)
        }
    }
    
    var bodyFont: Font {
        switch self {
        case .modern:
            return .system(size: 11, design: .rounded)
        case .classic:
            return .system(size: 11, design: .serif)
        case .executive:
            return .system(size: 11, design: .serif)
        case .corporate:
            return .system(size: 11)
        case .elegant:
            return .system(size: 11, design: .serif).italic()
        case .minimalist:
            return .system(size: 11, weight: .light)
        case .bold:
            return .system(size: 11, weight: .medium)
        case .creative:
            return .system(size: 11, design: .rounded)
        case .traditional:
            return .system(size: 11, design: .serif)
        case .contemporary:
            return .system(size: 11, design: .rounded)
        case .tech:
            return .system(size: 11, weight: .regular, design: .monospaced)
        case .retro:
            return .system(size: 11, weight: .medium, design: .serif)
        case .futuristic:
            return .system(size: 11, weight: .light, design: .rounded)
        }
    }
    
    var detailFont: Font {
        switch self {
        case .modern:
            return .system(size: 10, design: .rounded)
        case .classic:
            return .system(size: 10, design: .serif)
        case .executive:
            return .system(size: 9, design: .serif)
        case .corporate:
            return .system(size: 9)
        case .elegant:
            return .system(size: 9, design: .serif).italic()
        case .minimalist:
            return .system(size: 9, weight: .light)
        case .bold:
            return .system(size: 9)
        case .creative:
            return .system(size: 10, design: .rounded)
        case .traditional:
            return .system(size: 9, design: .serif)
        case .contemporary:
            return .system(size: 9, design: .rounded)
        case .tech:
            return .system(size: 10, weight: .regular, design: .monospaced)
        case .retro:
            return .system(size: 9, weight: .regular, design: .serif)
        case .futuristic:
            return .system(size: 9, weight: .ultraLight, design: .rounded)
        }
    }
    
    var titleSpacing: CGFloat {
        switch self {
        case .modern: return 4
        case .classic: return 5
        case .executive, .corporate: return 4
        case .contemporary: return 3
        case .traditional: return 5
        case .elegant: return 6
        case .minimalist: return 8
        case .bold: return 3
        case .creative: return 4
        case .tech: return 4
        case .retro: return 6
        case .futuristic: return 2
        }
    }
    
    var lineSpacing: CGFloat {
        switch self {
        case .modern: return 2
        case .classic: return 3
        case .executive, .corporate: return 2
        case .contemporary: return 1
        case .traditional: return 3
        case .elegant: return 4
        case .minimalist: return 6
        case .bold: return 1
        case .creative: return 2
        case .tech: return 2
        case .retro: return 4
        case .futuristic: return 1
        }
    }
    
    var textCase: Text.Case? {
        switch self {
        case .executive, .corporate, .bold:
            return .uppercase
        case .minimalist:
            return .lowercase
        default:
            return nil
        }
    }
    
    var letterSpacing: CGFloat {
        switch self {
        case .modern: return 0.2
        case .classic: return 0.3
        case .executive, .corporate: return 0.5
        case .contemporary: return 0
        case .traditional: return 0.3
        case .elegant: return 0.8
        case .minimalist: return 1.2
        case .bold: return 0.4
        case .creative: return 0.2
        case .tech: return 0.5
        case .retro: return 0.6
        case .futuristic: return 0.8
        }
    }
}

enum LayoutStyles: String, Codable, CaseIterable {
    case classic = "Classic"
    case modern = "Modern"
    case compact = "Compact"
    case centered = "Centered"
    case minimal = "Minimal"
    case elegant = "Elegant"
    case professional = "Professional"
}

enum BackgroundStyle: String, Codable, CaseIterable {
    case solid = "Solid Color"
    case gradient = "Gradient"
    case horizontalSplit = "Horizontal Split"
    case verticalSplit = "Vertical Split"
    case emoticonPattern = "Emoticon Pattern"
}

struct CardSymbols {
    static let name = "person.fill"
    static let title = "briefcase.fill"
    static let company = "building.2.fill"
    static let email = "envelope.fill"
    static let phone = "phone.fill"
    static let linkedin = "link"
    static let website = "globe"
    static let aboutMe = "text.justify"
} 