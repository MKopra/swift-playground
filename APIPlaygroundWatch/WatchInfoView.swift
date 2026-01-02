import SwiftUI
import WatchKit

struct WatchInfoView: View {
    @State private var deviceInfo: [InfoItem] = []

    struct InfoItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let value: String
        let color: Color
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(deviceInfo) { item in
                    HStack {
                        Image(systemName: item.icon)
                            .foregroundStyle(item.color)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 0) {
                            Text(item.title)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(item.value)
                                .font(.caption)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(8)
                    .background(Color(.darkGray).opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Device Info")
        .onAppear {
            loadDeviceInfo()
        }
    }

    private func loadDeviceInfo() {
        let device = WKInterfaceDevice.current()

        deviceInfo = [
            InfoItem(icon: "applewatch", title: "Model", value: device.model, color: .gray),
            InfoItem(icon: "info.circle", title: "Name", value: device.name, color: .blue),
            InfoItem(icon: "gearshape", title: "System", value: device.systemName, color: .orange),
            InfoItem(icon: "number", title: "Version", value: device.systemVersion, color: .green),
            InfoItem(icon: "memorychip", title: "Identifier", value: identifierForVendor(), color: .purple),
            InfoItem(icon: "ruler", title: "Screen Size", value: screenSize(), color: .cyan),
            InfoItem(icon: "textformat.size", title: "Content Size", value: contentSize(), color: .indigo),
            InfoItem(icon: "hand.raised", title: "Wrist Location", value: wristLocation(device), color: .pink),
            InfoItem(icon: "crown", title: "Crown Direction", value: crownDirection(device), color: .yellow),
            InfoItem(icon: "drop.fill", title: "Water Lock", value: waterLockStatus(device), color: .blue),
            InfoItem(icon: "battery.100", title: "Battery State", value: batteryState(device), color: .green)
        ]
    }

    private func identifierForVendor() -> String {
        WKInterfaceDevice.current().identifierForVendor?.uuidString.prefix(8).description ?? "Unknown"
    }

    private func screenSize() -> String {
        let bounds = WKInterfaceDevice.current().screenBounds
        return "\(Int(bounds.width))×\(Int(bounds.height))"
    }

    private func contentSize() -> String {
        WKInterfaceDevice.current().preferredContentSizeCategory
    }

    private func wristLocation(_ device: WKInterfaceDevice) -> String {
        switch device.wristLocation {
        case .left: return "Left Wrist"
        case .right: return "Right Wrist"
        @unknown default: return "Unknown"
        }
    }

    private func crownDirection(_ device: WKInterfaceDevice) -> String {
        switch device.crownOrientation {
        case .left: return "Left"
        case .right: return "Right"
        @unknown default: return "Unknown"
        }
    }

    private func waterLockStatus(_ device: WKInterfaceDevice) -> String {
        device.isWaterLockEnabled ? "Enabled" : "Disabled"
    }

    private func batteryState(_ device: WKInterfaceDevice) -> String {
        device.isBatteryMonitoringEnabled = true
        let level = device.batteryLevel
        let state = device.batteryState

        var stateString: String
        switch state {
        case .charging: stateString = "Charging"
        case .full: stateString = "Full"
        case .unplugged: stateString = "Unplugged"
        case .unknown: stateString = "Unknown"
        @unknown default: stateString = "Unknown"
        }

        if level >= 0 {
            return "\(Int(level * 100))% (\(stateString))"
        }
        return stateString
    }
}

#Preview {
    NavigationStack {
        WatchInfoView()
    }
}
