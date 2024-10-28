//
//  Exercise.swift
//  Activity
//
//  Created by Sandro  on 20.01.24.
//

import Foundation
import SwiftData

@Model
class Project: Identifiable {
    var id: UUID  // Unique identifier for Identifiable protocol
    var name: String
    var tasks: [Task]
    var startDate: Date  // Date type
    var priority: Int
    
    init(id: UUID = UUID(), name: String, tasks: [Task] = [], startDate: Date, priority: Int = 2) {
        self.id = id
        self.name = name
        self.tasks = tasks
        self.startDate = startDate
        self.priority = priority
    }
}

@Model
class Task: Identifiable {
    var id: UUID  // Unique identifier for Identifiable protocol
    
    var name: String
    var tags: [String]
    var startDate: Date  // Date type
    var priority: Int
    var repeatDays: Set<DayOfWeek>
    
    init(id: UUID = UUID(), name: String, tags: [String] = [], startDate: Date, priority: Int = 2, repeatDays: Set<DayOfWeek> = Set()) {
        self.id = id
        self.name = name
        self.tags = tags
        self.startDate = startDate
        self.priority = priority
        self.repeatDays = repeatDays
    }
}
