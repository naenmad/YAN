import SwiftUI
import AppKit

public enum CalendarDisplayMode: String {
    case week = "Week"
    case month = "Month"
}

public struct NotchCalendarView: View {
    public var isLarge: Bool = false
    
    @ObservedObject private var calendarManager = CalendarManager.shared
    @State private var mode: CalendarDisplayMode = .week
    @State private var currentDate = Date()
    @State private var displayedMonth = Date()
    private let calendar = Calendar.current
    
    public init(isLarge: Bool = false) {
        self.isLarge = isLarge
    }
    
    private var weekDays: [Date] {
        let today = calendar.startOfDay(for: currentDate)
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return [today]
        }
        var days: [Date] = []
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: weekInterval.start) {
                days.append(day)
            }
        }
        return days
    }
    
    private var monthGridDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let firstDay = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDay) // 1 = Sun, 2 = Mon ...
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        
        var days: [Date?] = []
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        for offset in 0..<range.count {
            if let d = calendar.date(byAdding: .day, value: offset, to: firstDay) {
                days.append(d)
            }
        }
        return days
    }
    
    public var body: some View {
        if isLarge {
            largeCalendarSection
        } else {
            compactWeekView
        }
    }
    
    // MARK: - Compact Week View (Saat Hover Ringkas 500x56)
    
    private var compactWeekView: some View {
        Button {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.red)
                    
                    Text(currentDate, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer(minLength: 0)
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                }
                
                HStack(spacing: 3) {
                    ForEach(weekDays, id: \.self) { day in
                        let isToday = calendar.isDateInToday(day)
                        VStack(spacing: 2) {
                            Text(dayLetter(for: day))
                                .font(.system(size: 7.5, weight: .medium))
                                .foregroundColor(isToday ? .white : .white.opacity(0.40))
                            
                            ZStack {
                                if isToday {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 16, height: 16)
                                }
                                
                                Text("\(calendar.component(.day, from: day))")
                                    .font(.system(size: 9, weight: isToday ? .bold : .medium, design: .rounded))
                                    .foregroundColor(isToday ? .white : .white.opacity(0.85))
                            }
                            .frame(width: 16, height: 16)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Click to open macOS Calendar")
    }
    
    // MARK: - Large Calendar Section (Default: 1-Row Week + Schedule, Toggleable to Month)
    
    private var largeCalendarSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: "Nov '26" + [Week | Month] Picker + Open Calendar
            HStack(spacing: 6) {
                Text(monthYearHeader(for: displayedMonth))
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer(minLength: 0)
                
                // Toggle Button Antara 1-Baris Minggu (Week) dan Kalender Bulanan (Month)
                HStack(spacing: 1) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { mode = .week }
                    } label: {
                        Text("Week")
                            .font(.system(size: 8, weight: mode == .week ? .bold : .medium))
                            .foregroundColor(mode == .week ? .white : .white.opacity(0.45))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(mode == .week ? Color.white.opacity(0.18) : Color.clear)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { mode = .month }
                    } label: {
                        Text("Month")
                            .font(.system(size: 8, weight: mode == .month ? .bold : .medium))
                            .foregroundColor(mode == .month ? .white : .white.opacity(0.45))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(mode == .month ? Color.white.opacity(0.18) : Color.clear)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(1)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
                
                // Shortcut Apple Calendar
                Button {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
                } label: {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.red.opacity(0.95))
                        .frame(width: 16, height: 16)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Open Apple Calendar")
            }
            
            if mode == .week {
                // TAMPILAN 1 BARIS MINGGU INI (Permintaan User: 1 Baris Saja)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 3) {
                        ForEach(weekDays, id: \.self) { day in
                            let isToday = calendar.isDateInToday(day)
                            VStack(spacing: 2) {
                                Text(dayLetter(for: day))
                                    .font(.system(size: 7.5, weight: .bold))
                                    .foregroundColor(isToday ? .white : .white.opacity(0.35))
                                
                                ZStack {
                                    if isToday {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 16, height: 16)
                                    }
                                    
                                    Text("\(calendar.component(.day, from: day))")
                                        .font(.system(size: 8.5, weight: isToday ? .bold : .medium, design: .rounded))
                                        .foregroundColor(isToday ? .white : .white.opacity(0.85))
                                }
                                .frame(width: 16, height: 16)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 2)
                    
                    Divider()
                        .overlay(Color.white.opacity(0.08))
                    
                    // JADWAL MINGGU INI / HARI INI DI BAWAH 1 BARIS KALENDER
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("SCHEDULE")
                                .font(.system(size: 7.5, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.35))
                            
                            Spacer()
                            
                            Text("This Week")
                                .font(.system(size: 7.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.25))
                        }
                        
                        if calendarManager.events.isEmpty {
                            HStack(spacing: 5) {
                                Image(systemName: "calendar.badge.checkmark")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.35))
                                Text("No scheduled events this week")
                                    .font(.system(size: 8.5, weight: .regular))
                                    .foregroundColor(.white.opacity(0.40))
                                Spacer()
                            }
                            .padding(.vertical, 3)
                        } else {
                            ForEach(calendarManager.events.prefix(2)) { event in
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(event.color)
                                        .frame(width: 4.5, height: 4.5)
                                    
                                    Text(event.title)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.white.opacity(0.90))
                                        .lineLimit(1)
                                    
                                    Spacer(minLength: 0)
                                    
                                    Text(formatEventTime(start: event.startDate, isAllDay: event.isAllDay))
                                        .font(.system(size: 7.5, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.35))
                                }
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
                    }
                }
            } else {
                // TAMPILAN BULANAN PENUH (Jika User Memilih Tab "Month")
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 2) {
                        ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { symbol in
                            Text(symbol)
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.white.opacity(0.30))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                        ForEach(0..<monthGridDays.count, id: \.self) { index in
                            if let day = monthGridDays[index] {
                                let isToday = calendar.isDateInToday(day)
                                let dayNumber = calendar.component(.day, from: day)
                                
                                Button {
                                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
                                } label: {
                                    ZStack {
                                        if isToday {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 14, height: 14)
                                        }
                                        
                                        Text("\(dayNumber)")
                                            .font(.system(size: 8, weight: isToday ? .bold : .medium, design: .rounded))
                                            .foregroundColor(isToday ? .white : .white.opacity(0.85))
                                    }
                                    .frame(height: 14)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Color.clear.frame(height: 14)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
    
    private func monthYearHeader(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM ''yy" // e.g. "Nov '26"
        return formatter.string(from: date)
    }
    
    private func formatEventTime(start: Date, isAllDay: Bool) -> String {
        if isAllDay { return "All Day" }
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: start)
    }
    
    private func dayLetter(for date: Date) -> String {
        let weekday = calendar.component(.weekday, from: date)
        switch weekday {
        case 1: return "S"
        case 2: return "M"
        case 3: return "T"
        case 4: return "W"
        case 5: return "T"
        case 6: return "F"
        case 7: return "S"
        default: return ""
        }
    }
}
