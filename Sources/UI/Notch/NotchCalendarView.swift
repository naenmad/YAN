import SwiftUI
import AppKit

public struct NotchCalendarView: View {
    public var isLarge: Bool = false
    
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
        // Padding kosong sebelum tanggal 1
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        // Tanggal 1 sampai akhir bulan
        for offset in 0..<range.count {
            if let d = calendar.date(byAdding: .day, value: offset, to: firstDay) {
                days.append(d)
            }
        }
        return days
    }
    
    public var body: some View {
        if isLarge {
            largeMonthView
        } else {
            compactWeekView
        }
    }
    
    // MARK: - Compact Week View (Saat Hover)
    
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
    
    // MARK: - Large Full Month View (Saat Diklik / Enlarged)
    
    private var largeMonthView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header: Month & Year + Navigasi
            HStack(spacing: 6) {
                Text(displayedMonth, format: .dateTime.month(.wide).year())
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer(minLength: 0)
                
                HStack(spacing: 4) {
                    Button {
                        if let prev = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
                            displayedMonth = prev
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.65))
                            .frame(width: 16, height: 16)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        displayedMonth = Date()
                    } label: {
                        Text("Today")
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundColor(.white.opacity(0.80))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        if let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
                            displayedMonth = next
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.65))
                            .frame(width: 16, height: 16)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
                    } label: {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.red.opacity(0.90))
                            .frame(width: 16, height: 16)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Open Calendar")
                }
            }
            
            // Weekday Header: S M T W T F S
            HStack(spacing: 2) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(.white.opacity(0.40))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 1)
            
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
                                        .frame(width: 16, height: 16)
                                }
                                
                                Text("\(dayNumber)")
                                    .font(.system(size: 8.5, weight: isToday ? .bold : .medium, design: .rounded))
                                    .foregroundColor(isToday ? .white : .white.opacity(0.85))
                            }
                            .frame(height: 16)
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Empty cell for alignment
                        Color.clear
                            .frame(height: 16)
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
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
