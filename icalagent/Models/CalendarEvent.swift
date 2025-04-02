import Foundation

struct CalendarEvent: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var startDate: Date
    var endDate: Date
    var location: String?
    var attendees: [String]?
    var category: String?
    var isAllDay: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case startDate
        case endDate
        case location
        case attendees
        case category
        case isAllDay
    }
    
    init(id: UUID = UUID(), title: String, description: String, startDate: Date, endDate: Date, location: String? = nil, attendees: [String]? = nil, category: String? = nil, isAllDay: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.attendees = attendees
        self.category = category
        self.isAllDay = isAllDay
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle UUID string or UUID object
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = UUID(uuidString: idString) ?? UUID()
        } else {
            id = try container.decode(UUID.self, forKey: .id)
        }
        
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        
        // Handle date strings
        let dateFormatter = ISO8601DateFormatter()
        if let startDateString = try? container.decode(String.self, forKey: .startDate),
           let date = dateFormatter.date(from: startDateString) {
            startDate = date
        } else {
            startDate = try container.decode(Date.self, forKey: .startDate)
        }
        
        if let endDateString = try? container.decode(String.self, forKey: .endDate),
           let date = dateFormatter.date(from: endDateString) {
            endDate = date
        } else {
            endDate = try container.decode(Date.self, forKey: .endDate)
        }
        
        location = try? container.decode(String.self, forKey: .location)
        attendees = try? container.decode([String].self, forKey: .attendees)
        category = try? container.decode(String.self, forKey: .category)
        
        // Handle isAllDay property
        if let isAllDayValue = try? container.decode(Bool.self, forKey: .isAllDay) {
            isAllDay = isAllDayValue
        } else {
            isAllDay = false
        }
    }
} 