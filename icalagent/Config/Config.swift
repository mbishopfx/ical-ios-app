import Foundation

enum Config {
    // Use environment variable or secure configuration system for API keys
    static let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    
    // Add other configuration values here
    static let defaultCalendarName = "My Calendar"
    static let maxEvents = 100
} 