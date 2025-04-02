//
//  icalagentApp.swift
//  icalagent
//
//  Created by Matthew Bishop on 3/30/25.
//

import SwiftUI

@main
struct icalagentApp: App {
    @StateObject private var viewModel: CalendarViewModel
    
    init() {
        let viewModel = CalendarViewModel(apiKey: Config.openAIKey)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
