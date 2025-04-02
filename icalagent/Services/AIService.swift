import Foundation

actor AIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateEvents(from prompt: String, categories: Set<ScheduleCategory>, preferences: UserPreferences) async throws -> [CalendarEvent] {
        let systemPrompt = """
        You are a calendar event generator. Generate a 30-day schedule with well-structured events based on the user's description, selected categories, work hours, and recurring tasks.
        
        Work Hours:
        - Start: \(preferences.workHours.startTime.formatted(date: .omitted, time: .shortened))
        - End: \(preferences.workHours.endTime.formatted(date: .omitted, time: .shortened))
        - Work Days: \(preferences.workHours.workDays.map { getDayName($0) }.joined(separator: ", "))
        
        Recurring Tasks:
        \(preferences.recurringTasks.map { task in
            """
            - \(task.title)
              Time: \(task.startTime.formatted(date: .omitted, time: .shortened))
              Duration: \(Int(task.duration / 60)) minutes
              Frequency: \(task.frequency.rawValue)
              Days: \(task.daysOfWeek.map { getDayName($0) }.joined(separator: ", "))
            """
        }.joined(separator: "\n"))
        
        Guidelines:
        1. Create realistic schedules that respect time constraints
        2. Ensure events don't overlap with work hours or recurring tasks
        3. Include appropriate breaks between events
        4. Vary event times to create a natural flow
        5. Add detailed descriptions that explain the purpose of each event
        6. Format the response as a JSON array of events with the following structure:
        [
            {
                "id": "UUID string",
                "title": "Event title",
                "description": "Event description",
                "startDate": "ISO 8601 date string",
                "endDate": "ISO 8601 date string",
                "location": "Optional location string",
                "attendees": ["Optional array of email addresses"],
                "category": "Optional category string",
                "isAllDay": false
            }
        ]
        
        Selected categories: \(categories.map { $0.rawValue }.joined(separator: ", "))
        """
        
        let userPrompt = """
        Generate a 30-day schedule based on this description: \(prompt)
        Make the events realistic and well-structured, ensuring they fit within the selected categories and don't conflict with work hours or recurring tasks.
        """
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.7,
            "max_tokens": 2000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid HTTP response")
            throw AIError.requestFailed
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                print("API Error: \(errorResponse.error.message)")
                throw AIError.apiError(errorResponse.error.message)
            }
            print("HTTP Error: \(httpResponse.statusCode)")
            throw AIError.requestFailed
        }
        
        do {
            let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            guard let content = result.choices.first?.message.content,
                  let jsonData = content.data(using: .utf8) else {
                print("Invalid content in response")
                throw AIError.invalidResponse
            }
            
            print("Raw JSON response: \(String(data: jsonData, encoding: .utf8) ?? "Invalid JSON")")
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                let events = try decoder.decode([CalendarEvent].self, from: jsonData)
                return events
            } catch {
                print("Failed to decode events: \(error)")
                print("Decoding error details: \(error.localizedDescription)")
                throw AIError.invalidResponse
            }
        } catch {
            print("Failed to decode OpenAI response: \(error)")
            throw AIError.invalidResponse
        }
    }
    
    private func getDayName(_ day: Int) -> String {
        switch day {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return "Unknown"
        }
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

struct OpenAIErrorResponse: Codable {
    let error: Error
    
    struct Error: Codable {
        let message: String
    }
}

enum AIError: Error {
    case requestFailed
    case invalidResponse
    case apiError(String)
} 