import ActivityKit
import Foundation

/// ActivityAttributes for the Breath Pacer Live Activity
/// Demonstrates using Live Activity update rate as a FEATURE for guided breathing
struct BreathingActivityAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable {
        /// Current phase of the breathing cycle
        var phase: BreathingPhase
        /// Seconds remaining in current phase
        var secondsRemaining: Int
        /// Total seconds for current phase
        var phaseTotal: Int
        /// Current cycle number
        var currentCycle: Int
        /// Total cycles in session
        var totalCycles: Int
        /// Session start time for elapsed display
        var sessionStartTime: Date
        /// Whether session is paused
        var isPaused: Bool
    }

    /// The breathing pattern being used
    var pattern: BreathingPattern
    /// Session duration in minutes
    var sessionMinutes: Int
}

/// Phases of a breathing cycle
enum BreathingPhase: String, Codable, Hashable {
    case inhale = "Inhale"
    case holdIn = "Hold"
    case exhale = "Exhale"
    case holdOut = "Rest"

    var icon: String {
        switch self {
        case .inhale: return "arrow.down.circle.fill"
        case .holdIn: return "pause.circle.fill"
        case .exhale: return "arrow.up.circle.fill"
        case .holdOut: return "circle.dashed"
        }
    }

    var instruction: String {
        switch self {
        case .inhale: return "Breathe in slowly..."
        case .holdIn: return "Hold your breath..."
        case .exhale: return "Breathe out slowly..."
        case .holdOut: return "Rest..."
        }
    }

    var color: String {
        switch self {
        case .inhale: return "blue"
        case .holdIn: return "purple"
        case .exhale: return "green"
        case .holdOut: return "gray"
        }
    }
}

/// Predefined breathing patterns
enum BreathingPattern: String, Codable, Hashable, CaseIterable {
    case boxBreathing = "Box Breathing"
    case relaxing478 = "4-7-8 Relaxing"
    case energizing = "Energizing"
    case calm = "Calming"

    var description: String {
        switch self {
        case .boxBreathing: return "4-4-4-4 • Navy SEAL technique for focus"
        case .relaxing478: return "4-7-8 • Dr. Weil's relaxation method"
        case .energizing: return "Quick inhale, slow exhale for energy"
        case .calm: return "Extended exhale for nervous system calm"
        }
    }

    var icon: String {
        switch self {
        case .boxBreathing: return "square"
        case .relaxing478: return "moon.stars"
        case .energizing: return "bolt.fill"
        case .calm: return "leaf.fill"
        }
    }

    /// Returns (inhale, holdIn, exhale, holdOut) in seconds
    var timing: (inhale: Int, holdIn: Int, exhale: Int, holdOut: Int) {
        switch self {
        case .boxBreathing:
            return (4, 4, 4, 4)  // 16 second cycle
        case .relaxing478:
            return (4, 7, 8, 0)  // 19 second cycle
        case .energizing:
            return (2, 0, 6, 2)  // 10 second cycle
        case .calm:
            return (4, 2, 8, 2)  // 16 second cycle
        }
    }

    /// Total cycle duration in seconds
    var cycleDuration: Int {
        let t = timing
        return t.inhale + t.holdIn + t.exhale + t.holdOut
    }

    /// Get duration for a specific phase
    func duration(for phase: BreathingPhase) -> Int {
        let t = timing
        switch phase {
        case .inhale: return t.inhale
        case .holdIn: return t.holdIn
        case .exhale: return t.exhale
        case .holdOut: return t.holdOut
        }
    }

    /// Get next phase in the cycle
    func nextPhase(after phase: BreathingPhase) -> BreathingPhase {
        let t = timing
        switch phase {
        case .inhale:
            return t.holdIn > 0 ? .holdIn : .exhale
        case .holdIn:
            return .exhale
        case .exhale:
            return t.holdOut > 0 ? .holdOut : .inhale
        case .holdOut:
            return .inhale
        }
    }

    /// Check if this is the start of a new cycle
    func isNewCycle(phase: BreathingPhase) -> Bool {
        return phase == .inhale
    }
}
