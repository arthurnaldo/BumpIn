import Foundation

class OpenAIService {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateCardStyle(from description: String) async throws -> CardStyleConfiguration {
        let prompt = """
        Based on this description: "\(description)"
        Generate a business card style configuration. Return ONLY a JSON object with these exact properties:
        {
            "colorScheme": "one of [Ocean, Sunset, Forest, Lavender, Midnight, Professional, Elegant, Modern, Ruby, Emerald, Arctic, Gold, Violet, Coral, Slate, Olive, Wine, Sage, Plum, Bronze, Teal]",
            "fontStyle": "one of [Executive, Corporate, Modern, Classic, Elegant, Minimalist, Bold, Creative, Traditional, Contemporary, Tech, Retro, Future]",
            "layoutStyle": "one of [Classic, Modern, Compact, Centered, Minimal, Elegant, Professional]",
            "backgroundStyle": "one of [Solid Color, Gradient, Horizontal Split, Vertical Split, Emoticon Pattern]",
            "showSymbols": boolean,
            "isVertical": boolean
        }
        Choose values that best match the description's style and mood. Return ONLY the JSON object, no additional text.
        """
        
        let messages: [[String: String]] = [
            ["role": "system", "content": "You are a professional design assistant specializing in business card styles."],
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 150
        ]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        // Debug prints
        print("Raw GPT Response:", String(data: data, encoding: .utf8) ?? "No data")
        print("Parsed Message:", response.choices.first?.message.content ?? "No content")
        
        guard let jsonString = response.choices.first?.message.content,
              let jsonData = jsonString.data(using: .utf8),
              let config = try? JSONDecoder().decode(AIStyleResponse.self, from: jsonData) else {
            print("❌ Failed to parse GPT response into AIStyleResponse")
            throw AIError.invalidResponse
        }
        
        print("✅ Parsed Configuration:", config)
        
        return CardStyleConfiguration(
            colorScheme: ColorSchemes(rawValue: config.colorScheme.capitalized) ?? .professional,
            fontStyle: FontStyles(rawValue: config.fontStyle.capitalized) ?? .modern,
            layoutStyle: LayoutStyles(rawValue: config.layoutStyle.capitalized) ?? .classic,
            backgroundStyle: BackgroundStyle(rawValue: config.backgroundStyle.replacingOccurrences(of: " ", with: "")) ?? .gradient,
            showSymbols: config.showSymbols,
            isVertical: config.isVertical
        )
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}

struct AIStyleResponse: Codable {
    let colorScheme: String
    let fontStyle: String
    let layoutStyle: String
    let backgroundStyle: String
    let showSymbols: Bool
    let isVertical: Bool
}

enum AIError: Error {
    case invalidResponse
} 