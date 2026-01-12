import SwiftUI
import UserNotifications
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .all

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        // Clear badge on launch
        clearBadge()
        // Register background tasks
        registerBackgroundTasks()
        return true
    }

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.apiplayground.refresh",
            using: nil
        ) { task in
            // Handle refresh task
            task.setTaskCompleted(success: true)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.apiplayground.processing",
            using: nil
        ) { task in
            // Handle processing task
            task.setTaskCompleted(success: true)
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear badge when app becomes active (opened from background)
        clearBadge()
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    private func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

// Deep link destination enum
enum DeepLinkDestination: Identifiable {
    case metal
    case metalGrid
    case referenceGrid
    case deviceInfo

    var id: String {
        switch self {
        case .metal: return "metal"
        case .metalGrid: return "metalGrid"
        case .referenceGrid: return "referenceGrid"
        case .deviceInfo: return "deviceInfo"
        }
    }
}

// Navigation state manager
class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    @Published var navigateToDeviceInfo = false
    @Published var navigateToMetal = false
    @Published var navigateToMetalGrid = false
    @Published var navigateToReferenceGrid = false
    @Published var deepLinkDestination: DeepLinkDestination?
}

@main
struct APIPlaygroundApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var navigationManager = NavigationManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(navigationManager)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        ContentView()
            .onOpenURL { url in
                handleDeepLink(url)
            }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "apiplayground" else { return }

        switch url.host {
        case "deviceinfo", "systemstats", "monitor":
            navigationManager.navigateToDeviceInfo = true
        case "metal", "shader":
            navigationManager.navigateToMetal = true
        case "metal-grid", "shader-grid", "metalgrid":
            navigationManager.navigateToMetalGrid = true
        case "reference", "reference-grid", "refgrid":
            navigationManager.navigateToReferenceGrid = true
        default:
            break
        }
    }
}
