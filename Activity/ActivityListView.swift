//
//  ActivityListView.swift
//  Activity
//
//  Created by TimurSmoev on 12/24/23.
//  Refactored and commented on by Yu-Ting on 27.01.24.
//

import SwiftUI
import SwiftData
import Charts

/// Enum representing different timeframes for filtering
enum Timeframe {
    case daily, weekly, monthly, allTime
}

/// View for displaying activity list
struct ActivityListView: View {
    @Query var tasks: [Task]
    @Query var stopwatchData: [StopwatchData]
    @State private var selectedTimeframe: Timeframe = .allTime
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            VStack {
                ActivityChart(tasks: tasks, data: calculateStopwatchData())
                TimeframeSelectionView(selectedTimeframe: $selectedTimeframe, selectedDate: $selectedDate, stopwatchData: stopwatchData)
            }
            .navigationTitle("Training Summary 🏋️".localized)
        }
    }
    
    /// Calculate stopwatch data based on the selected timeframe
    private func calculateStopwatchData() -> [(UUID, TimeInterval)] {
        let filteredData = filterStopwatchData()
        return aggregateStopwatchData(filteredData)
    }
    
    /// Filter stopwatch data based on the selected timeframe
    private func filterStopwatchData() -> [StopwatchData] {
        let calendar = Calendar.current
        return stopwatchData.filter { data in
            switch selectedTimeframe {
            case .daily:
                return calendar.isDate(data.completionDate, equalTo: selectedDate, toGranularity: .day)
            case .weekly:
                return calendar.isDate(data.completionDate, equalTo: selectedDate, toGranularity: .weekOfMonth)
                
            case .monthly:
                return calendar.isDate(data.completionDate, equalTo: selectedDate, toGranularity: .month)
            case .allTime:
                return true
            }
        }
    }
    
    /// Aggregate stopwatch data by task
    private func aggregateStopwatchData(_ data: [StopwatchData]) -> [(UUID, TimeInterval)] {
        data.reduce(into: [:]) { result, datum in
            result[datum.taskId, default: 0] += datum.totalInterval
        }
        .filter { $1 > 0 }
        .map { ($0.key, $0.value) }
    }
}

/// Subview for displaying the activity chart
struct ActivityChart: View {
    var tasks: [Task]
    var data: [(UUID, TimeInterval)]
    
    var body: some View {
        Chart {
            ForEach(data, id: \.0) { (taskId, interval) in
                let taskName = tasks.first { $0.id == taskId }?.name ?? "Unknown".localized
                SectorMark(angle: .value("Stream", interval), angularInset: 3)
                    .foregroundStyle(by: .value("name", taskName))
                    .cornerRadius(7)
                    .annotation(position: .overlay) {
                        Text(interval.formattedTime())
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
            }
        }
    }
}

/// Extension for formatting TimeInterval
extension TimeInterval {
    func formattedTime() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        return "\(hours > 0 ? "\(hours)h " : "")\(minutes > 0 ? "\(minutes)m " : "")\(seconds > 0 ? "\(seconds)s" : "")".trimmingCharacters(in: .whitespaces)
    }
}

/// Subview for timeframe selection
struct TimeframeSelectionView: View {
    @Binding var selectedTimeframe: Timeframe
    @Binding var selectedDate: Date
    var stopwatchData: [StopwatchData]
    
    var body: some View {
        Group {
            timeframeSpecificPicker()
            generalTimeframePicker()
        }
    }
    
    /// Picker specific to the timeframe (daily, weekly or monthly)
    private func timeframeSpecificPicker() -> some View {
        switch selectedTimeframe {
        case .daily:
            return DatePicker("Day to view".localized, selection: $selectedDate, displayedComponents: .date).eraseToAnyView()
        case .weekly:
            return WeekPickerView(selectedDate: $selectedDate, stopwatchData: stopwatchData).eraseToAnyView()
            
        case .monthly:
            return MonthPickerView(selectedDate: $selectedDate, stopwatchData: stopwatchData).eraseToAnyView()
        default:
            return EmptyView().eraseToAnyView()
        }
    }
    
    /// General picker for selecting timeframe
    private func generalTimeframePicker() -> some View {
        Picker("Select Timeframe".localized, selection: $selectedTimeframe) {
            Text("Daily".localized).tag(Timeframe.daily)
            Text("Weekly".localized).tag(Timeframe.weekly)
            Text("Monthly".localized).tag(Timeframe.monthly)
            Text("All Time".localized).tag(Timeframe.allTime)
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

/// Extension for converting View to AnyView
extension View {
    func eraseToAnyView() -> AnyView { AnyView(self) }
}

/// Subview for selecting week
struct WeekPickerView: View {
    @Binding var selectedDate: Date
    var stopwatchData: [StopwatchData]
    
    var body: some View {
        Picker("Week to view".localized, selection: $selectedDate) {
            ForEach(uniqueYearAndWeeks(), id: \.self) { yearAndWeek in
                Text(yearAndWeek.longString).tag(yearAndWeek.startDate)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
    
    /// Calculate unique year and week combinations
    private func uniqueYearAndWeeks() -> [YearAndWeek] {
        let calendar = Calendar.current
        let yearAndWeeks = stopwatchData.compactMap { stopwatchData -> YearAndWeek? in
            let components = calendar.dateComponents([.weekOfYear, .month, .yearForWeekOfYear], from: stopwatchData.completionDate)
            guard let weekOfYear = components.weekOfYear, let month = components.month, let year = components.yearForWeekOfYear else { return nil }
            return YearAndWeek(weekOfYear: weekOfYear, month: month, year: year)
        }
        return Set(yearAndWeeks).sorted()
    }
}

struct YearAndWeek: Hashable, Comparable {
    let weekOfYear: Int
    let month: Int
    let year: Int
    
    /// Calculate the start date of the week
    var startDate: Date {
        var components = DateComponents()
        components.weekOfYear = weekOfYear
        components.month = month
        components.yearForWeekOfYear = year
        return Calendar.current.date(from: components) ?? Date()
    }
    
    var longString: String {
        "\(monthName(from: month)) - Week \(weekOfYear), \(year)"
    }
    
    static func < (lhs: YearAndWeek, rhs: YearAndWeek) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        } else if lhs.month != rhs.month {
            return lhs.month < rhs.month
        }
        return lhs.weekOfYear < rhs.weekOfYear
    }
}

func monthName(from month: Int) -> String {
    let dateFormatter = DateFormatter()
    let months = dateFormatter.monthSymbols
    guard month >= 1, month <= 12, let months = months else {
        return "Invalid month"
    }
    return months[month - 1] /// Array is zero-indexed, months are 1-indexed
}

/// Subview for selecting month
struct MonthPickerView: View {
    @Binding var selectedDate: Date
    var stopwatchData: [StopwatchData]
    
    var body: some View {
        Picker("Month to view".localized, selection: $selectedDate) {
            ForEach(uniqueMonthAndYears(), id: \.self) { monthAndYear in
                Text(monthAndYear.longString).tag(monthAndYear.date)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
    
    /// Calculate unique month and year combinations
    private func uniqueMonthAndYears() -> [MonthAndYear] {
        Set(stopwatchData.map { MonthAndYear(from: $0.completionDate) })
            .sorted()
    }
}

struct MonthAndYear: Codable, Identifiable, Comparable, Hashable {
    static func < (lhs: MonthAndYear, rhs: MonthAndYear) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        return lhs.month < rhs.month
    }
    
    var month: Int
    var year: Int
    
    var id: Int64 { Int64(month) + Int64(year) * 12 }
    
    var date: Date {
        Calendar.current.date(from: DateComponents(
            year: year,
            month: month
        ))!
    }
    
    init(from date: Date) {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        self.year = components.year ?? 0
        self.month = components.month ?? 0
    }
    
    var longString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return dateFormatter.string(from: self.date)
    }
}

extension Date {
    static func from(year: Int, month: Int, day: Int) -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        return Calendar.current.date(from: components)!
    }
}

#Preview {
    ActivityListView()
}
