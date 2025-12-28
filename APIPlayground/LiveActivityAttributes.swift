import ActivityKit
import Foundation

// MARK: - Pomodoro Focus

struct PomodoroActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var isWorkPhase: Bool
        var secondsRemaining: Int
        var totalSeconds: Int
        var currentSession: Int
        var totalSessions: Int
        var isPaused: Bool
    }

    var taskName: String
}

// MARK: - Parking Meter

struct ParkingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var minutesRemaining: Int
        var totalMinutes: Int
        var isExpired: Bool
        var spotInfo: String
    }

    var licensePlate: String
    var location: String
}

enum ParkingUrgency {
    case safe, warning, critical, expired

    static func from(minutes: Int, total: Int) -> ParkingUrgency {
        if minutes <= 0 { return .expired }
        let percentage = Double(minutes) / Double(total)
        if percentage > 0.3 { return .safe }
        if percentage > 0.1 { return .warning }
        return .critical
    }
}

// MARK: - Caffeine Tracker

struct CaffeineActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentMg: Double
        var startMg: Double
        var hoursElapsed: Double
        var estimatedClearTime: Date
    }

    var drinkName: String
    var startTime: Date
}

// MARK: - Workout Rest Timer

struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var secondsRemaining: Int
        var totalSeconds: Int
        var currentSet: Int
        var totalSets: Int
        var exerciseName: String
        var weight: Int
        var reps: Int
        var isResting: Bool
        var restEndTime: Date?  // For auto-updating countdown display
    }

    var workoutName: String
    var useRestTimer: Bool
}

// MARK: - Auction Countdown

struct AuctionActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var secondsRemaining: Int
        var currentBid: Double
        var numberOfBids: Int
        var isWinning: Bool
        var isEnded: Bool
    }

    var itemName: String
    var itemImage: String  // SF Symbol
}

// MARK: - Rocket Launch

struct RocketActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var secondsToLaunch: Int
        var phase: LaunchPhase
        var missionStatus: String
    }

    var missionName: String
    var rocketName: String
}

enum LaunchPhase: String, Codable, Hashable {
    case holding = "HOLD"
    case countdown = "T-MINUS"
    case liftoff = "LIFTOFF"
    case maxQ = "MAX-Q"
    case meco = "MECO"
    case success = "SUCCESS"

    var color: String {
        switch self {
        case .holding: return "yellow"
        case .countdown: return "blue"
        case .liftoff: return "orange"
        case .maxQ: return "red"
        case .meco: return "purple"
        case .success: return "green"
        }
    }
}

// MARK: - Sports Score

struct SportsActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var homeScore: Int
        var awayScore: Int
        var quarter: String
        var timeRemaining: String
        var possession: String  // "home" or "away"
        var lastPlay: String
    }

    var homeTeam: String
    var awayTeam: String
    var homeColor: String
    var awayColor: String
}

// MARK: - Egg Timer

struct EggTimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var secondsRemaining: Int
        var totalSeconds: Int
        var isDone: Bool
    }

    var eggStyle: EggStyle
    var quantity: Int
}

enum EggStyle: String, Codable, Hashable, CaseIterable {
    case soft = "Soft Boiled"
    case medium = "Medium Boiled"
    case hard = "Hard Boiled"
    case poached = "Poached"

    var cookTime: Int {  // seconds
        switch self {
        case .soft: return 360      // 6 minutes
        case .medium: return 540    // 9 minutes
        case .hard: return 720      // 12 minutes
        case .poached: return 240   // 4 minutes
        }
    }

    var icon: String {
        switch self {
        case .soft: return "oval"
        case .medium: return "oval.fill"
        case .hard: return "circle.fill"
        case .poached: return "drop.fill"
        }
    }

    var description: String {
        switch self {
        case .soft: return "Runny yolk, set white"
        case .medium: return "Jammy yolk, firm white"
        case .hard: return "Fully set yolk and white"
        case .poached: return "Delicate, no shell"
        }
    }
}
