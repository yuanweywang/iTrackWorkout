//
//  ContentView.swift
//  Activity
//
//  Created by TimurSmoev on 12/24/23.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query var settingsList: [Settings]
    var settings: Settings? { settingsList.first }
    
    var body: some View {
        // Main content view of the app, organized as a TabView for navigation between different sections.
        TabView {
            // Home tab
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            // Calendar tab
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
            
            // Projects tab
            ProjectsView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Projects")
                }
            
            // Summary tab
            ActivityListView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Summary")
                }
            
            // Setting tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(settings?.accentColor.swiftuiAccentColor ?? .yellow)
        .font(.system(size: settings?.dynamicFontSize ?? 17))
    }
}

#Preview {
    ContentView()
}
