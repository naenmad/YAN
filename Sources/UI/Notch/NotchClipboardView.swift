import SwiftUI
import AppKit

public struct NotchClipboardView: View {
    @ObservedObject private var clipboard = ClipboardManager.shared
    @State private var selectedTab: Int = 0 // 0: History, 1: Pinned
    @State private var copiedId: UUID? = nil
    
    // Quick Add Snippet State
    @State private var isAddingSnippet: Bool = false
    @State private var newSnippetTitle: String = ""
    @State private var newSnippetContent: String = ""
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 8) {
            // Header: Minimal Tab Switcher + Action Button
            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedTab = 0
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 8))
                            Text("History (\(clipboard.history.count))")
                                .font(.system(size: 8.5, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(selectedTab == 0 ? Color.white.opacity(0.18) : Color.clear)
                        .foregroundColor(selectedTab == 0 ? .white : .white.opacity(0.45))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedTab = 1
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 8))
                            Text("Pinned (\(clipboard.pinnedSnippets.count))")
                                .font(.system(size: 8.5, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(selectedTab == 1 ? Color.cyan.opacity(0.25) : Color.clear)
                        .foregroundColor(selectedTab == 1 ? .cyan : .white.opacity(0.45))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(2)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
                
                Spacer()
                
                if selectedTab == 0 {
                    if !clipboard.history.isEmpty {
                        Button {
                            clipboard.clearHistory()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.45))
                                .frame(width: 20, height: 20)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help("Clear History")
                    }
                } else {
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            isAddingSnippet.toggle()
                        }
                    } label: {
                        Image(systemName: isAddingSnippet ? "xmark" : "plus")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.cyan)
                            .frame(width: 20, height: 20)
                            .background(Color.cyan.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(isAddingSnippet ? "Cancel" : "Add Pinned Snippet")
                }
            }
            
            // Content
            if selectedTab == 0 {
                historyList
            } else {
                pinnedList
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
    
    // MARK: - History List View
    
    private var historyList: some View {
        Group {
            if clipboard.history.isEmpty {
                VStack(spacing: 4) {
                    Spacer()
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.25))
                    Text("Clipboard is empty")
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.40))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 5) {
                        ForEach(clipboard.history) { item in
                            ClipboardRow(
                                item: item,
                                isCopied: copiedId == item.id,
                                onCopy: {
                                    clipboard.copy(content: item.content)
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
                                        copiedId = item.id
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        if copiedId == item.id { copiedId = nil }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, 1)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Pinned Snippets View
    
    private var pinnedList: some View {
        VStack(spacing: 6) {
            if isAddingSnippet {
                HStack(spacing: 6) {
                    TextField("Title (e.g. My IBAN)", text: $newSnippetTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 9.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    TextField("Content...", text: $newSnippetContent)
                        .textFieldStyle(.plain)
                        .font(.system(size: 9.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    Button("Save") {
                        clipboard.addSnippet(title: newSnippetTitle, content: newSnippetContent)
                        newSnippetTitle = ""
                        newSnippetContent = ""
                        isAddingSnippet = false
                    }
                    .font(.system(size: 9, weight: .bold))
                    .buttonStyle(.plain)
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyan)
                    .clipShape(Capsule())
                }
                .padding(.bottom, 2)
            }
            
            if clipboard.pinnedSnippets.isEmpty {
                VStack(spacing: 4) {
                    Spacer()
                    Image(systemName: "pin")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.25))
                    Text("No pinned snippets yet")
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.40))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 5) {
                        ForEach(clipboard.pinnedSnippets) { snippet in
                            PinnedRow(
                                snippet: snippet,
                                isCopied: copiedId == snippet.id,
                                onCopy: {
                                    clipboard.copy(content: snippet.content)
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
                                        copiedId = snippet.id
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        if copiedId == snippet.id { copiedId = nil }
                                    }
                                },
                                onDelete: {
                                    clipboard.removeSnippet(id: snippet.id)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 1)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Clipboard Item Row

private struct ClipboardRow: View {
    let item: ClipboardItem
    let isCopied: Bool
    let onCopy: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: onCopy) {
            HStack(spacing: 8) {
                // Leading Type Icon or Color Swatch
                if item.type == .color, let col = item.color {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(col)
                        .frame(width: 18, height: 18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                        )
                } else if item.type == .link {
                    Image(systemName: "link")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.cyan)
                        .frame(width: 18, height: 18)
                } else {
                    Image(systemName: "doc.text")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.50))
                        .frame(width: 18, height: 18)
                }
                
                // Text Preview
                Text(item.content.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.system(size: 9.5, weight: .medium, design: item.type == .color ? .monospaced : .default))
                    .foregroundColor(isCopied ? .cyan : .white.opacity(0.90))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer(minLength: 0)
                
                // Feedback icon
                if isCopied {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                        Text("Copied")
                            .font(.system(size: 7.5, weight: .bold))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.cyan.opacity(0.15))
                    .clipShape(Capsule())
                } else {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(isHovered ? 0.80 : 0.25))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4.5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.10) : Color.white.opacity(0.04))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .help("Click to copy to clipboard")
    }
}

// MARK: - Pinned Snippet Row

private struct PinnedRow: View {
    let snippet: PinnedSnippet
    let isCopied: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: onCopy) {
                HStack(spacing: 8) {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 8.5))
                        .foregroundColor(.cyan)
                        .frame(width: 16, height: 16)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(snippet.title)
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(snippet.content)
                            .font(.system(size: 8, weight: .regular))
                            .foregroundColor(.white.opacity(0.50))
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 0)
                    
                    if isCopied {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark")
                            Text("Copied")
                        }
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 9.5))
                    .foregroundColor(.white.opacity(isHovered ? 0.70 : 0.20))
            }
            .buttonStyle(.plain)
            .help("Delete snippet")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4.5)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isHovered ? Color.white.opacity(0.10) : Color.white.opacity(0.04))
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Compact Hover Clipboard View (Mode Hover 56pt)

public struct NotchCompactClipboardView: View {
    @ObservedObject private var clipboard = ClipboardManager.shared
    @State private var isCopied: Bool = false
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.cyan)
            }
            
            if let latest = clipboard.history.first {
                Button {
                    clipboard.copy(content: latest.content)
                    withAnimation { isCopied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { isCopied = false }
                } label: {
                    HStack(spacing: 6) {
                        VStack(alignment: .leading, spacing: 1.5) {
                            Text(isCopied ? "Copied to Clipboard!" : "Latest Copied")
                                .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                                .foregroundColor(isCopied ? .cyan : .white.opacity(0.50))
                            
                            Text(latest.content.trimmingCharacters(in: .whitespacesAndNewlines))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.system(size: 10.5))
                            .foregroundColor(isCopied ? .cyan : .white.opacity(0.70))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
            } else {
                Text("Clipboard is empty")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.40))
                Spacer()
            }
        }
        .padding(.horizontal, 10)
    }
}
