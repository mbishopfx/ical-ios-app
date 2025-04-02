import Foundation

class ICalGenerator {
    static func generateICalFile(events: [CalendarEvent], calendarName: String) -> String {
        var icalString = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//iCalAgent//EN
        CALSCALE:GREGORIAN
        X-WR-CALNAME:\(calendarName)
        X-WR-TIMEZONE:UTC
        
        """
        
        for event in events {
            icalString += generateEventString(event)
        }
        
        icalString += "END:VCALENDAR"
        return icalString
    }
    
    private static func generateEventString(_ event: CalendarEvent) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let startDate = dateFormatter.string(from: event.startDate)
        let endDate = dateFormatter.string(from: event.endDate)
        
        var eventString = """
        BEGIN:VEVENT
        UID:\(event.id.uuidString)
        DTSTAMP:\(dateFormatter.string(from: Date()))
        DTSTART:\(event.isAllDay ? "VALUE=DATE:\(startDate.prefix(8))" : startDate)
        DTEND:\(event.isAllDay ? "VALUE=DATE:\(endDate.prefix(8))" : endDate)
        SUMMARY:\(event.title)
        DESCRIPTION:\(event.description)
        """
        
        if let location = event.location {
            eventString += "\nLOCATION:\(location)"
        }
        
        if let attendees = event.attendees {
            for attendee in attendees {
                eventString += "\nATTENDEE:mailto:\(attendee)"
            }
        }
        
        if let category = event.category {
            eventString += "\nCATEGORIES:\(category)"
        }
        
        eventString += "\nEND:VEVENT\n"
        return eventString
    }
} 