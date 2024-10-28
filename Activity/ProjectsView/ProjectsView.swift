//
//  ProjectsView.swift
//  Activity
//
//  Created by TimurSmoev on 1/10/24.
// Commented by Yu-Ting
//

import SwiftUI
import SwiftData

/// Displays a list of projects, supports searching, and allows navigation to project details.
struct ProjectsView: View {
    @Environment(\.modelContext) var context
    @Environment(\.editMode) var editMode
    @Query(sort: [SortDescriptor(\Project.priority, order: .reverse), SortDescriptor(\Project.name)]) var projects: [Project]
    
    @State private var sortOrder = SortDescriptor(\Project.name)
    @State private var isSearching = false
    @State private var searchTerm = ""
    private var searchResults: [SearchResult] {
        var result: [Project: SearchResult] = [:]
        
        let lowercaseSearchTerm = searchTerm.localizedLowercase
        
        for project in projects {
            if project.name.localizedLowercase.contains(lowercaseSearchTerm) {
                result[project] = SearchResult(project: project, tasks: [], tags: [], findReasons: [.project])
            }
            for task in project.tasks {
                if task.name.localizedLowercase.contains(lowercaseSearchTerm) {
                    var sr = result[project] ?? SearchResult(project: project, tasks: [], tags: [], findReasons: [])
                    sr.tasks.insert(task)
                    sr.findReasons.insert(.task(task.id))
                    result[project] = sr
                }
                for tag in task.tags {
                    if tag.localizedLowercase.contains(lowercaseSearchTerm) {
                        var sr = result[project] ?? SearchResult(project: project, tasks: [], tags: [], findReasons: [])
                        sr.tasks.insert(task)
                        sr.tags.insert(tag)
                        sr.findReasons.insert(.tag(tag))
                        result[project] = sr
                    }
                }
            }
        }
        
        return Array(result.values)
    }
    
    var body: some View {
        NavigationStack {
            
            Group {
                if !isSearching {
                    if (projects.isEmpty) {
                        VStack {
                            Spacer()
                            Text("There are no projects.")
                            NavigationLink("Add new project") {
                                NewExerciseView()
                            }
                            Spacer()
                        }
                    }
                    
                    List {
                        ForEach(projects) { exercise in
                            NavigationLink(destination: ProjectContentView(exercise: exercise)) {
                                ExerciseCell(exercise: exercise)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                for task in projects[index].tasks {
                                    if let dataForTask = try? context.fetch(FetchDescriptor<StopwatchData>()) {
                                        let filtered = dataForTask.filter { $0.taskId == task.id }
                                        for data in filtered {
                                            context.delete(data)
                                        }
                                    }
                                    context.delete(task)
                                }
                                context.delete(projects[index])
                            }
                        }
                        .padding()
                        
                    }
                } else if searchTerm.isEmpty {
                    Text("Start typing to search".localized)
                } else {
                    List(searchResults) { result in
                        NavigationLink {
                            ProjectContentView(exercise: result.project)
                        } label: {
                            ProjectSearchResultView(result: result)
                        }
                        
                    }
                }
            }
            .navigationTitle("Projects")
            .navigationBarItems(
                trailing:
                    NavigationLink(destination: NewExerciseView()) {
                        Image(systemName: "plus")
                    }
            )
            .searchable(text: $searchTerm, isPresented: $isSearching)
        }
    }
}

/// Represents a view for displaying a single search result.
struct ProjectSearchResultView: View {
    var result: SearchResult
    
    var body: some View {
        VStack(alignment: .leading) {
            if result.findReasons.contains(.project) {
                Text(result.project.name)
                    .foregroundStyle(Color.accentColor)
                    .font(.title)
            } else {
                Text(result.project.name)
                    .font(.title)
            }
            ForEach(Array(result.tasks.sorted { $0.id < $1.id })) { task in
                VStack(alignment: .leading) {
                    if result.findReasons.contains(.task(task.id)) {
                        Text("Task: \(task.name)")
                            .foregroundStyle(Color.accentColor)
                    } else {
                        Text("Task: \(task.name)")
                    }
                    
                    let foundTags = task.tags.filter { result.tags.contains($0) }
                    if !foundTags.isEmpty {
                        Group {
                            Text("Tags: ".localized) + Text(foundTags.joined(separator: ", ")).foregroundStyle(Color.accentColor)
                        }
                        .padding([.leading])
                    }
                }.padding([.leading])
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct SearchResult: Identifiable {
    var id: UUID = UUID()
    
    var project: Project
    var tasks: Set<Task>
    var tags: Set<String>
    var findReasons: Set<SearchResultFindReason>
}

enum SearchResultFindReason: Hashable {
    case project
    case task(UUID)
    case tag(String)
}
