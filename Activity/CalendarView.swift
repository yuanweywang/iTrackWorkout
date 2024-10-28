//
//  CalendarView.swift
//  GymTime
//
//  Created by JieTing on 2024/1/15.
//  Commented by Yu-Ting
//

import SwiftUI
import SwiftData

// MARK: - Control Panel Rectangle Definition

/// Represents the rectangle of a control panel button with an associated view index.
struct controlPanelRect: Equatable {
    let viewIdx: Int
    let rect: CGRect
}

/// PreferenceKey to collect control panel rectangles.
struct controlPanelRectKey: PreferenceKey {
    typealias Value = [controlPanelRect]
    static var defaultValue: [controlPanelRect] = []
    static func reduce(value: inout [controlPanelRect], nextValue: () -> [controlPanelRect]) {
        value.append(contentsOf: nextValue())
    }
}

// MARK: - Control Panel Button View

/// View for a button in the control panel.
struct ctrlPanelBtnView: View {
    @Binding var activeBtn: Int
    let idx: Int
    let viewStyle = ["Cal.", "List."]
    
    var body: some View {
        Text("\(viewStyle[idx])")
            .padding(3)
            .background(ctrlPanelBtnSetrView(idx: idx))
    }
}

/// Sets the geometry for a control panel button.
struct ctrlPanelBtnSetrView: View {
    let idx: Int
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.clear)
                .preference(key: controlPanelRectKey.self,
                            value: [controlPanelRect(viewIdx: self.idx, rect: geometry.frame(in: .named("controlPanelZStack")))])
        }
    }
}

// MARK: - Control Panel View

/// View for the control panel, including navigation and style toggle.
struct controlPanelView: View {
    
    @Binding var styleIdx: Int
    @Binding var currentMonth: Date
    
    @State private var rects: [CGRect] = Array<CGRect>(repeating: CGRect(), count: 12)
        
    var body: some View {
        // Controls for changing the current month.
        HStack {
            Button(action: { self.changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
            }
            Spacer()
            
            Text("\(currentMonth, formatter: DateFormatter.monthAndYear)")
                .font(.headline)
            Spacer()
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.8))
                    .frame(width: rects[styleIdx].size.width, height: rects[styleIdx].size.height)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 5.0).foregroundColor(.accentColor)
                    )
                    .offset(x: rects[styleIdx].minX, y: rects[styleIdx].minY)
                    .animation(.easeInOut(duration: 0.35), value: styleIdx)
                
                HStack{
                    ForEach(0...1, id: \.self) { col in
                        ctrlPanelBtnView(activeBtn: $styleIdx, idx: col)
                    }
                }
                
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            .coordinateSpace(name: "controlPanelZStack")
            .onTapGesture { styleIdx = (styleIdx + 1) % 2 }
            
            Spacer()
            Button(action: { self.changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
        .onPreferenceChange(controlPanelRectKey.self) { preferences in
            for p in preferences {
                self.rects[p.viewIdx] = p.rect
            }
        }
    }
    
    /// Changes the current month displayed.
    func changeMonth(by amount: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: amount, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

// MARK: - CalendarView Main View

/// Main calendar view for displaying and interacting with dates and tasks.
struct CalendarView: View {
    @State private var currentMonth = Date()
    private let calendar = Calendar.current
    @State private var styleIdx: Int = 0
    
    @Query var projects: [Project]

    /// Titles for days of the week.
    private let daysOfWeek = DayOfWeek.all

    var body: some View {
        /// Main navigation view for the calendar.
        NavigationStack {
            VStack {
                controlPanelView(styleIdx: $styleIdx, currentMonth: $currentMonth)
                
                if styleIdx == 1 {
                    ListView(currentMonth: currentMonth)
                }
                else{
                    
                    // Displaying days of the week.
                    HStack {
                        ForEach(daysOfWeek) { day in
                            Text(day.shortString)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    ScrollView{
                        
                        // Displaying month calendar.
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                            // show empty day
                            let nofec = Int(numberOfEmptyCells(at: currentMonth))
                            ForEach(100..<100+nofec, id: \.self) { i in
                                VStack{
                                    Text("")
                                }
                            }
                            
                            // show date
                            ForEach(1...daysInMonth(date: currentMonth), id: \.self) { day in
                                let dateInDay = Date.from(
                                    year: Calendar.current.dateComponents([.year], from: currentMonth).year!,
                                    month: Calendar.current.dateComponents([.month], from: currentMonth).month!,
                                    day: day
                                )
                                DayView(date: dateInDay)
                                
                            }
                        }
                    }
                }
            }
            .padding([.leading, .trailing])
            .safeAreaPadding()
        }
    }
    
    /// Function to calculate how many days in first week before first day in the months.
    func numberOfEmptyCells(at date: Date) -> Int {
        let firstDayOfMonth = calendar.date(from: Calendar.current.dateComponents([.year, .month], from: date))!
        /// Sunday is 1, Monday is 2, Tuesday is 3
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        /// Add 5: Sunday is 6, Monday is 7, Tuesday is 8
        /// Mod 7: Sunday is 6, Monday is 0, Tuesday is 1
        /// If the first day of the month is Monday, we need 0 empty cells
        /// If the first day of the month is Tuedsay, we need 1 empty cell
        /// ...
        /// If the first day of the month is Sunday, we need 6 empty cells
        return (weekday + 5) % 7 /// Count rest days in a week.
    }
}

/// Function to calculate how many days in a month.
func daysInMonth(date: Date) -> Int {
    let range = Calendar.current.range(of: .day, in: .month, for: date)
    return range?.count ?? 30
}

struct ListView: View {
    var currentMonth: Date
    @Query var projects: [Project]
    @Query var tags: [Tag]
    
    @State var isShowingPopover: Bool = false
    
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

    private var allTasks: [Task] {
        projects.flatMap { $0.tasks }
    }
    
    func tasksInDay(date: Date) -> [Task] {
        let componentsOfDate = Calendar.current.dateComponents([.day, .month, .year], from: date)
        return allTasks.filter { task in
            if task.startDate > Calendar.current.date(byAdding: .day, value: 1, to: date)! {
                // Task starts after today, therefore we're not interested.
                return false
            }
            
            let componentsOfTask = Calendar.current.dateComponents([.day, .month, .year], from: task.startDate)
            if componentsOfDate == componentsOfTask {
                /// If the task starts today, then it is okay.
                return true
            }
            
            var weekdayOfDate = (Calendar.current.dateComponents([.weekday], from: date).weekday! + 6) % 7
            if weekdayOfDate == 0 { weekdayOfDate = 7 }
            let weekday = DayOfWeek(rawValue: weekdayOfDate)!
            if task.repeatDays.contains(weekday) {
                // The task repeats today, so it's okay.
                return true
            }
            
            /// The task doesn't repeat today, don't use it.
            return false
        }
    }
    
    var dayInMonth: [Date] {(1...daysInMonth(date: currentMonth)).compactMap {
        Date.from(
            year: Calendar.current.dateComponents([.year], from: currentMonth).year!,
            month: Calendar.current.dateComponents([.month], from: currentMonth).month!,
            day: $0
        )}}
    
    var taskInMonth: [(Date, [Task])] {dayInMonth.compactMap { ($0, tasksInDay(date: $0))}.filter { !$0.1.isEmpty}}
    
    var body: some View {
        VStack(){
            ZStack{
                HStack{
                    TextField("Type to search...".localized, text: $searchTerm)
                        .padding(7)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal, 10)
                    
                    
                    Button(action: {
                        self.isShowingPopover = true
                    }) {
                        Text("Filter")
                    }
                    .padding()
                }
                .padding([.bottom])
                
                if isShowingPopover {
                    HStack {
                        
                        Spacer()
                        
                        Text("Tags: ")
                            .font(.headline)
                        
                        Picker(selection: $searchTerm, label: Text("choice")) {
                            if tags.isEmpty{
                                Text("No tag exists").tag("")
                            }else{
                                Text("Choose tag").tag("")
                                ForEach(0..<tags.count) { index in
                                    Text(tags[index].name).tag(tags[index].name)
                                }
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Spacer()
                        
                        Button(action: {
                            self.isShowingPopover = false
                            self.searchTerm = ""
                        })
                        {
                            Image(systemName: "xmark.circle.fill").imageScale(.large)
                        }
                        .padding()
                        
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
            }
            
            
            Group {
                if searchTerm.isEmpty {
                    ScrollView{
                        VStack{
                            ForEach(taskInMonth, id: \.0.self) { date, tasks in
                                ListDayView(date: date, tasks: tasks)
                            }
                        }
                    }
                } else if !searchResults.isEmpty {
                    List(searchResults) { result in
                        NavigationLink {
                            ProjectContentView(exercise: result.project)
                        } label: {
                            ProjectSearchResultView(result: result)
                        }
                    }
                    .listStyle(InsetListStyle())
                    .background(Color.white)
                }
                else {
                    Text("Nothing match !!".localized)
                }
            }
        }
        
    }
}

struct ListDayView: View {
    var date: Date
    var tasks: [Task]
    
    @Query var stopwatchData: [StopwatchData]
    
    var body: some View {
        VStack {
            let dateFormatter = { () -> DateFormatter in
                let df = DateFormatter()
                df.dateStyle = .medium
                return df
            }()
            
            HStack{
                Text("\(dateFormatter.string(from: date))")
                    .font(.system(size: 15))
                    .font(.headline)
                Spacer()
            }
            
            ForEach(tasks, id: \.self) { task in
                let stopwatchData = stopwatchData.filter { $0.taskId == task.id && Calendar.current.isDate($0.completionDate, inSameDayAs: date) }.first
                NavigationLink(destination: Stopwatch(taskId: task.id, date: date)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(task.name)
                                .font(.headline)
                        }
                        Spacer()
                        if let stopwatchData = stopwatchData {
                            Text(String(format: "Time: %@".localized, stopwatchData.totalInterval.formattedTime()))
                                .padding([.horizontal])
                        }
                        Image(systemName: stopwatchData != nil ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(stopwatchData != nil ? .green : .gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
    }
}

struct DayView: View {
    var date: Date
    @Query var projects: [Project]
    @Query var stopwatchData: [StopwatchData]

    private var allTasks: [Task] {
        projects.flatMap { $0.tasks }
    }
    private var tasksToday: [Task] {
        let componentsOfDate = Calendar.current.dateComponents([.day, .month, .year], from: date)
        return allTasks.filter { task in
            if task.startDate > Calendar.current.date(byAdding: .day, value: 1, to: date)! {
                // Task starts after today, therefore we're not interested.
                return false
            }
            
            let componentsOfTask = Calendar.current.dateComponents([.day, .month, .year], from: task.startDate)
            if componentsOfDate == componentsOfTask {
                // If the task starts today, then it is okay.
                return true
            }
            
            var weekdayOfDate = (Calendar.current.dateComponents([.weekday], from: date).weekday! + 6) % 7
            if weekdayOfDate == 0 { weekdayOfDate = 7 }
            let weekday = DayOfWeek(rawValue: weekdayOfDate)!
            if task.repeatDays.contains(weekday) {
                // The task repeats today, so it's okay.
                return true
            }
            
            // The task doesn't repeat today, don't use it.
            return false
        }
    }
    private var stopwatchDataToday: [StopwatchData] {
        let componentsOfDate = Calendar.current.dateComponents([.day, .month, .year], from: date)
        return stopwatchData.filter { data in
            let componentsOfStopwatch = Calendar.current.dateComponents(
                [.day, .month, .year],
                from: data.completionDate
            )
            return componentsOfDate == componentsOfStopwatch
        }
    }

    var body: some View {
        let tasksOfToday = tasksToday
        let stopwatchOfToday = stopwatchDataToday
        let tasksDoneToday = tasksOfToday.filter { task in
            stopwatchOfToday.contains { $0.taskId == task.id }
        }
        NavigationLink(destination: TaskDetailPage(date: date)) {
            VStack {
                // show date
                Text("\(Calendar.current.dateComponents([.day], from: date).day!)")
                    .font(.system(size: 15))
                    .font(.headline)
                    .padding(4)
                    .background(
                        Calendar.current.isDate(date, inSameDayAs: Date.now) ? .accentColor.opacity(0.2) : Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .frame(maxWidth: .infinity)
                
                if !tasksOfToday.isEmpty {
                    TaskView(
                        text: "\(tasksDoneToday.count)/\(tasksOfToday.count)",
                        complete: tasksDoneToday.count == tasksOfToday.count
                    )
                }
                
                Spacer() // same height of dayView
            }
            .frame(height: 80) // fixed height
            .padding(4)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TaskView: View {
    var text: String
    var complete: Bool

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(3)
            .frame(maxWidth: .infinity)
            .background(complete ? Color.green.opacity(0.2) : Color.accentColor.opacity(0.2))
            .cornerRadius(5)
    }
}

// Extension and additional struct implementations (ListView, DayView, etc.) go here.

// MARK: - Date Formatter Extension

/// Extension to provide a custom date formatter for the month and year.// Extension to provide a custom date formatter for the month and year.
extension DateFormatter {
    static let monthAndYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}

// MARK: - Preview Provider

#Preview{
    CalendarView()
}
