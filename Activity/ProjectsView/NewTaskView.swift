//
//  NewTaskView.swift
//  Activity
//
//  Created by Vivian Wang on 2024/1/24.
//

import SwiftUI
import SwiftData

struct NewTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var context
    
    @Query var settingsList: [Settings]
    var settings: Settings? { settingsList.first }
    
    var exercise: Project
    @State private var name: String = ""
    @State private var startDate: Date = .now
    @State private var priority: Int = 2
    @State private var newTag: String = ""
    @State private var tags: [String] = []
    @State private var showNewTagPopup = false
    @State private var repeatDays = Set<DayOfWeek>()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task".localized)) {
                    TextField("Name".localized, text: $name)
                    if exercise.tasks.contains(where: { $0.name.localizedLowercase == name.localizedLowercase }) {
                        Text("A task with the same name already exists".localized).foregroundStyle(.red)
                    }
                    DatePicker("Start Date".localized, selection: $startDate, displayedComponents: .date)
                    NavigationLink {
                        RepeatDaysChoice(repeatDays: $repeatDays)
                    } label: {
                        HStack(alignment: .lastTextBaseline) {
                            Text("Repeat".localized)
                            Spacer()
                            if repeatDays.isEmpty {
                                Text("Never".localized)
                            } else if repeatDays == Set<DayOfWeek>([.monday, .tuesday, .wednesday, .thursday, .friday]) {
                                Text("Every Weekday".localized)
                            } else if repeatDays == Set<DayOfWeek>([.saturday, .sunday]) {
                                Text("Every Weekend Day".localized)
                            } else if repeatDays == Set(DayOfWeek.all) {
                                Text("Every Day".localized)
                            } else {
                                Text(
                                    repeatDays
                                        .sorted(by: { $0.rawValue < $1.rawValue })
                                        .lazy
                                        .map { $0.shortString }
                                        .joined(separator: ", ")
                                )
                            }
                        }
                    }
                }
                
                Section("Priority".localized) {
                    Picker("Priority".localized, selection: $priority) {
                        Text("Meh".localized).tag(1)
                        Text("Maybe".localized).tag(2)
                        Text("Must".localized).tag(3)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Tags".localized)) {
                    ForEach(0..<tags.count, id: \.self) { index in
                        Text(tags[index])
                    }
                    .onDelete { indexSet in
                        tags.remove(atOffsets: indexSet)
                    }
                    Button(action: {
                        showNewTagPopup.toggle()
                    }) {
                        Text("Add tag".localized)
                    }
                }
            }
        }
        .navigationBarTitle("New Task".localized)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button("Cancel".localized) {
                dismiss()
            },
            trailing: Button("Save".localized) {
                let newTask = Task(name: name, tags: tags, startDate: startDate, priority: 2, repeatDays: repeatDays)
                exercise.tasks.append(newTask)
                try! context.save()
                dismiss()
            }.disabled(name.isEmpty || exercise.tasks.contains { $0.name.localizedLowercase == name.localizedLowercase })
        )
        .sheet(isPresented: $showNewTagPopup) {
            TagChoice(initial: tags, onTagsSelected: { selectedTags in
                showNewTagPopup = false
                tags.removeAll()
                tags.append(contentsOf: selectedTags)
            })
            .accentColor(settings?.accentColor.swiftuiAccentColor ?? .yellow)
        }
    }
}
