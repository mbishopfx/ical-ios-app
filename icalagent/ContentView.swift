//
//  ContentView.swift
//  icalagent
//
//  Created by Matthew Bishop on 3/30/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: CalendarViewModel
    @State private var selectedTab = 0
    @State private var showingAddEvent = false
    @State private var showingAIPrompt = false
    @State private var aiPrompt = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Month View Tab
            MonthView()
                .tabItem {
                    Label("Month", systemImage: "calendar")
                }
                .tag(0)
            
            // Events List Tab
            EventsListView(showingAddEvent: $showingAddEvent)
                .tabItem {
                    Label("Events", systemImage: "list.bullet")
                }
                .tag(1)
        }
    }
}

struct EventsListView: View {
    @EnvironmentObject private var viewModel: CalendarViewModel
    @Binding var showingAddEvent: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Calendar Name")) {
                    TextField("Calendar Name", text: $viewModel.calendarName)
                }
                
                Section(header: Text("Events")) {
                    ForEach(viewModel.events) { event in
                        EventRow(event: event)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.removeEvent(viewModel.events[index])
                        }
                    }
                }
            }
            .navigationTitle("Events")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button(action: { showingAddEvent = true }) {
                            Label("Add Event", systemImage: "plus")
                        }
                        
                        Button(action: { viewModel.saveICalFile() }) {
                            Label("Export Calendar", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView()
            }
        }
    }
}

struct EventRow: View {
    let event: CalendarEvent
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(event.title)
                .font(.headline)
            Text(event.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                Text(event.startDate, style: .date)
                Text("-")
                Text(event.endDate, style: .date)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: CalendarViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var location = ""
    @State private var attendees = ""
    @State private var category = ""
    @State private var isAllDay = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    Toggle("All Day", isOn: $isAllDay)
                }
                
                Section(header: Text("Date & Time")) {
                    DatePicker("Start", selection: $startDate, displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
                    DatePicker("End", selection: $endDate, displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
                }
                
                Section(header: Text("Additional Details")) {
                    TextField("Location", text: $location)
                    TextField("Attendees (comma-separated)", text: $attendees)
                    TextField("Category", text: $category)
                }
            }
            .navigationTitle("Add Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let event = CalendarEvent(
                            title: title,
                            description: description,
                            startDate: startDate,
                            endDate: endDate,
                            location: location.isEmpty ? nil : location,
                            attendees: attendees.isEmpty ? nil : attendees.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
                            category: category.isEmpty ? nil : category,
                            isAllDay: isAllDay
                        )
                        viewModel.addEvent(event)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct AIPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: CalendarViewModel
    @EnvironmentObject private var preferences: UserPreferences
    @Binding var prompt: String
    @State private var selectedCategories: Set<ScheduleCategory> = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Categories")) {
                    ForEach(ScheduleCategory.allCases) { category in
                        Toggle(category.rawValue, isOn: Binding(
                            get: { selectedCategories.contains(category) },
                            set: { isSelected in
                                if isSelected {
                                    selectedCategories.insert(category)
                                } else {
                                    selectedCategories.remove(category)
                                }
                            }
                        ))
                    }
                }
                
                Section(header: Text("Describe Your Calendar")) {
                    TextEditor(text: $prompt)
                        .frame(height: 100)
                }
                
                if viewModel.isLoading {
                    Section {
                        ProgressView()
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Generate with AI")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        Task {
                            await viewModel.generateEventSuggestions(prompt: prompt, categories: selectedCategories, preferences: preferences)
                            dismiss()
                        }
                    }
                    .disabled(prompt.isEmpty || viewModel.isLoading || selectedCategories.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CalendarViewModel(apiKey: Config.openAIKey))
        .environmentObject(UserPreferences())
}
