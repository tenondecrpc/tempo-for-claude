import Foundation

enum TimeFormatPolicy {
    private static func fixedTimeLocale(use24HourTime: Bool) -> Locale {
        use24HourTime ? Locale(identifier: "en_GB_POSIX") : Locale(identifier: "en_US_POSIX")
    }

    static func clockString(from date: Date, use24HourTime: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = fixedTimeLocale(use24HourTime: use24HourTime)
        formatter.dateFormat = use24HourTime ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }

    static func sessionResetString(resetAt date: Date, now: Date, use24HourTime: Bool) -> String {
        let totalMinutes = max(0, Int(date.timeIntervalSince(now) / 60))
        let duration: String
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            duration = minutes > 0 ? "\(hours) hr \(minutes) min" : "\(hours) hr"
        } else {
            duration = "\(totalMinutes) min"
        }
        return "Resets in \(duration) (\(clockString(from: date, use24HourTime: use24HourTime)))"
    }

    static func weeklyResetString(resetAt date: Date, use24HourTime: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = fixedTimeLocale(use24HourTime: use24HourTime)
        formatter.dateFormat = use24HourTime ? "EEE, HH:mm" : "EEE, h:mm a"
        return "Resets \(formatter.string(from: date))"
    }
}
