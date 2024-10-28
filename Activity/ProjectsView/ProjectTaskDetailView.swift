//
//  ProjectTaskDetailView.swift
//  Activity
//
//  Created by Vivian Wang on 2024/1/24.
//

import SwiftUI

struct ProjectTaskDetailView: View {
    var project: Project
    var task: Task
    @State private var name: String = ""
    var body: some View {
        Form {
            
            Section(header: Text("Time".localized)) {
                Text(task.startDate, style: .date)
            }
            
            
            Section(header: Text("Priority".localized)) {
                Text("Priority:  \(task.priority)")
            }
            
            Section(header: Text("Repeat".localized)) {
                ForEach(Array(task.repeatDays.sorted { $0.rawValue < $1.rawValue }), id: \.rawValue) {day in
                    Text(day.string)
                }
            }
            
            Section(header: Text("Tags".localized)) {
                ForEach(task.tags, id: \.self) { tag in
                    Text(tag)
                }
            }
            

        }
        .navigationBarTitle(task.name)
        .navigationBarItems(
            trailing:
                NavigationLink(destination: EditTaskDetailView(exercise: project, task: task)) {
                    Text("Edit".localized)
                }
        )
    }
}
