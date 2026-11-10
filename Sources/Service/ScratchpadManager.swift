import Foundation
import AppKit
import SwiftUI
import EventKit

public struct AppleReminderItem: Identifiable, Equatable {
    public let id: String
    public var title: String
    public var isCompleted: Bool
    public var dueDate: Date?
    public var listTitle: String
    
    public init(id: String, title: String, isCompleted: Bool = false, dueDate: Date? = nil, listTitle: String = "Reminders") {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.listTitle = listTitle
    }
}

public struct LocalTodoItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public var text: String
    public var isCompleted: Bool
    public let createdAt: Date
    
    public init(text: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.text = text
        self.isCompleted = isCompleted
        self.createdAt = Date()
    }
}

@MainActor
public final class ScratchpadManager: ObservableObject {
    public static let shared = ScratchpadManager()
    
    private let eventStore = EKEventStore()
    
    @Published public var note: String = "" {
        didSet {
            saveNote()
        }
    }
    
    // Apple Reminders Integration
    @Published public var appleReminders: [AppleReminderItem] = []
    @Published public var hasRemindersAccess: Bool = false
    
    // Local fallback tasks
    @Published public var localTodos: [LocalTodoItem] = [] {
        didSet {
            saveLocalTodos()
        }
    }
    
    @Published public var toastMessage: String? = nil
    
    private let noteStorageKey = "com.yan.notchanothernotch.scratchpadNote"
    private let todosStorageKey = "com.yan.notchanothernotch.todos"
    
    private init() {
        loadData()
        requestRemindersAccess()
    }
    
    // MARK: - Apple Reminders Integration (iCloud / Account Synced)
    
    public func requestRemindersAccess() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if status == .authorized {
            self.hasRemindersAccess = true
            fetchAppleReminders()
        } else if status == .notDetermined {
            if #available(macOS 14.0, *) {
                eventStore.requestFullAccessToReminders { [weak self] granted, _ in
                    Task { @MainActor [weak self] in
                        self?.hasRemindersAccess = granted
                        if granted {
                            self?.fetchAppleReminders()
                        }
                    }
                }
            } else {
                eventStore.requestAccess(to: .reminder) { [weak self] granted, _ in
                    Task { @MainActor [weak self] in
                        self?.hasRemindersAccess = granted
                        if granted {
                            self?.fetchAppleReminders()
                        }
                    }
                }
            }
        }
    }
    
    public func fetchAppleReminders() {
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        eventStore.fetchReminders(matching: predicate) { [weak self] ekReminders in
            guard let ekReminders = ekReminders else { return }
            Task { @MainActor [weak self] in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    self?.appleReminders = ekReminders.map { rem in
                        AppleReminderItem(
                            id: rem.calendarItemIdentifier,
                            title: rem.title ?? "Reminder",
                            isCompleted: rem.isCompleted,
                            dueDate: rem.dueDateComponents?.date,
                            listTitle: rem.calendar?.title ?? "Reminders"
                        )
                    }
                }
            }
        }
    }
    
    public func addReminder(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if hasRemindersAccess {
            let reminder = EKReminder(eventStore: eventStore)
            reminder.title = trimmed
            reminder.calendar = eventStore.defaultCalendarForNewReminders() ?? eventStore.calendars(for: .reminder).first
            
            do {
                try eventStore.save(reminder, commit: true)
                showToast("Added to Apple Reminders")
                fetchAppleReminders()
                return
            } catch {
                print("Error saving to Reminders: \(error)")
            }
        }
        
        // Fallback to local todo
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            localTodos.append(LocalTodoItem(text: trimmed))
        }
    }
    
    public func toggleReminder(id: String) {
        if hasRemindersAccess, let rem = eventStore.calendarItem(withIdentifier: id) as? EKReminder {
            rem.isCompleted = true
            rem.completionDate = Date()
            try? eventStore.save(rem, commit: true)
            showToast("Reminder Completed")
            fetchAppleReminders()
            return
        }
        
        // Fallback to local
        if let uuid = UUID(uuidString: id), let idx = localTodos.firstIndex(where: { $0.id == uuid }) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                localTodos[idx].isCompleted.toggle()
            }
        }
    }
    
    public func deleteReminder(id: String) {
        if hasRemindersAccess, let rem = eventStore.calendarItem(withIdentifier: id) as? EKReminder {
            try? eventStore.remove(rem, commit: true)
            fetchAppleReminders()
            return
        }
        
        // Fallback to local
        if let uuid = UUID(uuidString: id) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                localTodos.removeAll(where: { $0.id == uuid })
            }
        }
    }
    
    public func openRemindersApp() {
        if let url = URL(string: "x-apple-reminderkit://") {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Reminders.app"))
        }
    }
    
    // MARK: - Apple Notes Integration
    
    public func exportToAppleNotes() {
        guard !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let lines = self.note.components(separatedBy: "\n")
            let title = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "YAN Note"
            let bodyHTML = lines.joined(separator: "<br>")
            let escapedBody = bodyHTML.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            let escapedTitle = title.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            
            let script = """
            tell application "Notes"
                tell account 1
                    make new note at default folder with properties {name: "\(escapedTitle)", body: "<p>\(escapedBody)</p>"}
                end tell
            end tell
            """
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
            
            Task { @MainActor [weak self] in
                self?.showToast("Exported to Apple Notes")
            }
        }
    }
    
    public func openAppleNotes() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Notes.app"))
    }
    
    public func copyNote() {
        guard !note.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(note, forType: .string)
        showToast("Note Copied")
    }
    
    // MARK: - Local Persistence
    
    private func loadData() {
        self.note = UserDefaults.standard.string(forKey: noteStorageKey) ?? ""
        if let data = UserDefaults.standard.data(forKey: todosStorageKey),
           let decoded = try? JSONDecoder().decode([LocalTodoItem].self, from: data) {
            self.localTodos = decoded
        } else {
            self.localTodos = [
                LocalTodoItem(text: "Check upcoming reminders"),
                LocalTodoItem(text: "Review project milestones")
            ]
        }
    }
    
    private func saveNote() {
        UserDefaults.standard.set(note, forKey: noteStorageKey)
    }
    
    private func saveLocalTodos() {
        if let data = try? JSONEncoder().encode(localTodos) {
            UserDefaults.standard.set(data, forKey: todosStorageKey)
        }
    }
    
    private func showToast(_ msg: String) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            self.toastMessage = msg
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            if self.toastMessage == msg {
                withAnimation { self.toastMessage = nil }
            }
        }
    }
}
