import SwiftUI

struct SettingsRow: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 29, height: 29)
                .background(color, in: RoundedRectangle(cornerRadius: 6))

            Text(title)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    List {
        SettingsRow(title: "Camera", icon: "camera.fill", color: .gray)
    }
}
