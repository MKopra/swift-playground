import SwiftUI
import Darwin

// MARK: - Live System Stats

struct LiveSystemStats {
    let cpuUsage: Double
    let memoryUsed: UInt64
    let memoryTotal: UInt64
    let memoryUsagePercent: Double

    var memoryUsedGB: Double {
        Double(memoryUsed) / 1_073_741_824
    }

    var memoryTotalGB: Double {
        Double(memoryTotal) / 1_073_741_824
    }

    static func current() -> LiveSystemStats {
        let cpuUsage = getCPUUsage()
        let (memUsed, memTotal) = getMemoryUsage()
        let memPercent = memTotal > 0 ? Double(memUsed) / Double(memTotal) : 0

        return LiveSystemStats(
            cpuUsage: cpuUsage,
            memoryUsed: memUsed,
            memoryTotal: memTotal,
            memoryUsagePercent: memPercent
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

struct DeviceInfoView: View {
    @State private var deviceInfo = DeviceInfoData()
    @State private var thermalState: ProcessInfo.ThermalState = .nominal
    @State private var liveStats = LiveSystemStats.current()
    @State private var statsTimer: Timer?

    var body: some View {
        List {
            Section("CPU & RAM") {
                // CPU Usage
                HStack {
                    Image(systemName: "cpu")
                        .foregroundStyle(.cyan)
                        .frame(width: 24)
                    Text("CPU Usage")
                    Spacer()
                    Text("\(Int(liveStats.cpuUsage * 100))%")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(cpuColor)
                }

                ProgressView(value: liveStats.cpuUsage)
                    .tint(cpuColor)
                    .padding(.vertical, 2)

                // RAM Usage
                HStack {
                    Image(systemName: "memorychip")
                        .foregroundStyle(ramColor)
                        .frame(width: 24)
                    Text("RAM Usage")
                    Spacer()
                    Text("\(Int(liveStats.memoryUsagePercent * 100))%")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(ramColor)
                }

                ProgressView(value: liveStats.memoryUsagePercent)
                    .tint(ramColor)
                    .padding(.vertical, 2)

                HStack {
                    Text("RAM")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(String(format: "%.1f", liveStats.memoryUsedGB)) / \(String(format: "%.1f", liveStats.memoryTotalGB)) GB")
                        .foregroundStyle(.secondary)
                }
                .font(.footnote)
            }

            Section("Device") {
                DeviceInfoRow(label: "Name", value: deviceInfo.deviceName)
                DeviceInfoRow(label: "Model", value: deviceInfo.deviceModel)
                DeviceInfoRow(label: "System", value: "\(deviceInfo.systemName) \(deviceInfo.systemVersion)")
                DeviceInfoRow(label: "Identifier", value: deviceInfo.identifierForVendor)
            }

            Section("Hardware") {
                DeviceInfoRow(label: "Processor Cores", value: "\(deviceInfo.processorCount)")
                DeviceInfoRow(label: "Active Cores", value: "\(deviceInfo.activeProcessorCount)")
                DeviceInfoRow(label: "Physical Memory", value: formatBytes(deviceInfo.physicalMemory))
            }

            Section("Storage") {
                DeviceInfoRow(label: "Total", value: formatBytes(deviceInfo.totalDiskSpace))
                DeviceInfoRow(label: "Used", value: formatBytes(deviceInfo.usedDiskSpace))
                DeviceInfoRow(label: "Available", value: formatBytes(deviceInfo.freeDiskSpace))

                ProgressView(value: deviceInfo.storageUsagePercent)
                    .tint(storageColor)
                    .padding(.vertical, 4)
            }

            Section("System State") {
                HStack {
                    Text("Thermal State")
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: thermalIcon)
                            .foregroundStyle(thermalColor)
                        Text(thermalText)
                            .foregroundStyle(thermalColor)
                    }
                }

                DeviceInfoRow(label: "Low Power Mode", value: deviceInfo.isLowPowerModeEnabled ? "Enabled" : "Disabled")
                DeviceInfoRow(label: "Uptime", value: formatUptime(deviceInfo.uptime))
            }

            Section("Process") {
                DeviceInfoRow(label: "Host Name", value: deviceInfo.hostName)
                DeviceInfoRow(label: "OS Build", value: deviceInfo.operatingSystemVersionString)
            }
        }
        .navigationTitle("Device Info")
        .onAppear {
            updateDeviceInfo()
            startThermalMonitoring()
            startStatsTimer()
        }
        .onDisappear {
            stopThermalMonitoring()
            stopStatsTimer()
        }
    }

    private var cpuColor: Color {
        if liveStats.cpuUsage > 0.9 { return .red }
        if liveStats.cpuUsage > 0.7 { return .orange }
        return .cyan
    }

    private var ramColor: Color {
        if liveStats.memoryUsagePercent > 0.9 { return .red }
        if liveStats.memoryUsagePercent > 0.75 { return .orange }
        return .green
    }

    private var storageColor: Color {
        if deviceInfo.storageUsagePercent > 0.9 { return .red }
        if deviceInfo.storageUsagePercent > 0.75 { return .orange }
        return .blue
    }

    private var thermalIcon: String {
        switch thermalState {
        case .nominal: return "thermometer.low"
        case .fair: return "thermometer.medium"
        case .serious: return "thermometer.high"
        case .critical: return "thermometer.sun.fill"
        @unknown default: return "thermometer.medium"
        }
    }

    private var thermalColor: Color {
        switch thermalState {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .gray
        }
    }

    private var thermalText: String {
        switch thermalState {
        case .nominal: return "Cool"
        case .fair: return "Warm"
        case .serious: return "Hot"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private func updateDeviceInfo() {
        deviceInfo = DeviceInfoData()
        thermalState = ProcessInfo.processInfo.thermalState
    }

    private func startThermalMonitoring() {
        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            thermalState = ProcessInfo.processInfo.thermalState
        }
    }

    private func stopThermalMonitoring() {
        NotificationCenter.default.removeObserver(
            self,
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
    }

    private func startStatsTimer() {
        statsTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            liveStats = LiveSystemStats.current()
        }
    }

    private func stopStatsTimer() {
        statsTimer?.invalidate()
        statsTimer = nil
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 24 {
            let days = hours / 24
            let remainingHours = hours % 24
            return "\(days)d \(remainingHours)h \(minutes)m"
        }
        return "\(hours)h \(minutes)m"
    }
}

struct DeviceInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

struct DeviceInfoData {
    let deviceName: String
    let deviceModel: String
    let systemName: String
    let systemVersion: String
    let identifierForVendor: String
    let processorCount: Int
    let activeProcessorCount: Int
    let physicalMemory: Int64
    let totalDiskSpace: Int64
    let usedDiskSpace: Int64
    let freeDiskSpace: Int64
    let storageUsagePercent: Double
    let isLowPowerModeEnabled: Bool
    let uptime: TimeInterval
    let hostName: String
    let operatingSystemVersionString: String

    init() {
        let device = UIDevice.current
        let processInfo = ProcessInfo.processInfo

        deviceName = device.name
        deviceModel = device.model
        systemName = device.systemName
        systemVersion = device.systemVersion
        identifierForVendor = device.identifierForVendor?.uuidString ?? "Unknown"

        processorCount = processInfo.processorCount
        activeProcessorCount = processInfo.activeProcessorCount
        physicalMemory = Int64(processInfo.physicalMemory)

        // Storage info
        var total: Int64 = 0
        var free: Int64 = 0
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            if let totalSize = attrs[.systemSize] as? Int64 {
                total = totalSize
            }
            if let freeSize = attrs[.systemFreeSize] as? Int64 {
                free = freeSize
            }
        }
        totalDiskSpace = total
        freeDiskSpace = free
        usedDiskSpace = total - free
        storageUsagePercent = total > 0 ? Double(total - free) / Double(total) : 0

        isLowPowerModeEnabled = processInfo.isLowPowerModeEnabled
        uptime = processInfo.systemUptime
        hostName = processInfo.hostName
        operatingSystemVersionString = processInfo.operatingSystemVersionString
    }
}

#Preview {
    NavigationStack {
        DeviceInfoView()
    }
}
