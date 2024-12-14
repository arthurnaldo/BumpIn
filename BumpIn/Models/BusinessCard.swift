import SwiftUI

struct BusinessCard: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String = ""
    var title: String = ""
    var company: String = ""
    var email: String = ""
    var phone: String = ""
    var linkedin: String = ""
    var website: String = ""
    var profileImageURL: String?
    var colorScheme: CardColorScheme = CardColorScheme()
    var fontStyle: FontStyles = .modern
    var layoutStyle: LayoutStyles = .classic
    var textScale: CGFloat = 1.0
    var backgroundStyle: BackgroundStyle = .gradient
}

struct CardColorScheme: Codable, Equatable {
    var primary: Color = Color(red: 0.1, green: 0.3, blue: 0.5)
    var secondary: Color = Color(red: 0.2, green: 0.4, blue: 0.6)
    var textColor: Color = .white
    var accentColor: Color = .white.opacity(0.8)
    
    private enum CodingKeys: String, CodingKey {
        case primary, secondary, textColor, accentColor
    }
    
    init() {
        self.primary = Color(red: 0.1, green: 0.3, blue: 0.5)
        self.secondary = Color(red: 0.2, green: 0.4, blue: 0.6)
        self.textColor = .white
        self.accentColor = .white.opacity(0.8)
    }
    
    init(primary: Color, secondary: Color, textColor: Color = .white, accentColor: Color = .white.opacity(0.8)) {
        self.primary = primary
        self.secondary = secondary
        self.textColor = textColor
        self.accentColor = accentColor
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let primaryComponents = try container.decode([Double].self, forKey: .primary)
        let secondaryComponents = try container.decode([Double].self, forKey: .secondary)
        let textComponents = try container.decode([Double].self, forKey: .textColor)
        let accentComponents = try container.decode([Double].self, forKey: .accentColor)
        
        self.primary = Color(red: primaryComponents[0], green: primaryComponents[1], blue: primaryComponents[2])
        self.secondary = Color(red: secondaryComponents[0], green: secondaryComponents[1], blue: secondaryComponents[2])
        self.textColor = Color(red: textComponents[0], green: textComponents[1], blue: textComponents[2])
        self.accentColor = Color(red: accentComponents[0], green: accentComponents[1], blue: accentComponents[2])
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let primaryComponents = UIColor(self.primary).cgColor.components ?? [0, 0, 0]
        let secondaryComponents = UIColor(self.secondary).cgColor.components ?? [0, 0, 0]
        let textComponents = UIColor(self.textColor).cgColor.components ?? [1, 1, 1]
        let accentComponents = UIColor(self.accentColor).cgColor.components ?? [1, 1, 1]
        
        try container.encode([primaryComponents[0], primaryComponents[1], primaryComponents[2]], forKey: .primary)
        try container.encode([secondaryComponents[0], secondaryComponents[1], secondaryComponents[2]], forKey: .secondary)
        try container.encode([textComponents[0], textComponents[1], textComponents[2]], forKey: .textColor)
        try container.encode([accentComponents[0], accentComponents[1], accentComponents[2]], forKey: .accentColor)
    }
    
    func backgroundView(style: BackgroundStyle) -> some View {
        switch style {
        case .solid:
            return AnyView(primary)
        case .gradient:
            return AnyView(
                LinearGradient(
                    colors: [primary, secondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .horizontalSplit:
            return AnyView(
                HStack(spacing: 0) {
                    primary
                    secondary
                }
            )
        case .verticalSplit:
            return AnyView(
                VStack(spacing: 0) {
                    primary
                    secondary
                }
            )
        }
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
                primary: Color(red: 0.1, green: 0.1, blue: 0.2),
                secondary: Color(red: 0.2, green: 0.2, blue: 0.3)
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
    
    var titleFont: Font {
        let baseSize: CGFloat = 18
        switch self {
        case .executive:
            return .system(size: baseSize, weight: .semibold, design: .serif)
        case .corporate:
            return .system(size: baseSize, weight: .medium)
        case .modern:
            return .system(size: baseSize, weight: .medium, design: .rounded)
        case .classic:
            return .system(size: baseSize, design: .serif)
        case .elegant:
            return .system(size: baseSize, weight: .regular, design: .serif).italic()
        case .minimalist:
            return .system(size: baseSize, weight: .light)
        case .bold:
            return .system(size: baseSize, weight: .bold)
        case .creative:
            return .system(size: baseSize, weight: .semibold, design: .rounded)
        case .traditional:
            return .system(size: baseSize, weight: .medium, design: .serif)
        case .contemporary:
            return .system(size: baseSize, weight: .regular, design: .rounded)
        }
    }
    
    var bodyFont: Font {
        let baseSize: CGFloat = 14
        switch self {
        case .executive:
            return .system(size: baseSize, design: .serif)
        case .corporate:
            return .system(size: baseSize)
        case .modern:
            return .system(size: baseSize, design: .rounded)
        case .classic:
            return .system(size: baseSize, design: .serif)
        case .elegant:
            return .system(size: baseSize, design: .serif).italic()
        case .minimalist:
            return .system(size: baseSize, weight: .light)
        case .bold:
            return .system(size: baseSize, weight: .medium)
        case .creative:
            return .system(size: baseSize, design: .rounded)
        case .traditional:
            return .system(size: baseSize, design: .serif)
        case .contemporary:
            return .system(size: baseSize, design: .rounded)
        }
    }
    
    var detailFont: Font {
        let baseSize: CGFloat = 12
        switch self {
        case .executive:
            return .system(size: baseSize, design: .serif)
        case .corporate:
            return .system(size: baseSize)
        case .modern:
            return .system(size: baseSize, design: .rounded)
        case .classic:
            return .system(size: baseSize, design: .serif)
        case .elegant:
            return .system(size: baseSize, design: .serif).italic()
        case .minimalist:
            return .system(size: baseSize, weight: .light)
        case .bold:
            return .system(size: baseSize)
        case .creative:
            return .system(size: baseSize, design: .rounded)
        case .traditional:
            return .system(size: baseSize, design: .serif)
        case .contemporary:
            return .system(size: baseSize, design: .rounded)
        }
    }
    
    func scaledTitleFont(_ scale: CGFloat) -> Font {
        let baseSize: CGFloat = 18 * scale
        switch self {
        case .executive:
            return .system(size: baseSize, weight: .semibold, design: .serif)
        case .corporate:
            return .system(size: baseSize, weight: .medium)
        case .modern:
            return .system(size: baseSize, weight: .medium, design: .rounded)
        case .classic:
            return .system(size: baseSize, design: .serif)
        case .elegant:
            return .system(size: baseSize, weight: .regular, design: .serif).italic()
        case .minimalist:
            return .system(size: baseSize, weight: .light)
        case .bold:
            return .system(size: baseSize, weight: .bold)
        case .creative:
            return .system(size: baseSize, weight: .semibold, design: .rounded)
        case .traditional:
            return .system(size: baseSize, weight: .medium, design: .serif)
        case .contemporary:
            return .system(size: baseSize, weight: .regular, design: .rounded)
        }
    }
    
    func scaledBodyFont(_ scale: CGFloat) -> Font {
        let baseSize: CGFloat = 14 * scale
        switch self {
        case .executive:
            return .system(size: baseSize, design: .serif)
        case .corporate:
            return .system(size: baseSize)
        case .modern:
            return .system(size: baseSize, design: .rounded)
        case .classic:
            return .system(size: baseSize, design: .serif)
        case .elegant:
            return .system(size: baseSize, design: .serif).italic()
        case .minimalist:
            return .system(size: baseSize, weight: .light)
        case .bold:
            return .system(size: baseSize, weight: .medium)
        case .creative:
            return .system(size: baseSize, design: .rounded)
        case .traditional:
            return .system(size: baseSize, design: .serif)
        case .contemporary:
            return .system(size: baseSize, design: .rounded)
        }
    }
    
    func scaledDetailFont(_ scale: CGFloat) -> Font {
        let baseSize: CGFloat = 12 * scale
        switch self {
        case .executive:
            return .system(size: baseSize, design: .serif)
        case .corporate:
            return .system(size: baseSize)
        case .modern:
            return .system(size: baseSize, design: .rounded)
        case .classic:
            return .system(size: baseSize, design: .serif)
        case .elegant:
            return .system(size: baseSize, design: .serif).italic()
        case .minimalist:
            return .system(size: baseSize, weight: .light)
        case .bold:
            return .system(size: baseSize)
        case .creative:
            return .system(size: baseSize, design: .rounded)
        case .traditional:
            return .system(size: baseSize, design: .serif)
        case .contemporary:
            return .system(size: baseSize, design: .rounded)
        }
    }
    
    var titleSpacing: CGFloat {
        switch self {
        case .executive, .corporate: return 4
        case .modern, .contemporary: return 3
        case .classic, .traditional: return 5
        case .elegant: return 6
        case .minimalist: return 8
        case .bold: return 3
        case .creative: return 4
        }
    }
    
    var lineSpacing: CGFloat {
        switch self {
        case .executive, .corporate: return 2
        case .modern, .contemporary: return 1
        case .classic, .traditional: return 3
        case .elegant: return 4
        case .minimalist: return 6
        case .bold: return 1
        case .creative: return 2
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
        case .executive, .corporate: return 0.5
        case .modern, .contemporary: return 0
        case .classic, .traditional: return 0.3
        case .elegant: return 0.8
        case .minimalist: return 1.2
        case .bold: return 0.4
        case .creative: return 0.2
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
} 