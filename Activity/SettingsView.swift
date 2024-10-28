//
//  SettingsView.swift
//  Activity
//
//  Created by TimurSmoev on 12/24/23.
//  Refactored and commented on by Yu-Ting on 27.01.24.
//

import SwiftUI
import SwiftData

/// Constants for reuse and easy modification
let dailyNotificationId = "DAILY_NOTIFICATION"
let notificationTitle = "Let's Check What You've Got For Today!"
let notificationSubtitle = "Motivation is what gets you started. Habit is what keeps you going."
let defaultHour = 8
let defaultMinute = 0

struct SettingsView: View {
    @Environment(\.modelContext) var modelContext
    @Query var settingsList: [Settings]
    var settings: Settings? { settingsList.first }

    @State private var notificationPermission = UNAuthorizationStatus.notDetermined

    /// Function to update settings, creating new settings if none exist.
    private func updateSettings(_ updateBlock: (_ settings: Settings) -> Void) {
        let currentSettings = settings ?? createNewSettings()
        updateBlock(currentSettings)
    }

    private func createNewSettings() -> Settings {
        let newSettings = Settings()
        modelContext.insert(newSettings)
        return newSettings
    }

    /// Function to remove daily notifications, with an option to update the database.
    private func removeDailyNotification(updatingDatabase: Bool = true) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyNotificationId])
        if updatingDatabase {
            updateSettings { $0.notificationTime = nil }
        }
    }

    /// Function to schedule daily notifications.
    private func scheduleDailyNotification(for dateComponents: DateComponents) {
        removeDailyNotification(updatingDatabase: false)
        let content = createNotificationContent()
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: dailyNotificationId,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
        updateSettings { $0.notificationTime = HourAndMinute(hour: dateComponents.hour ?? defaultHour, minute: dateComponents.minute ?? defaultMinute) }
    }

    /// Creating notification content to reduce complexity in scheduleDailyNotification
    private func createNotificationContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = notificationTitle
        content.subtitle = notificationSubtitle
        content.sound = UNNotificationSound.default
        return content
    }

    var body: some View {
        NavigationStack {
            Form {
                personalInfoSection()
                visualSettingsSection()
                notificationSettingsSection()
            }
            .navigationTitle(Text("Settings"))
        }
    }

    /// Personal Information Section
    private func personalInfoSection() -> some View {
        Section(header: Text("Personal Information".localized)) {
            // Use the dynamic font size for TextFields and Labels
            TextField("First Name".localized, text: textFieldBinding(for: \.firstName))
            TextField("Last Name".localized, text: textFieldBinding(for: \.lastName))
            TextField("Email".localized, text: textFieldBinding(for: \.email))
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled(true)
            DatePicker("Birthday".localized, selection: datePickerBinding(for: \.birthday), displayedComponents: .date)
        }
        .font(.system(size: settings?.dynamicFontSize ?? 17))
    }

    /// Visual Settings Section
    private func visualSettingsSection() -> some View {
        Section(header: Text("Visual Settings".localized)) {
            Picker("Accent Color".localized, selection: pickerBinding(for: \.accentColor, defaultValue: AccentColor.yellow)) {
                Text("Yellow".localized).tag(AccentColor.yellow)
                Text("Blue".localized).tag(AccentColor.blue)
                Text("Purple".localized).tag(AccentColor.purple)
                Text("Green".localized).tag(AccentColor.green)
            }
            .font(.system(size: settings?.dynamicFontSize ?? 17))
        }
    }

    /// Notification Settings Section
    private func notificationSettingsSection() -> some View {
        Section(header: Text("Notification Settings".localized)) {
            switch notificationPermission {
            case .authorized, .provisional, .ephemeral:
                dailyReminderToggle()
                notificationTimePicker()
            case .denied:
                notificationPermissionDeniedView()
            case .notDetermined:
                enableRemindersButton()
            @unknown default:
                Text("Notification Permission Unknown".localized)
            }
        }
        .font(.system(size: settings?.dynamicFontSize ?? 17))
    }

    private func fontSizeSection() -> some View {
        // Section for font size adjustment
        Section(header: Text("Font Size".localized)) {
            Slider(
                value: fontSizeBinding(for: \.dynamicFontSize),
                in: 12...24, // Range for font size
                step: 1
            )
            Text(String(format: "FontSizeFormat".localized, Int(settings?.dynamicFontSize ?? 17)))

        }
    }
    
    /// Extracting smaller view components
    private func dailyReminderToggle() -> some View {
        Toggle(isOn: toggleBinding(), label: { Text("Daily Reminder".localized)})
            .font(.system(size: settings?.dynamicFontSize ?? 17))
    }

    private func notificationTimePicker() -> some View {
        Group {  /// Using Group instead of AnyView for better performance and simplicity
            if let notificationTime = settings?.notificationTime {
                DatePicker(
                    selection: datePickerBinding(forNotificationTime: notificationTime),
                    displayedComponents: .hourAndMinute
                ) {
                    Text("Notification Time".localized)
                }
            } else {
                EmptyView()
            }
        }
    }

    private func notificationPermissionDeniedView() -> some View {
        Group {
            Text("Notification Permission Denied".localized)
            Button("Enable in Settings".localized) {
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
    }

    private func enableRemindersButton() -> some View {
        Button("Enable Reminders".localized) {
            requestNotificationPermission()
        }
        .onAppear {
            checkAndHandleNotificationPermission()
        }
    }

    /// Binding helper functions
    private func textFieldBinding(for keyPath: WritableKeyPath<Settings, String?>) -> Binding<String> {
        Binding(
            get: { self.settings?[keyPath: keyPath] ?? "" },
            set: { newValue in
                self.updateSettings { settings in
                    var mutableSettings = settings
                    mutableSettings[keyPath: keyPath] = newValue
                }
            }
        )
    }

    private func datePickerBinding(for keyPath: WritableKeyPath<Settings, Date?>) -> Binding<Date> {
        Binding(
            get: { self.settings?[keyPath: keyPath] ?? Date() }, // Default to current date if nil
            set: { newValue in
                self.updateSettings { settings in
                    var mutableSettings = settings
                    mutableSettings[keyPath: keyPath] = newValue
                }
            }
        )
    }
    
    private func fontSizeBinding(for keyPath: WritableKeyPath<Settings, CGFloat?>) -> Binding<CGFloat> {
        Binding(
            get: { self.settings?[keyPath: keyPath] ?? 17 },
            set: { newValue in
                self.updateSettings { settings in
                    var mutableSettings = settings
                    mutableSettings[keyPath: keyPath] = newValue
                }
            }
        )
    }
    
    private func pickerBinding<T>(for keyPath: WritableKeyPath<Settings, T>, defaultValue: T) -> Binding<T> {
        Binding(
            get: { self.settings?[keyPath: keyPath] ?? defaultValue },
            set: { newValue in
                self.updateSettings { settings in
                    var mutableSettings = settings
                    mutableSettings[keyPath: keyPath] = newValue
                }
            }
        )
    }

    private func toggleBinding() -> Binding<Bool> {
        Binding(
            get: { self.settings?.notificationTime != nil },
            set: { newValue in
                if newValue {
                    scheduleDailyNotification(for: DateComponents(calendar: Calendar.current, hour: defaultHour, minute: defaultMinute))
                } else {
                    removeDailyNotification()
                }
            }
        )
    }

    private func datePickerBinding(forNotificationTime notificationTime: HourAndMinute) -> Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: notificationTime.hour, minute: notificationTime.minute, second: 0, of: Date()) ?? Date()
            },
            set: { newValue in
                let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                scheduleDailyNotification(for: dateComponents)
            }
        )
    }

    /// Functions for notification permission handling
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, _ in
            if success {
                scheduleDailyNotification(for: DateComponents(calendar: Calendar.current, hour: defaultHour, minute: defaultMinute))
            }
            refreshNotificationPermissionStatus()
        }
    }

    private func checkAndHandleNotificationPermission() {
        refreshNotificationPermissionStatus()
        if notificationPermission == .notDetermined || notificationPermission == .denied {
            updateSettings { $0.notificationTime = nil }
        }
    }

    private func refreshNotificationPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            notificationPermission = settings.authorizationStatus
        }
    }
}

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
    
#Preview{
    SettingsView()
}
