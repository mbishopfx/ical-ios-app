import Foundation
import SwiftUI

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var calendarName: String = "My Calendar"
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let aiService: AIService
    
    init(apiKey: String) {
        self.aiService = AIService(apiKey: apiKey)
    }
    
    func addEvent(_ event: CalendarEvent) {
        events.append(event)
    }
    
    func removeEvent(_ event: CalendarEvent) {
        events.removeAll { $0.id == event.id }
    }
    
    func generateICalFile() -> String {
        return ICalGenerator.generateICalFile(events: events, calendarName: calendarName)
    }
    
    func saveICalFile() {
        let icalString = generateICalFile()
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent("\(calendarName).ics")
        
        do {
            try icalString.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            errorMessage = "Failed to save calendar file: \(error.localizedDescription)"
        }
    }
    
    func generateEventSuggestions(prompt: String, categories: Set<ScheduleCategory>, preferences: UserPreferences) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let newEvents = try await aiService.generateEvents(from: prompt, categories: categories, preferences: preferences)
            events.append(contentsOf: newEvents)
        } catch {
            errorMessage = "Failed to generate events: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
} 