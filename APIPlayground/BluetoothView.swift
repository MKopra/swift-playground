import SwiftUI
import CoreBluetooth

// MARK: - BluetoothView
/// A comprehensive Bluetooth Low Energy scanner and connection interface.
///
/// Features:
/// - Real-time device discovery with radar visualization
/// - Signal strength monitoring (RSSI)
/// - Device connection and service discovery
/// - Characteristic reading and writing
/// - Device filtering by name or service
/// - Connection state management
/// - Advertising data parsing
///
/// APIs Demonstrated:
/// - CBCentralManager for BLE scanning
/// - CBPeripheral for device connection
/// - CBService and CBCharacteristic for data access
/// - RSSI monitoring for signal strength
struct BluetoothView: View {
    @StateObject private var bluetooth = BluetoothManager()
    @State private var radarAngle: Double = 0
    @State private var selectedDevice: DiscoveredDevice?
    @State private var showingDeviceDetail = false
    @State private var filterText = ""

    var filteredDevices: [DiscoveredDevice] {
        if filterText.isEmpty {
            return bluetooth.devices
        }
        return bluetooth.devices.filter {
            $0.name.localizedCaseInsensitiveContains(filterText)
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                // Status bar
                BluetoothStatusBar(manager: bluetooth)

                // Radar visualization
                ZStack {
                    // Radar circles
                    ForEach(1..<5, id: \.self) { ring in
                        Circle()
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                            .frame(width: CGFloat(ring) * 60, height: CGFloat(ring) * 60)
                    }

                    // Radar sweep
                    if bluetooth.isScanning {
                        RadarSweep(angle: radarAngle)
                            .frame(width: 240, height: 240)
                    }

                    // Device blips
                    ForEach(filteredDevices) { device in
                        DeviceBlip(
                            device: device,
                            radarSize: 240,
                            isSelected: selectedDevice?.id == device.id,
                            onTap: {
                                selectedDevice = device
                                showingDeviceDetail = true
                            }
                        )
                    }

                    // Center dot
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                }
                .frame(width: 240, height: 240)
                .onAppear {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        radarAngle = 360
                    }
                }

                // Filter bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray)
                    TextField("Filter devices...", text: $filterText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Scan control
                Button(action: {
                    if bluetooth.isScanning {
                        bluetooth.stopScanning()
                    } else {
                        bluetooth.startScanning()
                    }
                }) {
                    HStack {
                        Image(systemName: bluetooth.isScanning ? "stop.fill" : "antenna.radiowaves.left.and.right")
                        Text(bluetooth.isScanning ? "Stop Scan" : "Start Scan")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(bluetooth.isScanning ? Color.red : Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                // Device list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredDevices) { device in
                            DeviceRow(
                                device: device,
                                isConnected: bluetooth.connectedPeripheral?.identifier.uuidString == device.peripheralId,
                                onConnect: {
                                    bluetooth.connect(to: device)
                                },
                                onDisconnect: {
                                    bluetooth.disconnect()
                                },
                                onTap: {
                                    selectedDevice = device
                                    showingDeviceDetail = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                // Stats footer
                HStack {
                    Label("\(filteredDevices.count) devices", systemImage: "antenna.radiowaves.left.and.right")
                    Spacer()
                    if let connected = bluetooth.connectedPeripheral {
                        Label("Connected", systemImage: "link")
                            .foregroundStyle(.green)
                    }
                }
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .padding(.top, 8)
        }
        .navigationTitle("Bluetooth")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showingDeviceDetail) {
            if let device = selectedDevice {
                DeviceDetailView(device: device, manager: bluetooth)
            }
        }
        .onDisappear {
            bluetooth.stopScanning()
        }
    }
}

// MARK: - BluetoothStatusBar
/// Displays Bluetooth status and power state.
struct BluetoothStatusBar: View {
    @ObservedObject var manager: BluetoothManager

    var body: some View {
        HStack {
            Circle()
                .fill(manager.stateDescription == "Powered On" ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            Text(manager.stateDescription)
                .font(.caption)
                .foregroundStyle(.gray)

            Spacer()

            if manager.isScanning {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Scanning...")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - RadarSweep
/// Animated radar sweep effect.
struct RadarSweep: View {
    let angle: Double

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2

            Path { path in
                path.move(to: center)
                path.addArc(center: center, radius: radius, startAngle: .degrees(angle - 30), endAngle: .degrees(angle), clockwise: false)
                path.closeSubpath()
            }
            .fill(
                AngularGradient(
                    colors: [.green.opacity(0), .green.opacity(0.5)],
                    center: .center,
                    startAngle: .degrees(angle - 30),
                    endAngle: .degrees(angle)
                )
            )
        }
    }
}

// MARK: - DeviceBlip
/// Blip on radar representing a discovered device.
struct DeviceBlip: View {
    let device: DiscoveredDevice
    let radarSize: CGFloat
    let isSelected: Bool
    let onTap: () -> Void

    @State private var pulse = false

    var body: some View {
        let distance = signalToDistance(rssi: device.rssi)
        let angle = device.angle

        ZStack {
            // Pulse ring
            Circle()
                .stroke(Color.green, lineWidth: 1)
                .frame(width: 16, height: 16)
                .scaleEffect(pulse ? 2 : 1)
                .opacity(pulse ? 0 : 0.5)

            // Blip dot
            Circle()
                .fill(isSelected ? Color.yellow : Color.green)
                .frame(width: 10, height: 10)
                .shadow(color: .green, radius: isSelected ? 8 : 4)
        }
        .offset(
            x: cos(angle) * distance * (radarSize / 2 - 20),
            y: sin(angle) * distance * (radarSize / 2 - 20)
        )
        .onTapGesture(perform: onTap)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }

    private func signalToDistance(rssi: Int) -> CGFloat {
        let normalized = CGFloat(min(0, max(-100, rssi)) + 100) / 100
        return 1.0 - (normalized * 0.9)
    }
}

// MARK: - DeviceRow
/// List row for a discovered device.
struct DeviceRow: View {
    let device: DiscoveredDevice
    let isConnected: Bool
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Signal strength
            SignalBars(rssi: device.rssi)
                .frame(width: 24, height: 20)

            // Device info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(device.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)

                    if isConnected {
                        Image(systemName: "link.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }

                HStack(spacing: 8) {
                    Text(device.shortId)
                        .font(.caption2)
                        .foregroundStyle(.gray)

                    if device.isConnectable {
                        Text("Connectable")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            // RSSI
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(device.rssi) dB")
                    .font(.caption)
                    .foregroundStyle(rssiColor(device.rssi))
                    .monospacedDigit()

                Text(device.lastSeenText)
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }

            // Connect/Disconnect button
            if device.isConnectable {
                Button(action: isConnected ? onDisconnect : onConnect) {
                    Image(systemName: isConnected ? "xmark.circle.fill" : "link.circle")
                        .font(.title2)
                        .foregroundStyle(isConnected ? .red : .blue)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(isConnected ? 0.1 : 0.05), in: RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private func rssiColor(_ rssi: Int) -> Color {
        if rssi > -50 { return .green }
        if rssi > -70 { return .yellow }
        return .red
    }
}

// MARK: - SignalBars
/// Signal strength bar indicator.
struct SignalBars: View {
    let rssi: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { bar in
                RoundedRectangle(cornerRadius: 1)
                    .fill(barActive(bar) ? barColor : Color.gray.opacity(0.3))
                    .frame(width: 4, height: CGFloat(bar + 1) * 4 + 4)
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private var barColor: Color {
        if rssi > -50 { return .green }
        if rssi > -70 { return .yellow }
        return .red
    }

    private func barActive(_ bar: Int) -> Bool {
        let level = (rssi + 100) / 25
        return bar < level
    }
}

// MARK: - DeviceDetailView
/// Detailed view for a selected device showing services and characteristics.
struct DeviceDetailView: View {
    let device: DiscoveredDevice
    @ObservedObject var manager: BluetoothManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Device info section
                Section("Device Information") {
                    DetailRow(label: "Name", value: device.name)
                    DetailRow(label: "UUID", value: device.peripheralId)
                    DetailRow(label: "RSSI", value: "\(device.rssi) dB")
                    DetailRow(label: "Connectable", value: device.isConnectable ? "Yes" : "No")
                }

                // Advertising data section
                Section("Advertising Data") {
                    if let manufacturerData = device.manufacturerData {
                        DetailRow(label: "Manufacturer", value: manufacturerData)
                    }
                    if !device.serviceUUIDs.isEmpty {
                        ForEach(device.serviceUUIDs, id: \.self) { uuid in
                            DetailRow(label: "Service", value: uuid)
                        }
                    }
                    if device.txPower != nil {
                        DetailRow(label: "TX Power", value: "\(device.txPower!) dB")
                    }
                }

                // Services section (when connected)
                if manager.connectedPeripheral?.identifier.uuidString == device.peripheralId {
                    Section("Discovered Services") {
                        if manager.discoveredServices.isEmpty {
                            HStack {
                                ProgressView()
                                Text("Discovering services...")
                                    .foregroundStyle(.gray)
                            }
                        } else {
                            ForEach(manager.discoveredServices, id: \.uuid) { service in
                                ServiceRow(service: service, manager: manager)
                            }
                        }
                    }
                }

                // Connection section
                Section {
                    if manager.connectedPeripheral?.identifier.uuidString == device.peripheralId {
                        Button(role: .destructive, action: { manager.disconnect() }) {
                            Label("Disconnect", systemImage: "xmark.circle")
                        }
                    } else if device.isConnectable {
                        Button(action: { manager.connect(to: device) }) {
                            Label("Connect", systemImage: "link.circle")
                        }
                    }
                }
            }
            .navigationTitle(device.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - DetailRow
/// Simple key-value row for device details.
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

// MARK: - ServiceRow
/// Expandable row showing service and its characteristics.
struct ServiceRow: View {
    let service: CBService
    @ObservedObject var manager: BluetoothManager
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if let characteristics = service.characteristics {
                ForEach(characteristics, id: \.uuid) { characteristic in
                    CharacteristicRow(characteristic: characteristic, manager: manager)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(serviceName(for: service.uuid))
                    .fontWeight(.medium)
                Text(service.uuid.uuidString)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                manager.discoverCharacteristics(for: service)
            }
        }
    }

    private func serviceName(for uuid: CBUUID) -> String {
        // Common service names
        let knownServices: [String: String] = [
            "180A": "Device Information",
            "180F": "Battery Service",
            "1800": "Generic Access",
            "1801": "Generic Attribute",
            "180D": "Heart Rate",
            "1805": "Current Time",
            "1802": "Immediate Alert"
        ]
        return knownServices[uuid.uuidString] ?? "Unknown Service"
    }
}

// MARK: - CharacteristicRow
/// Row displaying a characteristic with read/write actions.
struct CharacteristicRow: View {
    let characteristic: CBCharacteristic
    @ObservedObject var manager: BluetoothManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(characteristicName(for: characteristic.uuid))
                    .font(.subheadline)

                Spacer()

                // Properties badges
                HStack(spacing: 4) {
                    if characteristic.properties.contains(.read) {
                        PropertyBadge(text: "R", color: .blue)
                    }
                    if characteristic.properties.contains(.write) {
                        PropertyBadge(text: "W", color: .green)
                    }
                    if characteristic.properties.contains(.notify) {
                        PropertyBadge(text: "N", color: .orange)
                    }
                }
            }

            Text(characteristic.uuid.uuidString)
                .font(.caption2)
                .foregroundStyle(.gray)

            // Value if available
            if let value = characteristic.value, !value.isEmpty {
                Text("Value: \(value.map { String(format: "%02X", $0) }.joined(separator: " "))")
                    .font(.caption)
                    .foregroundStyle(.cyan)
            }

            // Read button
            if characteristic.properties.contains(.read) {
                Button(action: { manager.readValue(for: characteristic) }) {
                    Label("Read", systemImage: "arrow.down.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.leading, 16)
    }

    private func characteristicName(for uuid: CBUUID) -> String {
        let knownCharacteristics: [String: String] = [
            "2A29": "Manufacturer Name",
            "2A24": "Model Number",
            "2A25": "Serial Number",
            "2A27": "Hardware Revision",
            "2A26": "Firmware Revision",
            "2A28": "Software Revision",
            "2A19": "Battery Level",
            "2A00": "Device Name"
        ]
        return knownCharacteristics[uuid.uuidString] ?? "Characteristic"
    }
}

// MARK: - PropertyBadge
/// Small badge showing characteristic property.
struct PropertyBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .frame(width: 18, height: 18)
            .background(color, in: Circle())
    }
}

// MARK: - DiscoveredDevice
/// Represents a discovered Bluetooth device.
struct DiscoveredDevice: Identifiable {
    let id = UUID()
    let peripheralId: String
    let name: String
    let rssi: Int
    let angle: Double
    let isConnectable: Bool
    let manufacturerData: String?
    let serviceUUIDs: [String]
    let txPower: Int?
    let lastSeen: Date

    var shortId: String {
        String(peripheralId.prefix(8))
    }

    var lastSeenText: String {
        let interval = Date().timeIntervalSince(lastSeen)
        if interval < 5 { return "Just now" }
        if interval < 60 { return "\(Int(interval))s ago" }
        return "\(Int(interval / 60))m ago"
    }
}

// MARK: - BluetoothManager
/// Manages Bluetooth scanning, connection, and service discovery.
///
/// This class provides:
/// - Device scanning with configurable filters
/// - Connection management
/// - Service and characteristic discovery
/// - RSSI monitoring
/// - Advertising data parsing
class BluetoothManager: NSObject, ObservableObject {
    // MARK: Published Properties
    @Published var devices: [DiscoveredDevice] = []
    @Published var isScanning = false
    @Published var stateDescription = "Unknown"
    @Published var connectedPeripheral: CBPeripheral?
    @Published var discoveredServices: [CBService] = []
    @Published var connectionState = "Disconnected"

    // MARK: Private Properties
    private var centralManager: CBCentralManager!
    private var seenPeripherals: [String: (peripheral: CBPeripheral, device: DiscoveredDevice)] = [:]

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: Public Methods

    /// Starts scanning for Bluetooth devices.
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        devices.removeAll()
        seenPeripherals.removeAll()
        isScanning = true

        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])

        // Stop after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.stopScanning()
        }
    }

    /// Stops scanning for devices.
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }

    /// Connects to a discovered device.
    func connect(to device: DiscoveredDevice) {
        guard let (peripheral, _) = seenPeripherals[device.peripheralId] else { return }
        connectionState = "Connecting..."
        centralManager.connect(peripheral, options: nil)
    }

    /// Disconnects from the current device.
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }

    /// Discovers characteristics for a service.
    func discoverCharacteristics(for service: CBService) {
        connectedPeripheral?.discoverCharacteristics(nil, for: service)
    }

    /// Reads value for a characteristic.
    func readValue(for characteristic: CBCharacteristic) {
        connectedPeripheral?.readValue(for: characteristic)
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            switch central.state {
            case .poweredOn: self.stateDescription = "Powered On"
            case .poweredOff: self.stateDescription = "Powered Off"
            case .resetting: self.stateDescription = "Resetting"
            case .unauthorized: self.stateDescription = "Unauthorized"
            case .unsupported: self.stateDescription = "Unsupported"
            case .unknown: self.stateDescription = "Unknown"
            @unknown default: self.stateDescription = "Unknown"
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                       advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let uuid = peripheral.identifier.uuidString
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown"
        let isConnectable = advertisementData[CBAdvertisementDataIsConnectable] as? Bool ?? false

        // Parse manufacturer data
        var manufacturerData: String?
        if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            manufacturerData = data.map { String(format: "%02X", $0) }.joined(separator: " ")
        }

        // Parse service UUIDs
        var serviceUUIDs: [String] = []
        if let uuids = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            serviceUUIDs = uuids.map { $0.uuidString }
        }

        // Parse TX power
        let txPower = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Int

        let device = DiscoveredDevice(
            peripheralId: uuid,
            name: name,
            rssi: RSSI.intValue,
            angle: seenPeripherals[uuid]?.device.angle ?? Double.random(in: 0..<(2 * .pi)),
            isConnectable: isConnectable,
            manufacturerData: manufacturerData,
            serviceUUIDs: serviceUUIDs,
            txPower: txPower,
            lastSeen: Date()
        )

        seenPeripherals[uuid] = (peripheral, device)

        DispatchQueue.main.async {
            if let index = self.devices.firstIndex(where: { $0.peripheralId == uuid }) {
                self.devices[index] = device
            } else {
                self.devices.append(device)
            }
            self.devices.sort { $0.rssi > $1.rssi }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.connectedPeripheral = peripheral
            self.connectionState = "Connected"
            self.discoveredServices = []
            peripheral.delegate = self
            peripheral.discoverServices(nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.connectedPeripheral = nil
            self.connectionState = "Disconnected"
            self.discoveredServices = []
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.connectionState = "Connection Failed"
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        DispatchQueue.main.async {
            self.discoveredServices = services
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        DispatchQueue.main.async {
            // Force refresh
            if let index = self.discoveredServices.firstIndex(where: { $0.uuid == service.uuid }) {
                self.discoveredServices[index] = service
            }
            self.objectWillChange.send()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}

#Preview {
    NavigationStack {
        BluetoothView()
    }
}
