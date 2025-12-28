import SwiftUI

struct Feature: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
}

struct ContentView: View {
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
        Feature(title: "Contacts", icon: "person.crop.circle", color: .blue)
    ]

    var body: some View {
        NavigationStack {
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
                case "Live Activity": LiveActivityView()
                case "Data Scanner": DataScannerDemoView()
                case "Weather": WeatherKitView()
                case "Calendar": EventKitView()
                case "Contacts": ContactsView()
                default: FeatureDetailView(feature: feature)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
