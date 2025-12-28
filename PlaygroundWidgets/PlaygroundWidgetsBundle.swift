import WidgetKit
import SwiftUI

@main
struct PlaygroundWidgetsBundle: WidgetBundle {
    var body: some Widget {
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
