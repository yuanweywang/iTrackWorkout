//
//  ActivityApp.swift
//  Activity
//
//  Created by TimurSmoev on 12/24/23.
//  Edited by Yu-Ting on 27.01.24.
//

import SwiftUI
import SwiftData

@main
struct ActivityApp: App {
    
    /// The main container for the app's data model, including projects, settings, and stopwatch data.
    let container: ModelContainer = ModelContainer.initializeModelContainer()

    var body: some Scene {
        /// The main UI scene of the app, hosting the ContentView.
        WindowGroup {
            ContentView()
        }
        .modelContainer(container) // Injecting the model container into the SwiftUI environment.
    }
}

extension ModelContainer {
    /// Initializes and returns a ModelContainer instance, safely handling any potential errors.
    static func initializeModelContainer() -> ModelContainer {
        let schema = Schema([
            Project.self,
            Settings.self,
            StopwatchData.self
        ])
        
        let config = ModelConfiguration()
        
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            /// Proper error handling could be implemented here.
            fatalError("Failed to initialize the model container: \(error)")
        }
    }
}
