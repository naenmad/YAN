import SwiftUI
import AppKit

public struct NotchScratchpadView: View {
    @ObservedObject private var manager = ScratchpadManager.shared
    @State private var newTodoText: String = ""
    @State private var isNoteCopied: Bool = false
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            // SISI KIRI: Instant Scratchpad
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "note.text")
                            .font(.system(size: 9))
                            .foregroundColor(.cyan)
                        Text("Scratchpad")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    if !manager.note.isEmpty {
                        Button {
                            manager.copyNote()
                            withAnimation { isNoteCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { isNoteCopied = false }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: isNoteCopied ? "checkmark" : "doc.on.doc")
                                Text(isNoteCopied ? "Copied" : "Copy")
                            }
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(isNoteCopied ? .cyan : .white.opacity(0.60))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                ZStack(alignment: .topLeading) {
                    if manager.note.isEmpty {
                        Text("Type quick thoughts, code snippets, or draft notes here...")
                            .font(.system(size: 9.5))
                            .foregroundColor(.white.opacity(0.25))
                            .padding(.top, 4)
                            .padding(.leading, 4)
                    }
                    
                    TextEditor(text: $manager.note)
                        .font(.system(size: 9.5, weight: .regular))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                }
                .padding(6)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .frame(maxWidth: .infinity)
            
            // DIVIDER TENGAH
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1)
                .padding(.vertical, 4)
            
            // SISI KANAN: Mini To-Do Checklist
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "checklist")
                            .font(.system(size: 9))
                            .foregroundColor(.cyan)
                        Text("To-Do")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    if manager.todos.contains(where: { $0.isCompleted }) {
                        Button("Clear Done") {
                            manager.clearCompleted()
                        }
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.white.opacity(0.40))
                        .buttonStyle(.plain)
                    }
                }
                
                // Add Todo Row
                HStack(spacing: 6) {
                    TextField("Add task...", text: $newTodoText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 9.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .onSubmit {
                            submitTodo()
                        }
                    
                    Button(action: submitTodo) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 18, height: 18)
                            .background(Color.cyan)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Todos List
                if manager.todos.isEmpty {
                    VStack {
                        Spacer()
                        Text("No pending tasks")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(.white.opacity(0.30))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 4) {
                            ForEach(manager.todos) { item in
                                TodoRow(
                                    item: item,
                                    onToggle: {
                                        manager.toggleTodo(id: item.id)
                                    },
                                    onDelete: {
                                        manager.removeTodo(id: item.id)
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 1)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
    
    private func submitTodo() {
        manager.addTodo(text: newTodoText)
        newTodoText = ""
    }
}

// MARK: - Todo Row Component

private struct TodoRow: View {
    let item: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 10))
                    .foregroundColor(item.isCompleted ? .cyan : .white.opacity(0.35))
            }
            .buttonStyle(.plain)
            
            Text(item.text)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundColor(item.isCompleted ? .white.opacity(0.35) : .white)
                .strikethrough(item.isCompleted, color: .white.opacity(0.35))
                .lineLimit(1)
            
            Spacer(minLength: 0)
            
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundColor(.white.opacity(isHovered ? 0.60 : 0.0))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(isHovered ? Color.white.opacity(0.04) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Compact Hover Scratchpad View (Mode Hover 56pt)

public struct NotchCompactScratchpadView: View {
    @ObservedObject private var manager = ScratchpadManager.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            // Task count chip
            let uncompleted = manager.todos.filter { !$0.isCompleted }
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.18))
                        .frame(width: 24, height: 24)
                    Image(systemName: "checklist")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.cyan)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(uncompleted.count) Tasks Pending")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    if let first = uncompleted.first {
                        Text(first.text)
                            .font(.system(size: 8, weight: .regular))
                            .foregroundColor(.white.opacity(0.50))
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1, height: 24)
            
            // Scratch note snippet
            HStack(spacing: 6) {
                Image(systemName: "note.text")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.50))
                
                Text(manager.note.isEmpty ? "Scratchpad is empty" : manager.note.replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundColor(manager.note.isEmpty ? .white.opacity(0.30) : .white.opacity(0.70))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
    }
}
