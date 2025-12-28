import ActivityKit
import Foundation

/// Shared Activity Attributes for the Delivery Live Activity
/// This file must be accessible to both the main app and the Widget Extension
struct DeliveryActivityAttributes: ActivityAttributes {
    /// Dynamic content that changes during the activity
    public struct ContentState: Codable, Hashable {
        var driverName: String
        var estimatedDeliveryTime: Date
        var currentStatus: DeliveryStatus
        var progress: Double // 0.0 to 1.0
    }

    /// Fixed content set when activity starts
    var orderNumber: String
    var restaurantName: String
    var orderItems: String
}

/// Delivery status stages
enum DeliveryStatus: String, Codable, Hashable, CaseIterable {
    case preparing = "Preparing"
    case pickedUp = "Picked Up"
    case onTheWay = "On the Way"
    case arriving = "Arriving"
    case delivered = "Delivered"

    var icon: String {
        switch self {
        case .preparing: return "fork.knife"
        case .pickedUp: return "bag.fill"
        case .onTheWay: return "car.fill"
        case .arriving: return "location.fill"
        case .delivered: return "checkmark.circle.fill"
        }
    }

    var progressValue: Double {
        switch self {
        case .preparing: return 0.1
        case .pickedUp: return 0.33
        case .onTheWay: return 0.66
        case .arriving: return 0.85
        case .delivered: return 1.0
        }
    }
}
