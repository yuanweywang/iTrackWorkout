//
//  AccoutView.swift
//  Activity
//
//  Created by TimurSmoev on 12/24/23.
//  Refactored and commented on by Yu-Ting
//

import SwiftUI
import SwiftData

/// Represents the home screen of the application, showing a welcome message and task details for the day.
struct HomeView: View {
    @Query var settingsList: [Settings]
    
    /// The first `Settings` object from `settingsList`, if available.
    /// Used to retrieve user-specific settings such as the user's name.
    private var settings: Settings? { settingsList.first }
    
    /// The localized welcome title, personalized if a first name is set in settings.
    private var welcomeTitle: String {
        settings?.firstName.map {
            String(format: NSLocalizedString("WelcomeWithName", comment: "Welcome message with user's name"), $0)
        } ?? NSLocalizedString("Welcome", comment: "Generic welcome message")
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if settings == nil {
                    hintSection
                }
                
                Text("Today").font(.title)
                
                TaskDetailView(date: Date())
            }
            .navigationTitle(welcomeTitle)
        }
    }
    
    /// The hint section shown when no settings are available, suggesting the user to customize the app.
    private var hintSection: some View {
        Group {
            HStack {
                Image(systemName: "info.circle.fill")
                VStack(alignment: .leading) {
                    Text("Hint".localized)
                        .multilineTextAlignment(.leading)
                        .font(.title2)
                    Text("Consider going to the Settings tab to customize the application, set your name or enable notifications".localized)
                }
            }
            .padding()
            .background(Color.accentColor.opacity(0.4))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .inset(by: 1)
                    .stroke(Color.accentColor.opacity(0.6), lineWidth: 1)
            )
            .padding()
        }
    }
}
#Preview {
    HomeView()
}
