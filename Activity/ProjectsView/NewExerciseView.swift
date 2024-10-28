//
//  NewExerciseView.swift
//  Activity
//
//  Created by Vivian Wang on 2024/1/24.
//

import SwiftUI
import SwiftData

struct NewExerciseView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var context
    @Query() var existingProjects: [Project]
    
    @State private var name: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Project Name".localized)) {
                    TextField("", text: $name)
                    if existingProjects.contains(where: { $0.name.localizedLowercase == name.localizedLowercase }) {
                        Text("A project with the same name already exists".localized).foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationBarTitle("New Project")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel".localized) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save".localized) {
                    let exercise = Project(name: name, startDate: .now, priority: 2)
                    context.insert(exercise)
                    try! context.save()
                    dismiss()
                }
                .disabled(name.isEmpty || existingProjects.contains(where: { $0.name.localizedLowercase == name.localizedLowercase }))
            }
        }
    }
}
