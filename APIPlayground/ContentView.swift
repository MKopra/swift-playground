import SwiftUI
import ComposableArchitecture

struct Feature: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
}

enum FullScreenDestination: String, Identifiable {
    case metal
    case metalGrid
    case referenceGrid

    var id: String { rawValue }
}

struct ContentView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var navigationPath = NavigationPath()
    @State private var fullScreenDestination: FullScreenDestination?

    private let features: [Feature] = [
        Feature(title: "Camera", icon: "camera.fill", color: .gray),
        Feature(title: "Location", icon: "location.fill", color: .blue),
        Feature(title: "Haptics", icon: "waveform", color: .orange),
        Feature(title: "Motion", icon: "gyroscope", color: .green),
        Feature(title: "Notifications", icon: "bell.badge.fill", color: .red),
        Feature(title: "Biometrics", icon: "faceid", color: .purple),
        Feature(title: "Speech", icon: "waveform.circle.fill", color: .cyan),
        Feature(title: "Bluetooth", icon: "antenna.radiowaves.left.and.right", color: .indigo),
        Feature(title: "Altimeter", icon: "mountain.2.fill", color: .mint),
        Feature(title: "Audio", icon: "mic.fill", color: .pink),
        Feature(title: "Compass", icon: "location.north.fill", color: .red),
        Feature(title: "Torch", icon: "flashlight.on.fill", color: .yellow),
        Feature(title: "Proximity", icon: "sensor.fill", color: .teal),
        Feature(title: "Network", icon: "network", color: .blue),
        Feature(title: "Battery", icon: "battery.100", color: .green),
        Feature(title: "NFC", icon: "wave.3.right", color: .cyan),
        Feature(title: "Live Text", icon: "text.viewfinder", color: .indigo),
        Feature(title: "Shazam", icon: "shazam.logo.fill", color: .blue),
        Feature(title: "Screen Record", icon: "record.circle", color: .red),
        Feature(title: "ML Vision", icon: "brain.head.profile", color: .purple),
        Feature(title: "AR Kit", icon: "arkit", color: .orange),
        Feature(title: "Health", icon: "heart.fill", color: .pink),
        Feature(title: "Drawing", icon: "pencil.tip", color: .yellow),
        Feature(title: "Music", icon: "music.note.house.fill", color: .pink),
        Feature(title: "Wallet", icon: "wallet.pass.fill", color: .orange),
        Feature(title: "Live Activity", icon: "rectangle.portrait.on.rectangle.portrait.fill", color: .purple),
        Feature(title: "Data Scanner", icon: "barcode.viewfinder", color: .teal),
        Feature(title: "Weather", icon: "cloud.sun.fill", color: .cyan),
        Feature(title: "Calendar", icon: "calendar", color: .red),
        Feature(title: "Contacts", icon: "person.crop.circle", color: .blue),
        Feature(title: "Device Info", icon: "cpu", color: .gray),
        Feature(title: "Telephony", icon: "phone.connection", color: .green),
        Feature(title: "Accessibility", icon: "accessibility", color: .blue),
        Feature(title: "Translation", icon: "character.bubble", color: .blue),
        Feature(title: "Spotlight", icon: "magnifyingglass", color: .blue),
        Feature(title: "Background Tasks", icon: "clock.arrow.circlepath", color: .orange),
        Feature(title: "SharePlay", icon: "shareplay", color: .green),
        Feature(title: "CallKit", icon: "phone.badge.waveform", color: .green),
        Feature(title: "CloudKit", icon: "icloud.fill", color: .blue),
        Feature(title: "Photo Map", icon: "map.fill", color: .green),
        Feature(title: "Graphics", icon: "paintpalette.fill", color: .purple)
    ]

    private var deviceInfoFeature: Feature {
        features.first { $0.title == "Device Info" }!
    }

    private func checkAndHandleDeepLinks() {
        if navigationManager.navigateToDeviceInfo {
            navigationPath.append(deviceInfoFeature)
            navigationManager.navigateToDeviceInfo = false
        }
        if navigationManager.navigateToMetal {
            fullScreenDestination = .metal
            navigationManager.navigateToMetal = false
        }
        if navigationManager.navigateToMetalGrid {
            fullScreenDestination = .metalGrid
            navigationManager.navigateToMetalGrid = false
        }
        if navigationManager.navigateToReferenceGrid {
            fullScreenDestination = .referenceGrid
            navigationManager.navigateToReferenceGrid = false
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                Section {
                    ForEach(features) { feature in
                        NavigationLink(value: feature) {
                            SettingsRow(
                                title: feature.title,
                                icon: feature.icon,
                                color: feature.color
                            )
                        }
                    }
                }
            }
            .navigationTitle("API Playground")
            .navigationDestination(for: Feature.self) { feature in
                switch feature.title {
                case "Camera": CameraView()
                case "Location": LocationView()
                case "Haptics": HapticsView()
                case "Motion": MotionView()
                case "Notifications": NotificationsView()
                case "Biometrics": BiometricsView()
                case "Speech": SpeechView()
                case "Bluetooth": BluetoothView()
                case "Altimeter": AltimeterView()
                case "Audio": AudioView()
                case "Compass": CompassView()
                case "Torch": TorchView()
                case "Proximity": ProximityView()
                case "Network": NetworkView()
                case "Battery": BatteryView()
                case "NFC": NFCView()
                case "Live Text": LiveTextView()
                case "Shazam": ShazamView()
                case "Screen Record": ScreenRecordView()
                case "ML Vision": MLVisionView()
                case "AR Kit": ARKitView()
                case "Health": HealthKitView()
                case "Drawing": PencilKitView()
                case "Music": MusicKitView()
                case "Wallet": WalletView()
                case "Live Activity": LiveActivityListView()
                case "Data Scanner": DataScannerDemoView()
                case "Weather": WeatherKitView()
                case "Calendar": EventKitView()
                case "Contacts": ContactsView()
                case "Device Info": DeviceInfoView()
                case "Telephony": TelephonyView()
                case "Accessibility": AccessibilityView()
                case "Translation":
                    if #available(iOS 17.4, *) {
                        TranslationView()
                    } else {
                        TranslationViewFallback()
                    }
                case "Spotlight": SpotlightView()
                case "Background Tasks": BackgroundTasksView()
                case "SharePlay": SharePlayView()
                case "CallKit": CallKitView()
                case "CloudKit": CloudKitView()
                case "Photo Map":
                    PhotoMapView(
                        store: Store(initialState: PhotoMapFeature.State()) {
                            PhotoMapFeature()
                        }
                    )
                case "Graphics": GraphicsView()
                default: FeatureDetailView(feature: feature)
                }
            }
        }
        .onAppear {
            // Handle deep links that arrived before view appeared
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                checkAndHandleDeepLinks()
            }
        }
        .task {
            // Also check after a brief delay for cold start deep links
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
            await MainActor.run {
                checkAndHandleDeepLinks()
            }
        }
        .onChange(of: navigationManager.navigateToDeviceInfo) { _, shouldNavigate in
            if shouldNavigate {
                navigationPath.append(deviceInfoFeature)
                navigationManager.navigateToDeviceInfo = false
            }
        }
        .onChange(of: navigationManager.navigateToMetal) { _, shouldNavigate in
            if shouldNavigate {
                fullScreenDestination = .metal
                navigationManager.navigateToMetal = false
            }
        }
        .onChange(of: navigationManager.navigateToMetalGrid) { _, shouldNavigate in
            if shouldNavigate {
                fullScreenDestination = .metalGrid
                navigationManager.navigateToMetalGrid = false
            }
        }
        .onChange(of: navigationManager.navigateToReferenceGrid) { _, shouldNavigate in
            if shouldNavigate {
                fullScreenDestination = .referenceGrid
                navigationManager.navigateToReferenceGrid = false
            }
        }
        .fullScreenCover(item: $fullScreenDestination) { destination in
            switch destination {
            case .metal:
                MetalView(showGrid: false)
            case .metalGrid:
                MetalView(showGrid: true)
            case .referenceGrid:
                ReferenceImageView(showGrid: true)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NavigationManager.shared)
}
