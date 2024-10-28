//
//  TaskDetailView.swift
//  GymTime
//
//  Created by JieTing on 2024/1/15.
//

import SwiftUI
import SwiftData

struct TaskDetailPage: View {
    var date: Date
    
    var body: some View {
        let dateFormatter = { () -> DateFormatter in
            let df = DateFormatter()
            df.dateStyle = .medium
            return df
        }()
        
        TaskDetailView(date: date)
            .navigationBarTitle(dateFormatter.string(from: date), displayMode: .inline)
            .navigationBarItems(
                trailing:
                    NavigationLink(destination: NewExerciseView()) {
                        Image(systemName: "plus")
                    }
            )
            .padding()
    }
}

struct TaskDetailView: View {
    var date: Date
    var maxViewDayCnt = 1 // use for count maxViewDate
    
    @Environment(\.modelContext) var context
    
    @State var showRestartStopwatchConfirmation = false
    @State var navigatingToStopwatch = false
    @State var continuingStopwatchDatum: StopwatchData?
    
    @Query var stopwatchData: [StopwatchData]
    @Query var projects: [Project]
    private var allTasks: [Task] {
        projects.flatMap { $0.tasks }
    }
    private var tasksToday: [Task] {
        let componentsOfDate = Calendar.current.dateComponents([.day, .month, .year], from: date)
        return allTasks.filter { task in
            if task.startDate > Calendar.current.date(byAdding: .day, value: 1, to: date)! {
                // Task starts after today, therefore we're not interested
                return false
            }
            
            let componentsOfTask = Calendar.current.dateComponents([.day, .month, .year], from: task.startDate)
            if componentsOfDate == componentsOfTask {
                // If the task starts today, then it is okay
                return true
            }
            
            var weekdayOfDate = (Calendar.current.dateComponents([.weekday], from: date).weekday! + 6) % 7
            if weekdayOfDate == 0 { weekdayOfDate = 7 }
            let weekday = DayOfWeek(rawValue: weekdayOfDate)!
            if task.repeatDays.contains(weekday) {
                // The task repeats today, so it's okay
                return true
            }
            
            // The task doesn't repeat today, don't use it
            return false
        }
    }
    
    init(date: Date) {
        self.date = date
        let taskIds = tasksToday.map { $0.id }
        let viewDateComponents = Calendar.current.dateComponents(
            [.day, .month, .year],
            from: date
        )
        let minViewDate = Calendar.current.date(from: viewDateComponents)!
        let maxViewDate = Calendar.current.date(byAdding: .day, value: 1, to: minViewDate)!
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(tasksToday.indices, id: \.self) { index in
                exerciseItemView(tasksToday[index])
            }
            
            if tasksToday.isEmpty {
                Spacer()
                
                Text("No tasks for this day".localized)
                    .font(.title)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
    }

    private func exerciseItemView(_ item: Task) -> some View {
        let stopwatchDatum = stopwatchData.filter { $0.taskId == item.id && Calendar.current.isDate($0.completionDate, inSameDayAs: date) }.first
        
        let label = VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                }
                Spacer()
                if let stopwatchDatum = stopwatchDatum {
                    Text(String(format: "Time: %@".localized, stopwatchDatum.totalInterval.formattedTime()))
                        .padding([.horizontal])
                }
                Image(systemName: stopwatchDatum != nil ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(stopwatchDatum != nil ? .green : .gray)
            }
            
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        
        if stopwatchDatum == nil {
            return AnyView(
                NavigationLink(destination: Stopwatch(taskId: item.id, date: date)) {
                    label
                }
            )
        }
        else {
            return AnyView(
                Button {
                    showRestartStopwatchConfirmation = true
                } label: {
                    label
                        .confirmationDialog(
                            "Do you want to restart or continue the tracking?".localized,
                            isPresented: $showRestartStopwatchConfirmation,
                            titleVisibility: .visible) {
                                Button(role: .destructive) {
                                    discardStopwatchData(for: item)
                                    navigateToStopwatch()
                                } label: {
                                    Text("Discard data and restart".localized)
                                }
                                Button {
                                    navigateToStopwatch(continuingWith: stopwatchDatum)
                                } label: {
                                    Text("Continue tracking".localized)
                                }
                            }
                }.navigationDestination(isPresented: $navigatingToStopwatch) {
                    Stopwatch(taskId: item.id, date: date, updating: continuingStopwatchDatum)
                }
            )
        }
    }
    
    private func discardStopwatchData(for task: Task) {
        let stopwatchDataForTask = stopwatchData.filter { $0.taskId == task.id }
        for datum in stopwatchDataForTask {
            context.delete(datum)
        }
    }
    private func navigateToStopwatch(continuingWith stopwatchData: StopwatchData? = nil) {
        continuingStopwatchDatum = stopwatchData
        navigatingToStopwatch = true
    }
}

