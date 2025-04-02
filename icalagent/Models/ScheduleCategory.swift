import Foundation

enum ScheduleCategory: String, CaseIterable, Identifiable, Codable {
    case work = "Work Schedule"
    case kids = "Kids Schedule"
    case dinner = "Dinner Schedule"
    case hobbies = "Hobbies"
    case goals = "Goals"
    case fitness = "Fitness"
    case social = "Social"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .kids: return "figure.child"
        case .dinner: return "fork.knife"
        case .hobbies: return "paintbrush.fill"
        case .goals: return "target"
        case .fitness: return "figure.run"
        case .social: return "person.2.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .work: return "blue"
        case .kids: return "green"
        case .dinner: return "orange"
        case .hobbies: return "purple"
        case .goals: return "red"
        case .fitness: return "pink"
        case .social: return "yellow"
        case .other: return "gray"
        }
    }
} 