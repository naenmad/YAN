import Foundation
import EventKit
import SwiftUI

public struct NotchEvent: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let color: Color
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        color: Color = .blue
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.color = color
    }
}

@MainActor
public final class CalendarManager: ObservableObject {
    public static let shared = CalendarManager()
    
    private let eventStore = EKEventStore()
    
    @Published public var events: [NotchEvent] = []
    @Published public var hasPermission: Bool = false
    
    private init() {
        checkPermissionAndFetch()
    }
    
    public func checkPermissionAndFetch() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .authorized {
            self.hasPermission = true
            fetchEvents(for: Date())
        } else if status == .notDetermined {
            requestAccess()
        }
    }
    
    public func requestAccess() {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                    if granted {
                        self?.fetchEvents(for: Date())
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                    if granted {
                        self?.fetchEvents(for: Date())
                    }
                }
            }
        }
    }
    
    public func fetchEvents(for date: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return }
        
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        
        self.events = ekEvents.map { ek in
            let eventColor: Color
            if let cgColor = ek.calendar?.cgColor {
                eventColor = Color(cgColor)
            } else {
                eventColor = .red
            }
            return NotchEvent(
                id: ek.eventIdentifier ?? UUID().uuidString,
                title: ek.title ?? "Event",
                startDate: ek.startDate ?? date,
                endDate: ek.endDate ?? date,
                isAllDay: ek.isAllDay,
                color: eventColor
            )
        }.sorted { $0.startDate < $1.startDate }
    }
}
