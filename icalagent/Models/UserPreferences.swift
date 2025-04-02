import Foundation

struct WorkHours: Codable {
    var startTime: Date
    var endTime: Date
    var workDays: Set<Int> // 1 = Sunday, 2 = Monday, etc.
    
    init(startTime: Date, endTime: Date, workDays: Set<Int>) {
        self.startTime = startTime
        self.endTime = endTime
        self.workDays = workDays
    }
    
    static let defaultWorkHours: WorkHours = {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        let startTime = calendar.date(from: components) ?? Date()
        
        components.hour = 17
        components.minute = 0
        let endTime = calendar.date(from: components) ?? Date()
        
        return WorkHours(
            startTime: startTime,
            endTime: endTime,
            workDays: [2, 3, 4, 5, 6] // Monday through Friday
        )
    }()
    
    enum CodingKeys: String, CodingKey {
        case startTime
        case endTime
        case workDays
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decode(Date.self, forKey: .endTime)
        let workDaysArray = try container.decode([Int].self, forKey: .workDays)
        workDays = Set(workDaysArray)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(Array(workDays), forKey: .workDays)
    }
}

struct RecurringTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var startTime: Date
    var duration: TimeInterval
    var frequency: Frequency
    var daysOfWeek: Set<Int> // 1 = Sunday, 2 = Monday, etc.
    var category: ScheduleCategory
    
    enum Frequency: String, Codable, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case biweekly = "Bi-Weekly"
        case monthly = "Monthly"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case startTime
        case duration
        case frequency
        case daysOfWeek
        case category
    }
    
    init(id: UUID = UUID(), title: String, description: String, startTime: Date, duration: TimeInterval, frequency: Frequency, daysOfWeek: Set<Int>, category: ScheduleCategory) {
        self.id = id
        self.title = title
        self.description = description
        self.startTime = startTime
        self.duration = duration
        self.frequency = frequency
        self.daysOfWeek = daysOfWeek
        self.category = category
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        startTime = try container.decode(Date.self, forKey: .startTime)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        frequency = try container.decode(Frequency.self, forKey: .frequency)
        let daysArray = try container.decode([Int].self, forKey: .daysOfWeek)
        daysOfWeek = Set(daysArray)
        category = try container.decode(ScheduleCategory.self, forKey: .category)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(duration, forKey: .duration)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(Array(daysOfWeek), forKey: .daysOfWeek)
        try container.encode(category, forKey: .category)
    }
}

class UserPreferences: ObservableObject {
    @Published var workHours: WorkHours
    @Published var recurringTasks: [RecurringTask]
    
    init(workHours: WorkHours = .defaultWorkHours, recurringTasks: [RecurringTask] = []) {
        self.workHours = workHours
        self.recurringTasks = recurringTasks
    }
    
    func addRecurringTask(_ task: RecurringTask) {
        recurringTasks.append(task)
    }
    
    func removeRecurringTask(_ task: RecurringTask) {
        recurringTasks.removeAll { $0.id == task.id }
    }
    
    func updateRecurringTask(_ task: RecurringTask) {
        if let index = recurringTasks.firstIndex(where: { $0.id == task.id }) {
            recurringTasks[index] = task
        }
    }
} 