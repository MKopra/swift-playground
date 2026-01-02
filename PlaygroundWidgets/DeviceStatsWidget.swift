import WidgetKit
import SwiftUI
import Darwin

// MARK: - Deep Link URL
let deviceInfoURL = URL(string: "apiplayground://deviceinfo")!

// MARK: - System Stats Helper

struct SystemStats {
    let cpuUsage: Double
    let memoryUsed: UInt64
    let memoryTotal: UInt64
    let memoryUsagePercent: Double
    let batteryLevel: Double
    let batteryState: UIDevice.BatteryState

    var memoryUsedGB: Double {
        Double(memoryUsed) / 1_073_741_824
    }

    var memoryTotalGB: Double {
        Double(memoryTotal) / 1_073_741_824
    }

    var memoryFreeGB: Double {
        memoryTotalGB - memoryUsedGB
    }

    static func current() -> SystemStats {
        let cpuUsage = getCPUUsage()
        let (memUsed, memTotal) = getMemoryUsage()
        let memPercent = memTotal > 0 ? Double(memUsed) / Double(memTotal) : 0

        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = Double(UIDevice.current.batteryLevel)
        let batteryState = UIDevice.current.batteryState

        return SystemStats(
            cpuUsage: cpuUsage,
            memoryUsed: memUsed,
            memoryTotal: memTotal,
            memoryUsagePercent: memPercent,
            batteryLevel: batteryLevel,
            batteryState: batteryState
        )
    }

    private static func getCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0

        let err = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCpuInfo
        )

        guard err == KERN_SUCCESS, let cpuInfo = cpuInfo else {
            return 0.0
        }

        var totalUsage: Double = 0

        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            let user = Double(cpuInfo[offset + Int(CPU_STATE_USER)])
            let system = Double(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            let nice = Double(cpuInfo[offset + Int(CPU_STATE_NICE)])
            let idle = Double(cpuInfo[offset + Int(CPU_STATE_IDLE)])

            let total = user + system + nice + idle
            let used = user + system + nice

            if total > 0 {
                totalUsage += used / total
            }
        }

        let cpuInfoSize = vm_size_t(MemoryLayout<integer_t>.stride * Int(numCpuInfo))
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), cpuInfoSize)

        return totalUsage / Double(numCPUs)
    }

    private static func getMemoryUsage() -> (used: UInt64, total: UInt64) {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        let total = ProcessInfo.processInfo.physicalMemory

        guard result == KERN_SUCCESS else {
            return (0, total)
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize

        let used = active + wired + compressed

        return (used, total)
    }
}

// MARK: - Device Stats Provider

struct DeviceStatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> DeviceStatsEntry {
        DeviceStatsEntry(
            date: Date(),
            cpuUsage: 0.35,
            memoryUsagePercent: 0.65,
            memoryUsedGB: 4.2,
            memoryTotalGB: 6.0,
            batteryLevel: 0.75,
            batteryState: .unplugged
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DeviceStatsEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DeviceStatsEntry>) -> Void) {
        let entry = createEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry() -> DeviceStatsEntry {
        let stats = SystemStats.current()

        return DeviceStatsEntry(
            date: Date(),
            cpuUsage: stats.cpuUsage,
            memoryUsagePercent: stats.memoryUsagePercent,
            memoryUsedGB: stats.memoryUsedGB,
            memoryTotalGB: stats.memoryTotalGB,
            batteryLevel: stats.batteryLevel,
            batteryState: stats.batteryState
        )
    }
}

// MARK: - Device Stats Entry

struct DeviceStatsEntry: TimelineEntry {
    let date: Date
    let cpuUsage: Double
    let memoryUsagePercent: Double
    let memoryUsedGB: Double
    let memoryTotalGB: Double
    let batteryLevel: Double
    let batteryState: UIDevice.BatteryState
}

// MARK: - Home Screen Widget Views

struct DeviceStatsWidgetEntryView: View {
    var entry: DeviceStatsProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        .widgetURL(deviceInfoURL)
    }
}

struct SmallWidgetView: View {
    let entry: DeviceStatsEntry

    var body: some View {
        VStack(spacing: 6) {
            // Header
            HStack {
                Image(systemName: "cpu")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.cyan)
                Text("CPU & RAM")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
            }

            // Gauges
            HStack(spacing: 16) {
                // CPU Gauge
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 7)
                            .opacity(0.2)
                            .foregroundStyle(.cyan)

                        Circle()
                            .trim(from: 0, to: entry.cpuUsage)
                            .stroke(style: StrokeStyle(lineWidth: 7, lineCap: .round))
                            .foregroundStyle(.cyan)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(entry.cpuUsage * 100))%")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .frame(width: 50, height: 50)

                    Text("CPU")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                // RAM Gauge
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 7)
                            .opacity(0.2)
                            .foregroundStyle(ramColor)

                        Circle()
                            .trim(from: 0, to: entry.memoryUsagePercent)
                            .stroke(style: StrokeStyle(lineWidth: 7, lineCap: .round))
                            .foregroundStyle(ramColor)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(entry.memoryUsagePercent * 100))%")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .frame(width: 50, height: 50)

                    Text("RAM")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            // Battery bar
            HStack(spacing: 6) {
                Image(systemName: batteryIcon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(batteryColor)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.3))

                        RoundedRectangle(cornerRadius: 3)
                            .fill(batteryColor)
                            .frame(width: geo.size.width * max(0, entry.batteryLevel))
                    }
                }
                .frame(height: 8)

                Text("\(Int(entry.batteryLevel * 100))%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    var ramColor: Color {
        if entry.memoryUsagePercent > 0.9 { return .red }
        if entry.memoryUsagePercent > 0.75 { return .orange }
        return .green
    }

    var batteryIcon: String {
        if entry.batteryState == .charging { return "bolt.fill" }
        return "battery.100"
    }

    var batteryColor: Color {
        if entry.batteryState == .charging { return .green }
        if entry.batteryLevel <= 0.2 { return .red }
        if entry.batteryLevel <= 0.4 { return .orange }
        return .green
    }
}

struct MediumWidgetView: View {
    let entry: DeviceStatsEntry

    var body: some View {
        HStack(spacing: 20) {
            // CPU section
            VStack(alignment: .center, spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 8)
                        .opacity(0.2)
                        .foregroundStyle(.cyan)

                    Circle()
                        .trim(from: 0, to: entry.cpuUsage)
                        .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .foregroundStyle(.cyan)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Image(systemName: "cpu")
                            .font(.system(size: 14, weight: .semibold))
                        Text("\(Int(entry.cpuUsage * 100))%")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.cyan)
                }
                .frame(width: 65, height: 65)

                Text("CPU")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 70)

            // RAM section
            VStack(alignment: .center, spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 8)
                        .opacity(0.2)
                        .foregroundStyle(ramColor)

                    Circle()
                        .trim(from: 0, to: entry.memoryUsagePercent)
                        .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .foregroundStyle(ramColor)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Image(systemName: "memorychip")
                            .font(.system(size: 14, weight: .semibold))
                        Text("\(Int(entry.memoryUsagePercent * 100))%")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(ramColor)
                }
                .frame(width: 65, height: 65)

                Text("\(String(format: "%.1f", entry.memoryUsedGB))/\(String(format: "%.0f", entry.memoryTotalGB))GB")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 70)

            // Battery section
            VStack(alignment: .center, spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 8)
                        .opacity(0.2)
                        .foregroundStyle(batteryColor)

                    Circle()
                        .trim(from: 0, to: max(0, entry.batteryLevel))
                        .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .foregroundStyle(batteryColor)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Image(systemName: batteryIcon)
                            .font(.system(size: 14, weight: .semibold))
                        Text("\(Int(entry.batteryLevel * 100))%")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(batteryColor)
                }
                .frame(width: 65, height: 65)

                Text(batteryStateText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    var ramColor: Color {
        if entry.memoryUsagePercent > 0.9 { return .red }
        if entry.memoryUsagePercent > 0.75 { return .orange }
        return .green
    }

    var batteryIcon: String {
        if entry.batteryState == .charging { return "bolt.fill" }
        if entry.batteryState == .full { return "battery.100" }
        return "battery.75"
    }

    var batteryColor: Color {
        if entry.batteryState == .charging { return .green }
        if entry.batteryLevel <= 0.2 { return .red }
        if entry.batteryLevel <= 0.4 { return .orange }
        return .green
    }

    var batteryStateText: String {
        switch entry.batteryState {
        case .charging: return "Charging"
        case .full: return "Full"
        case .unplugged: return "Battery"
        default: return "Unknown"
        }
    }
}

// MARK: - Home Screen Widget

struct DeviceStatsWidget: Widget {
    let kind: String = "DeviceStatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DeviceStatsProvider()) { entry in
            DeviceStatsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("CPU & RAM")
        .description("Monitor CPU, RAM, and battery usage. Tap to view details.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    DeviceStatsWidget()
} timeline: {
    DeviceStatsEntry(date: .now, cpuUsage: 0.35, memoryUsagePercent: 0.68, memoryUsedGB: 4.1, memoryTotalGB: 6.0, batteryLevel: 0.75, batteryState: .unplugged)
}

#Preview(as: .systemMedium) {
    DeviceStatsWidget()
} timeline: {
    DeviceStatsEntry(date: .now, cpuUsage: 0.72, memoryUsagePercent: 0.85, memoryUsedGB: 5.1, memoryTotalGB: 6.0, batteryLevel: 0.45, batteryState: .charging)
}
