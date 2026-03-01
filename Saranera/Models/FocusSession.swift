import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID
    var date: Date
    var focusMinutes: Int
    var sessionsCompleted: Int
    var focusDuration: Int
    var shortBreakDuration: Int
    var longBreakDuration: Int

    init(
        id: UUID = UUID(),
        date: Date,
        focusMinutes: Int,
        sessionsCompleted: Int,
        focusDuration: Int,
        shortBreakDuration: Int,
        longBreakDuration: Int
    ) {
        self.id = id
        self.date = date
        self.focusMinutes = focusMinutes
        self.sessionsCompleted = sessionsCompleted
        self.focusDuration = focusDuration
        self.shortBreakDuration = shortBreakDuration
        self.longBreakDuration = longBreakDuration
    }
}
