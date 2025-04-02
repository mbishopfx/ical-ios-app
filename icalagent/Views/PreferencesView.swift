import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var preferences: UserPreferences
    @State private var showingAddTask = false
    @State private var selectedWorkDays: Set<Int> = []
    
    private let weekDays = [
        (1, "Sunday"),
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Work Hours")) {
                    DatePicker("Start Time", selection: $preferences.workHours.startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $preferences.workHours.endTime, displayedComponents: .hourAndMinute)
                    
                    Text("Work Days")
                        .font(.headline)
                    
                    ForEach(weekDays, id: \.0) { day in
                        Toggle(day.1, isOn: Binding(
                            get: { preferences.workHours.workDays.contains(day.0) },
                            set: { isOn in
                                if isOn {
                                    preferences.workHours.workDays.insert(day.0)
                                } else {
                                    preferences.workHours.workDays.remove(day.0)
                                }
                            }
                        ))
                    }
                }
                
                Section(header: Text("Recurring Tasks")) {
                    ForEach(preferences.recurringTasks) { task in
                        RecurringTaskRow(task: task)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            preferences.removeRecurringTask(preferences.recurringTasks[index])
                        }
                    }
                    
                    Button(action: { showingAddTask = true }) {
                        Label("Add Recurring Task", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Preferences")
            .sheet(isPresented: $showingAddTask) {
                AddRecurringTaskView()
            }
        }
    }
}

struct RecurringTaskRow: View {
    let task: RecurringTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title)
                .font(.headline)
            Text(task.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text(task.startTime, style: .time)
                Text("•")
                Text(task.frequency.rawValue)
                Text("•")
                Text("\(Int(task.duration / 60)) min")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AddRecurringTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var preferences: UserPreferences
    
    @State private var title = ""
    @State private var description = ""
    @State private var startTime = Date()
    @State private var duration: TimeInterval = 3600 // 1 hour
    @State private var frequency = RecurringTask.Frequency.daily
    @State private var selectedDays: Set<Int> = []
    @State private var category = ScheduleCategory.work
    
    private let weekDays = [
        (1, "Sunday"),
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    Picker("Category", selection: $category) {
                        ForEach(ScheduleCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Schedule")) {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    
                    Picker("Duration", selection: $duration) {
                        Text("30 minutes").tag(TimeInterval(1800))
                        Text("1 hour").tag(TimeInterval(3600))
                        Text("1.5 hours").tag(TimeInterval(5400))
                        Text("2 hours").tag(TimeInterval(7200))
                    }
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(RecurringTask.Frequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                }
                
                Section(header: Text("Days")) {
                    ForEach(weekDays, id: \.0) { day in
                        Toggle(day.1, isOn: Binding(
                            get: { selectedDays.contains(day.0) },
                            set: { isOn in
                                if isOn {
                                    selectedDays.insert(day.0)
                                } else {
                                    selectedDays.remove(day.0)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Add Recurring Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let task = RecurringTask(
                            title: title,
                            description: description,
                            startTime: startTime,
                            duration: duration,
                            frequency: frequency,
                            daysOfWeek: selectedDays,
                            category: category
                        )
                        preferences.addRecurringTask(task)
                        dismiss()
                    }
                    .disabled(title.isEmpty || selectedDays.isEmpty)
                }
            }
        }
    }
}

#Preview {
    PreferencesView()
        .environmentObject(UserPreferences())
} 