import SwiftUI

struct FeatureDetailView: View {
    let feature: Feature

    var body: some View {
        VStack {
            Image(systemName: feature.icon)
                .font(.system(size: 60))
                .foregroundStyle(feature.color)
                .padding(.bottom, 8)

            Text(feature.title)
                .font(.title2)
                .fontWeight(.semibold)

            Text("Coming soon...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(feature.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FeatureDetailView(feature: Feature(title: "Camera", icon: "camera.fill", color: .gray))
    }
}
