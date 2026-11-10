import SwiftUI
import AppKit

public struct NotchCalendarView: View {
    public var isLarge: Bool = false
    
    @ObservedObject private var calendarManager = CalendarManager.shared
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
            largeMonthWithScheduleView
        } else {
            compactWeekView
        }
    }
    
    // MARK: - Compact Week View (Saat Hover di Notch)
    
    private var compactWeekView: some View {
        Button {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.red)
                    
                    Text(currentDate, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer(minLength: 0)
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                }
                
                HStack(spacing: 3) {
                    ForEach(weekDays, id: \.self) { day in
                        let isToday = calendar.isDateInToday(day)
                        VStack(spacing: 2) {
                            Text(dayLetter(for: day))
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(isToday ? .white : .white.opacity(0.40))
                            
                            ZStack {
                                if isToday {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 17, height: 17)
                                }
                                
                                Text("\(calendar.component(.day, from: day))")
                                    .font(.system(size: 9.5, weight: isToday ? .bold : .medium, design: .rounded))
                                    .foregroundColor(isToday ? .white : .white.opacity(0.85))
                            }
                            .frame(width: 18, height: 18)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Click to open macOS Calendar")
    }
    
    // MARK: - Large Full Month + Schedule View (Saat Diklik / Enlarged 640x200)
    
    private var largeMonthWithScheduleView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: "Nov 26" / "Nov 2026" + Arrow Navigation (Tanpa teks "T..." yang kepotong)
            HStack(spacing: 6) {
                Text(monthYearHeader(for: displayedMonth))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer(minLength: 0)
                
                HStack(spacing: 5) {
                    Button {
                        if let prev = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
                            displayedMonth = prev
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.70))
                            .frame(width: 18, height: 18)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        if let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
                            displayedMonth = next
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.70))
                            .frame(width: 18, height: 18)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
                    } label: {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.red.opacity(0.95))
                            .frame(width: 18, height: 18)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Open Apple Calendar")
                }
            }
            
            // Weekday Row: S M T W T F S
            HStack(spacing: 2) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 7-Column Days Grid
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
                                        .frame(width: 15, height: 15)
                                }
                                
                                Text("\(dayNumber)")
                                    .font(.system(size: 8, weight: isToday ? .bold : .medium, design: .rounded))
                                    .foregroundColor(isToday ? .white : .white.opacity(0.85))
                            }
                            .frame(height: 15)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(height: 15)
                    }
                }
            }
            
            Divider()
                .overlay(Color.white.opacity(0.08))
                .padding(.vertical, 1)
            
            // BAGIAN JADWAL (SCHEDULE) DI BAWAH KALENDER
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("TODAY'S SCHEDULE")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.35))
                    
                    Spacer()
                    
                    Text(currentDate, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.30))
                }
                
                if calendarManager.events.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 9.5))
                            .foregroundColor(.white.opacity(0.35))
                        Text("No scheduled events today")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(.white.opacity(0.40))
                        Spacer()
                    }
                    .padding(.vertical, 2)
                } else {
                    ForEach(calendarManager.events.prefix(2)) { event in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(event.color)
                                .frame(width: 5, height: 5)
                            
                            Text(event.title)
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.90))
                                .lineLimit(1)
                            
                            Spacer(minLength: 0)
                            
                            Text(formatTimeRange(start: event.startDate, end: event.endDate, isAllDay: event.isAllDay))
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.40))
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
    
    // Format "Nov 26" atau "Nov 2026" agar ringkas dan tidak pernah truncate
    private func monthYearHeader(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM ''yy" // e.g. "Nov '26"
        return formatter.string(from: date)
    }
    
    private func formatTimeRange(start: Date, end: Date, isAllDay: Bool) -> String {
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
