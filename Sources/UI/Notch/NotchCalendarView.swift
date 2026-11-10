import SwiftUI
import AppKit

public struct NotchCalendarView: View {
    @State private var currentDate = Date()
    private let calendar = Calendar.current
    
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
    
    public init() {}
    
    public var body: some View {
        Button {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                // Header: Red calendar badge + formatted date + open indicator
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
                
                // 7-Day Week Strip
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
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            currentDate = Date()
        }
    }
    
    private func dayLetter(for date: Date) -> String {
        let weekday = calendar.component(.weekday, from: date)
        // 1 = Sunday, 2 = Monday, ...
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
