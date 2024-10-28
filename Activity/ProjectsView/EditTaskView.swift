//
//  EditTaskView.swift
//  Activity
//
//  Created by Vivian Wang on 2024/1/24.
//

import SwiftUI

struct EditTaskView: View {
    @State private var name: String = ""

    var task: Task

    var body: some View {
        Form {
            Section(header: Text("Task Name".localized)) {
                Text(task.name)
                Text(task.startDate, style: .date)
                Text("Priority:  \(task.priority)")
            }
            
            Section(header: Text("Tags".localized)) {
                ForEach(task.tags, id: \.self) { tag in
                    Text(tag)
                }
            }
        }
    }
}
