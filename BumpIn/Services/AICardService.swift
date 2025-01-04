import Foundation

class AICardService: ObservableObject {
    @Published var isProcessing = false
    private let openAIService: OpenAIService
    
    init() {
        self.openAIService = OpenAIService(apiKey: Config.openAIApiKey)
    }
    
    func generateCardStyle(from description: String) async throws -> CardStyleConfiguration {
        print("🎨 Generating style for description:", description)
        
        await MainActor.run {
            isProcessing = true
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }
        
        do {
            let config = try await openAIService.generateCardStyle(from: description)
            print("✅ Generated style configuration:", config)
            return config
        } catch {
            print("❌ Error generating style:", error)
            throw error
        }
    }
}

struct CardStyleConfiguration {
    var colorScheme: ColorSchemes
    var fontStyle: FontStyles
    var layoutStyle: LayoutStyles
    var backgroundStyle: BackgroundStyle
    var showSymbols: Bool
    var isVertical: Bool
} 