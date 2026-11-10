import SwiftUI
import AppKit

// MARK: - NotchScratchpadView (Mode Clicked / 152pt)

public struct NotchScratchpadView: View {
    @ObservedObject private var manager = ScratchpadManager.shared
    @ObservedObject private var store = NotchSettingsStore.shared
    
    @State private var newReminderText: String = ""
    @State private var isNoteCopied: Bool = false
    
    public init() {}
    
    public var body: some View {
        let currentW = CGFloat(store.preferences.clickedWidth)
        let currentH = CGFloat(store.preferences.clickedHeight)
        let availableW = max(360.0, currentW - 53)
        let leftWidth = max(230.0, availableW * 0.54)
        let rightWidth = max(190.0, availableW - leftWidth)
        let dividerHeight = max(70.0, currentH - 32)
        
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                // SISI KIRI: Instant Scratchpad & Apple Notes
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Image(systemName: "note.text")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.cyan)
                        Text("NOTES & SCRATCHPAD")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .foregroundColor(.white.opacity(0.85))
                        
                        Spacer()
                        
                        // Action: Open Notes.app
                        Button {
                            manager.openAppleNotes()
                        } label: {
                            HStack(spacing: 3) {
                                Text("Notes")
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.white.opacity(0.60))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .help("Open Apple Notes")
                        
                        // Action: Export Note
                        if !manager.note.isEmpty {
                            Button {
                                manager.exportToAppleNotes()
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export")
                                }
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.cyan.opacity(0.12))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .help("Save to Apple Notes")
                        }
                    }
                    
                    // Scratchpad Input Box
                    ZStack(alignment: .topLeading) {
                        if manager.note.isEmpty {
                            Text("Type quick thoughts, code, or draft thoughts here...")
                                .font(.system(size: 9.5))
                                .foregroundColor(.white.opacity(0.25))
                                .padding(.top, 6)
                                .padding(.leading, 6)
                        }
                        
                        TextEditor(text: $manager.note)
                            .font(.system(size: 9.5, weight: .regular))
                            .foregroundColor(.white)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .padding(4)
                    }
                    .background(Color.white.opacity(0.035))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(width: leftWidth)
                
                // DIVIDER TENGAH
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 1, height: dividerHeight)
                
                // SISI KANAN: Apple Reminders & Daily Tasks
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Image(systemName: "checklist")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.cyan)
                        Text(manager.hasRemindersAccess ? "APPLE REMINDERS" : "QUICK TASKS")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .foregroundColor(.white.opacity(0.85))
                        
                        Spacer()
                        
                        Button {
                            manager.openRemindersApp()
                        } label: {
                            HStack(spacing: 3) {
                                Text("Reminders")
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.white.opacity(0.60))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .help("Open Apple Reminders")
                    }
                    
                    // Quick Add Task Row
                    HStack(spacing: 6) {
                        TextField("New reminder...", text: $newReminderText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 9.5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .onSubmit {
                                submitReminder()
                            }
                        
                        Button {
                            submitReminder()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 20, height: 20)
                                .background(Color.cyan)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(newReminderText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    // Tasks List
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 4) {
                            if manager.hasRemindersAccess {
                                if manager.appleReminders.isEmpty {
                                    Text("No pending Apple Reminders")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.35))
                                        .padding(.top, 12)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    ForEach(manager.appleReminders) { rem in
                                        HStack(spacing: 6) {
                                            Button {
                                                manager.toggleReminder(id: rem.id)
                                            } label: {
                                                Image(systemName: rem.isCompleted ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(rem.isCompleted ? .cyan : .white.opacity(0.40))
                                            }
                                            .buttonStyle(.plain)
                                            
                                            Text(rem.title)
                                                .font(.system(size: 9.5, weight: .medium))
                                                .foregroundColor(rem.isCompleted ? .white.opacity(0.35) : .white.opacity(0.90))
                                                .strikethrough(rem.isCompleted, color: .white.opacity(0.35))
                                                .lineLimit(1)
                                            
                                            Spacer()
                                            
                                            Button {
                                                manager.deleteReminder(id: rem.id)
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 7.5))
                                                    .foregroundColor(.white.opacity(0.25))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3.5)
                                        .background(Color.white.opacity(0.025))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                }
                            } else {
                                // Fallback Local Tasks
                                ForEach(manager.localTodos) { todo in
                                    HStack(spacing: 6) {
                                        Button {
                                            manager.toggleReminder(id: todo.id.uuidString)
                                        } label: {
                                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 11))
                                                .foregroundColor(todo.isCompleted ? .cyan : .white.opacity(0.40))
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Text(todo.text)
                                            .font(.system(size: 9.5, weight: .medium))
                                            .foregroundColor(todo.isCompleted ? .white.opacity(0.35) : .white.opacity(0.90))
                                            .strikethrough(todo.isCompleted, color: .white.opacity(0.35))
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        Button {
                                            manager.deleteReminder(id: todo.id.uuidString)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 7.5))
                                                .foregroundColor(.white.opacity(0.25))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3.5)
                                    .background(Color.white.opacity(0.025))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                    }
                }
                .frame(width: rightWidth)
            }
            
            // Toast feedback
            if let toast = manager.toastMessage {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 7.5, weight: .bold))
                    Text(toast)
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.cyan.opacity(0.12))
                .clipShape(Capsule())
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }
    
    private func submitReminder() {
        let trimmed = newReminderText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        manager.addReminder(title: trimmed)
        newReminderText = ""
    }
}

// MARK: - Compact Hover Scratchpad View (Mode Hover 56pt)

public struct NotchCompactScratchpadView: View {
    @ObservedObject private var manager = ScratchpadManager.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            // Sisi Kiri: Scratchpad Peek
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 28, height: 28)
                    Image(systemName: "note.text")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.cyan)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Notes & Scratchpad")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(manager.note.isEmpty ? "Tap notch to write note..." : manager.note.components(separatedBy: "\n").first ?? "")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.50))
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 16)
            
            // Sisi Kanan: Apple Reminders Next Task
            HStack(spacing: 8) {
                if let nextReminder = manager.appleReminders.first(where: { !$0.isCompleted }) {
                    Button {
                        manager.toggleReminder(id: nextReminder.id)
                    } label: {
                        Image(systemName: "circle")
                            .font(.system(size: 11))
                            .foregroundColor(.cyan)
                    }
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next Reminder")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.cyan)
                        Text(nextReminder.title)
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                } else if let nextLocal = manager.localTodos.first(where: { !$0.isCompleted }) {
                    Button {
                        manager.toggleReminder(id: nextLocal.id.uuidString)
                    } label: {
                        Image(systemName: "circle")
                            .font(.system(size: 11))
                            .foregroundColor(.cyan)
                    }
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pending Task")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.cyan)
                        Text(nextLocal.text)
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    Text("All Tasks Completed")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.70))
                }
                
                Spacer(minLength: 0)
            }
            .frame(width: 190)
        }
        .padding(.horizontal, 10)
    }
}
