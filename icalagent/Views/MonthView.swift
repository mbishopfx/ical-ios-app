import SwiftUI

struct MonthView: View {
    @EnvironmentObject private var viewModel: CalendarViewModel
    @EnvironmentObject private var preferences: UserPreferences
    @State private var selectedCategories: Set<ScheduleCategory> = []
    @State private var showingCategoryPicker = false
    @State private var showingAIPrompt = false
    @State private var showingPreferences = false
    @State private var aiPrompt = ""
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Categories Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Schedule Categories")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ScheduleCategory.allCases) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategories.contains(category)
                                    ) {
                                        if selectedCategories.contains(category) {
                                            selectedCategories.remove(category)
                                        } else {
                                            selectedCategories.insert(category)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // AI Generation Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Generate Schedule")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            TextField("Describe your schedule preferences...", text: $aiPrompt, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                                .padding(.horizontal)
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding()
                            }
                            
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                            }
                            
                            Button {
                                Task {
                                    await viewModel.generateEventSuggestions(
                                        prompt: aiPrompt,
                                        categories: selectedCategories,
                                        preferences: preferences
                                    )
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "wand.and.stars")
                                    Text("Generate 30-Day Schedule")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(aiPrompt.isEmpty || viewModel.isLoading)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Events Preview Section
                    if !viewModel.events.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Generated Events")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal)
                            
                            ForEach(viewModel.events) { event in
                                EventPreviewRow(event: event)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Month Planner")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button(action: { showingPreferences = true }) {
                            Label("Preferences", systemImage: "gear")
                        }
                        
                        Button(action: { viewModel.saveICalFile() }) {
                            Label("Export Calendar", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingPreferences) {
                PreferencesView()
            }
        }
    }
}

struct CategoryButton: View {
    let category: ScheduleCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                Text(category.rawValue)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 100)
            .padding()
            .background(isSelected ? Color(category.color).opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? Color(category.color) : .primary)
            .cornerRadius(12)
        }
    }
}

struct EventPreviewRow: View {
    let event: CalendarEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.title)
                    .font(.headline)
                Spacer()
                Text(event.startDate, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
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
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    MonthView()
        .environmentObject(CalendarViewModel(apiKey: Config.openAIKey))
        .environmentObject(UserPreferences())
} 
