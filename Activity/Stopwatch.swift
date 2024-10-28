//
//  Stopwatch.swift
//  Activity
//
//  Created by Sandro  on 15.01.24.
//

import SwiftUI
import SwiftData

struct Stopwatch: View {
    var date: Date
    var stopwatchDataToUpdate: StopwatchData?
    @State var taskId: UUID
    @State var modelInserted = false
    @StateObject private var viewModel = StopwatchViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    
    @State var manualStartDate: Date
    @State var manualEndDate: Date
    
    init(taskId: UUID, date: Date, updating stopwatchDataToUpdate: StopwatchData? = nil) {
        self._taskId = State(initialValue: taskId)
        self.date = date
        self._manualStartDate = State(wrappedValue: date)
        self._manualEndDate = State(wrappedValue: date)
        self.stopwatchDataToUpdate = stopwatchDataToUpdate
        if let stopwatchDataToUpdate = stopwatchDataToUpdate {
            self._viewModel = StateObject(wrappedValue: StopwatchViewModel(
                stopwatchData: stopwatchDataToUpdate.times.map { time in
                    (time.start, time.end)
                }
            ))
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.06).edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                
                ZStack {
                    Circle()
                        .trim(from: 0, to: 1)
                        .stroke(colorScheme == .light ? Color.black.opacity(0.09) : Color.white.opacity(0.09), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .frame(width: 280, height: 280)
                        .padding()
                    if (viewModel.elapsedPeriods < 1 || viewModel.totalElapsedTime.truncatingRemainder(dividingBy: 1) > 0.3) {
                        Circle()
                            .trim(from: 0, to: min(viewModel.elapsedPeriods, 1.0))
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .frame(width: 280, height: 280)
                            .rotationEffect(.degrees(-90))
                            .padding()
                    }
                    //                    ForEach(1..<Int(viewModel.elapsedPeriods + 1), id: \.self) { idx in
                    //                        Circle()
                    //                            .trim(from: 0, to: (viewModel.elapsedTime.truncatingRemainder(dividingBy: 60)) / 60.0)
                    //                            .stroke(Color.red, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    //                            .frame(width: 280, height: 280)
                    //                            .rotationEffect(.degrees(-90))
                    //                            .padding()
                    //                    }
                    Text(viewModel.timeElapsed)
                        .font(.largeTitle)
                        .padding()
                }
                
                HStack {
                    if viewModel.isRunning {
                        Button(action: viewModel.stop) {
                            Text("Pause".localized)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            viewModel.start()
                        }) {
                            Text("Start".localized)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    
                    if viewModel.hasStarted {
                        Button(action:{
                            viewModel.stop()
                            if let stopwatchData = stopwatchDataToUpdate {
                                stopwatchData.times = viewModel.stopwatchData.map { (start, end) in
                                    Time(start: start, end: end)
                                }
                            } else {
                                let stopwatchData = StopwatchData(
                                    completionDate: date,
                                    taskId: taskId,
                                    times: viewModel.stopwatchData.map { (start, end) in
                                        Time(start: start, end: end)
                                    }
                                )
                                context.insert(stopwatchData)
                            }
                            dismiss()
                        }) {
                            Text("Finish".localized)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                
                Spacer()
                
                if !viewModel.hasStarted && stopwatchDataToUpdate == nil {
                    VStack {
                        Spacer()
                        
                        Text("Did you complete the workout already?")
                        
                        Form {
                            DatePicker("Start Time", selection: $manualStartDate, displayedComponents: .hourAndMinute)
                            DatePicker("End Time", selection: $manualEndDate, displayedComponents: .hourAndMinute)
                        }
                        
                        Button("Add manually") {
                            let startDate = manualStartDate.withoutSeconds()
                            let endDate = manualEndDate.withoutSeconds()
                            
                            let stopwatchData = StopwatchData(
                                completionDate: date,
                                taskId: taskId,
                                times: [
                                    Time(
                                        start: startDate,
                                        end: endDate
                                    )
                                ]
                            )
                            context.insert(stopwatchData)
                            dismiss()
                        }
                        .disabled(manualStartDate.withoutSeconds() == manualEndDate.withoutSeconds())
                    }
                    .padding([.vertical])
                }
            }
        }
    }
}

extension Date {
    func withoutSeconds() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        components.second = 0
        let date = Calendar.current.date(from: components)!
        return date
    }
}

class StopwatchViewModel: ObservableObject {
    @Published var timeElapsed: String = "00:00:00"
    @Published var isRunning: Bool = false
    @Published var hasStarted: Bool = false
    @Published var previousElapsedTime: TimeInterval = 0
    @Published var currentElapsedTime: TimeInterval = 0
    @Published var period: TimeInterval = 60
    @Published var stopwatchData: [(Date, Date)]
    var elapsedPeriods: Double {totalElapsedTime / period}
    var totalElapsedTime: TimeInterval {previousElapsedTime + currentElapsedTime}
    private var timer: Timer?
    private var startTime: Date?

    init (stopwatchData: [(Date, Date)] = []){
        self.stopwatchData = stopwatchData
        self.previousElapsedTime = stopwatchData.reduce(0) { result, tuple in
            let (start, end) = tuple
            return result + start.distance(to: end)
        }
        self.updateTimeElapsed(previousElapsedTime)
    }
    
    func start() {
        isRunning = true
        hasStarted = true
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            let currentTime = Date()
            let sinceStart = currentTime.timeIntervalSince(startTime)
            currentElapsedTime = sinceStart
            self.updateTimeElapsed(previousElapsedTime + currentElapsedTime)
        }
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        let currentTime = Date()
        if let startTime = startTime {
            let sinceStart = currentTime.timeIntervalSince(startTime)
            currentElapsedTime = 0
            previousElapsedTime += sinceStart
            stopwatchData.append((startTime, currentTime))
            self.startTime = nil
        }
    }

    func reset() {
        stop()
        hasStarted = false
        currentElapsedTime = 0
        updateTimeElapsed(0)
    }

    private func updateTimeElapsed(_ elapsedTime: TimeInterval) {
        let seconds = Int(elapsedTime) % 60
        let minutes = Int(elapsedTime / 60) % 60
        let hours = Int(elapsedTime / 3600)
        timeElapsed = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}



#Preview {
    
    return Stopwatch(taskId: UUID(), date: Date())
    
}

