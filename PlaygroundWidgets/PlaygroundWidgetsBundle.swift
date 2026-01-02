import WidgetKit
import SwiftUI

@main
struct PlaygroundWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen Widget - System Monitor
        DeviceStatsWidget()
        // Lock Screen Widget - System Monitor
        LockScreenBatteryWidget()
        // Control Center Widget (iOS 18+)
        if #available(iOS 18.0, *) {
            SystemMonitorControl()
        }
        // Live Activity for delivery tracking
        DeliveryLiveActivity()
        // Live Activity for guided breathing
        BreathingLiveActivity()
        // Pomodoro Focus Timer
        PomodoroLiveActivity()
        // Parking Meter
        ParkingLiveActivity()
        // Caffeine Tracker
        CaffeineLiveActivity()
        // Workout Rest Timer
        WorkoutLiveActivity()
        // Auction Countdown
        AuctionLiveActivity()
        // Rocket Launch
        RocketLiveActivity()
        // Sports Score
        SportsLiveActivity()
        // Egg Timer
        EggTimerLiveActivity()
    }
}
