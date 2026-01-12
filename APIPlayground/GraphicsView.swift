import SwiftUI

// MARK: - Graphics Hub View
/// Navigation hub for graphics framework demos

struct GraphicsDemo: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

struct GraphicsView: View {
    private let demos: [GraphicsDemo] = [
        GraphicsDemo(
            title: "Core Animation",
            subtitle: "Layer animations, particles & 3D transforms",
            icon: "sparkles",
            color: .purple
        ),
        GraphicsDemo(
            title: "Metal",
            subtitle: "GPU compute shaders & real-time effects",
            icon: "cpu",
            color: .blue
        ),
        GraphicsDemo(
            title: "SceneKit",
            subtitle: "3D rendering, physics & lighting",
            icon: "cube.transparent",
            color: .green
        ),
        GraphicsDemo(
            title: "SpriteKit",
            subtitle: "2D graphics, particles & game physics",
            icon: "flame",
            color: .orange
        )
    ]

    var body: some View {
        List {
            Section {
                ForEach(demos) { demo in
                    NavigationLink(value: demo) {
                        HStack(spacing: 16) {
                            Image(systemName: demo.icon)
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(demo.color)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(demo.title)
                                    .font(.headline)
                                Text(demo.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("iOS Graphics Frameworks")
            } footer: {
                Text("Explore Apple's powerful graphics APIs with interactive demos.")
            }
        }
        .navigationTitle("Graphics")
        .navigationDestination(for: GraphicsDemo.self) { demo in
            switch demo.title {
            case "Core Animation":
                CoreAnimationView()
            case "Metal":
                MetalView()
            case "SceneKit":
                SceneKitView()
            case "SpriteKit":
                SpriteKitView()
            default:
                Text("Demo not found")
            }
        }
    }
}

#Preview {
    NavigationStack {
        GraphicsView()
    }
}
