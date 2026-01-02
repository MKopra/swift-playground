import WidgetKit
import SwiftUI

// MARK: - Lock Screen Widget

struct LockScreenBatteryWidget: Widget {
    let kind: String = "LockScreenBatteryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DeviceStatsProvider()) { entry in
            LockScreenBatteryView(entry: entry)
                .widgetURL(deviceInfoURL)
        }
        .configurationDisplayName("CPU & RAM")
        .description("Shows CPU, RAM, and battery on your Lock Screen. Tap to view details.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Lock Screen Views

struct LockScreenBatteryView: View {
    var entry: DeviceStatsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularBatteryView(entry: entry)
        case .accessoryRectangular:
            RectangularBatteryView(entry: entry)
        case .accessoryInline:
            InlineBatteryView(entry: entry)
        default:
            CircularBatteryView(entry: entry)
        }
    }
}

struct CircularBatteryView: View {
    let entry: DeviceStatsEntry

    var body: some View {
        Gauge(value: entry.cpuUsage, in: 0...1) {
            Text("CPU")
                .font(.system(size: 8, weight: .medium))
        } currentValueLabel: {
            Text("\(Int(entry.cpuUsage * 100))%")
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
        .containerBackground(for: .widget) { }
    }
}

struct RectangularBatteryView: View {
    let entry: DeviceStatsEntry

    var body: some View {
        VStack(spacing: 10) {
            // CPU row
            HStack(spacing: 8) {
                Text("CPU")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 36, alignment: .leading)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.2))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary)
                            .frame(width: geo.size.width * entry.cpuUsage)
                    }
                }
                .frame(height: 10)

                Text("\(Int(entry.cpuUsage * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(width: 38, alignment: .trailing)
            }

            // RAM row
            HStack(spacing: 8) {
                Text("RAM")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 36, alignment: .leading)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.2))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary)
                            .frame(width: geo.size.width * entry.memoryUsagePercent)
                    }
                }
                .frame(height: 10)

                Text("\(Int(entry.memoryUsagePercent * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(width: 38, alignment: .trailing)
            }
        }
        .containerBackground(for: .widget) { }
    }
}

struct InlineBatteryView: View {
    let entry: DeviceStatsEntry

    var body: some View {
        HStack(spacing: 4) {
            Text("CPU")
            Text("\(Int(entry.cpuUsage * 100))%")
            Text("|")
            Text("RAM")
            Text("\(Int(entry.memoryUsagePercent * 100))%")
        }
        .containerBackground(for: .widget) { }
    }
}

// MARK: - Previews

#Preview(as: .accessoryCircular) {
    LockScreenBatteryWidget()
} timeline: {
    DeviceStatsEntry(date: .now, cpuUsage: 0.35, memoryUsagePercent: 0.68, memoryUsedGB: 4.1, memoryTotalGB: 6.0, batteryLevel: 0.65, batteryState: .unplugged)
}

#Preview(as: .accessoryRectangular) {
    LockScreenBatteryWidget()
} timeline: {
    DeviceStatsEntry(date: .now, cpuUsage: 0.45, memoryUsagePercent: 0.72, memoryUsedGB: 4.3, memoryTotalGB: 6.0, batteryLevel: 0.85, batteryState: .charging)
}

#Preview(as: .accessoryInline) {
    LockScreenBatteryWidget()
} timeline: {
    DeviceStatsEntry(date: .now, cpuUsage: 0.28, memoryUsagePercent: 0.55, memoryUsedGB: 3.3, memoryTotalGB: 6.0, batteryLevel: 0.50, batteryState: .unplugged)
}
