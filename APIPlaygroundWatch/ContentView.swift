import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    WatchHealthView()
                } label: {
                    Label("Health", systemImage: "heart.fill")
                        .foregroundStyle(.pink)
                }

                NavigationLink {
                    WatchHapticsView()
                } label: {
                    Label("Haptics", systemImage: "waveform")
                        .foregroundStyle(.orange)
                }

                NavigationLink {
                    WatchCloudKitView()
                } label: {
                    Label("CloudKit", systemImage: "icloud.fill")
                        .foregroundStyle(.blue)
                }

                NavigationLink {
                    WatchConnectivityView()
                } label: {
                    Label("iPhone Sync", systemImage: "iphone.and.arrow.forward")
                        .foregroundStyle(.green)
                }

                NavigationLink {
                    WatchMotionView()
                } label: {
                    Label("Motion", systemImage: "gyroscope")
                        .foregroundStyle(.purple)
                }

                NavigationLink {
                    WatchInfoView()
                } label: {
                    Label("Device Info", systemImage: "applewatch")
                        .foregroundStyle(.gray)
                }
            }
            .navigationTitle("API Playground")
        }
    }
}

#Preview {
    ContentView()
}
