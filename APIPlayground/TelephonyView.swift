import SwiftUI
import CoreTelephony

struct TelephonyView: View {
    @State private var carrierInfo: [CarrierData] = []
    @State private var isLoading = true

    var body: some View {
        List {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if carrierInfo.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No Cellular Data")
                            .font(.headline)
                        Text("Carrier information is not available on this device or SIM is not inserted.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            } else {
                ForEach(carrierInfo) { carrier in
                    Section(carrier.serviceIdentifier ?? "Carrier") {
                        TelephonyRow(label: "Carrier Name", value: carrier.carrierName)
                        TelephonyRow(label: "Mobile Country Code", value: carrier.mobileCountryCode)
                        TelephonyRow(label: "Mobile Network Code", value: carrier.mobileNetworkCode)
                        TelephonyRow(label: "ISO Country Code", value: carrier.isoCountryCode)
                        TelephonyRow(label: "Allows VoIP", value: carrier.allowsVoIP ? "Yes" : "No")
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("API Note", systemImage: "info.circle")
                        .font(.headline)
                    Text("Core Telephony provides read-only access to carrier information. Some data may be restricted on iOS 16+ for privacy reasons.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Framework") {
                TelephonyRow(label: "Framework", value: "CoreTelephony")
                TelephonyRow(label: "Permissions", value: "None Required")
                TelephonyRow(label: "Min iOS", value: "4.0+")
            }
        }
        .navigationTitle("Telephony")
        .onAppear {
            loadCarrierInfo()
        }
    }

    private func loadCarrierInfo() {
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let networkInfo = CTTelephonyNetworkInfo()

            if let carriers = networkInfo.serviceSubscriberCellularProviders {
                carrierInfo = carriers.compactMap { (serviceId, carrier) in
                    guard carrier.carrierName != nil else { return nil }
                    return CarrierData(
                        serviceIdentifier: serviceId,
                        carrierName: carrier.carrierName ?? "Unknown",
                        mobileCountryCode: carrier.mobileCountryCode ?? "N/A",
                        mobileNetworkCode: carrier.mobileNetworkCode ?? "N/A",
                        isoCountryCode: carrier.isoCountryCode?.uppercased() ?? "N/A",
                        allowsVoIP: carrier.allowsVOIP
                    )
                }
            }

            isLoading = false
        }
    }
}

struct CarrierData: Identifiable {
    let id = UUID()
    let serviceIdentifier: String?
    let carrierName: String
    let mobileCountryCode: String
    let mobileNetworkCode: String
    let isoCountryCode: String
    let allowsVoIP: Bool
}

struct TelephonyRow: View {
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

#Preview {
    NavigationStack {
        TelephonyView()
    }
}
