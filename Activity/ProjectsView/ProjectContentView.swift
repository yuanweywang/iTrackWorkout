//
//  ProjectContentView.swift
//  Activity
//
//  Created by Vivian Wang on 2024/1/24.
//  Comment by Yu-Ting
//

import SwiftUI
import SwiftData

/// Displays content for a specific project, including tasks and options to add, delete, or move tasks.
struct ProjectContentView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query var settingsList: [Settings]
    var settings: Settings? { settingsList.first }
    
    var exercise: Project
    @State private var isEditing = false
    @State private var selection = Set<UUID>()
    
    @State private var deleteDialogVisible = false
    @State private var moveDialogVisible = false
    
    @Environment(\.editMode) var editMode
    
    var body: some View {
        NavigationStack {
            if (exercise.tasks.isEmpty) {
                VStack {
                    Spacer()
                    Text("There are no tasks.")
                    NavigationLink("Add new task") {
                        NewTaskView(exercise: exercise)
                    }
                    Spacer()
                }
            }
            
            List(exercise.tasks, selection: $selection) { task in
                NavigationLink(destination: ProjectTaskDetailView(project:exercise, task: task)) {
                    Text(task.name)
                }
            }
            
        }
        .navigationTitle(exercise.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if editMode!.wrappedValue == .inactive {
                        NavigationLink(destination: NewTaskView(exercise: exercise)) {
                            Image(systemName: "plus")
                        }
                    } else {
                        Button {
                            deleteDialogVisible = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .disabled(selection.isEmpty)
                        .confirmationDialog(
                            "Are you sure you want to delete \(selection.count) tasks?",
                            isPresented: $deleteDialogVisible,
                            titleVisibility: .visible
                        ) {
                            Button("Delete", role: .destructive) {
                                let tasksToDelete = exercise.tasks.filter { selection.contains($0.id) }
                                exercise.tasks.removeAll { selection.contains($0.id) }
                                for task in tasksToDelete {
                                    modelContext.delete(task)
                                }
                                selection.removeAll()
                            }
                        }
                        
                        Button {
                            moveDialogVisible = true
                        } label: {
                            Text("Move".localized)
                        }
                        .disabled(selection.isEmpty)
                        .sheet(
                            isPresented: $moveDialogVisible
                        ) {
                            ChooseProjectView(title: "Choose Project".localized) { newProject in
                                guard let newProject = newProject else { return }
                                let tasksToMove = exercise.tasks.filter { selection.contains($0.id) }
                                exercise.tasks.removeAll { selection.contains($0.id) }
                                newProject.tasks.append(contentsOf: tasksToMove)
                                selection.removeAll()
                            }
                            .accentColor(settings?.accentColor.swiftuiAccentColor ?? .yellow)
                        }
                    }
                    EditButton()
                }
            }
        }
    }
    
    func deleteTasks(at offsets: IndexSet) {
        for offset in offsets {
            let task = exercise.tasks[offset]
            if let dataForTask = try? modelContext.fetch(FetchDescriptor<StopwatchData>()) {
                let filtered = dataForTask.filter { $0.taskId == task.id }
                for data in filtered {
                    modelContext.delete(data)
                }
            }
            modelContext.delete(task)
        }
        exercise.tasks.remove(atOffsets: offsets)
    }
}

/// View for selecting a project to move tasks to.
struct ChooseProjectView: View {
    var title: String
    var onProjectChosen: (Project?) -> ()
    
    @Query var projects: [Project]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Text(title)
            .font(.title)
            .padding()
        
        List(projects) { project in
            Button {
                dismiss()
                onProjectChosen(project)
            } label: {
                Text(project.name)
            }
        }
    }
}
