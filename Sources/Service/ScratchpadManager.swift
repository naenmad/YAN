import Foundation
import AppKit
import SwiftUI

public struct TodoItem: Identifiable, Codable, Equatable {
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
    
    @Published public var note: String = "" {
        didSet {
            saveNote()
        }
    }
    
    @Published public var todos: [TodoItem] = [] {
        didSet {
            saveTodos()
        }
    }
    
    private let noteStorageKey = "com.yan.notchanothernotch.scratchpadNote"
    private let todosStorageKey = "com.yan.notchanothernotch.todos"
    
    private init() {
        loadData()
    }
    
    public func addTodo(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            todos.append(TodoItem(text: trimmed))
        }
    }
    
    public func toggleTodo(id: UUID) {
        guard let idx = todos.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            todos[idx].isCompleted.toggle()
        }
    }
    
    public func removeTodo(id: UUID) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            todos.removeAll(where: { $0.id == id })
        }
    }
    
    public func clearCompleted() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            todos.removeAll(where: { $0.isCompleted })
        }
    }
    
    public func copyNote() {
        guard !note.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(note, forType: .string)
    }
    
    private func loadData() {
        self.note = UserDefaults.standard.string(forKey: noteStorageKey) ?? ""
        if let data = UserDefaults.standard.data(forKey: todosStorageKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            self.todos = decoded
        } else {
            self.todos = [
                TodoItem(text: "Review pull request"),
                TodoItem(text: "Drink water")
            ]
        }
    }
    
    private func saveNote() {
        UserDefaults.standard.set(note, forKey: noteStorageKey)
    }
    
    private func saveTodos() {
        if let data = try? JSONEncoder().encode(todos) {
            UserDefaults.standard.set(data, forKey: todosStorageKey)
        }
    }
}
