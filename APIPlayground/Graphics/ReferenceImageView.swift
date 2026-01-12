import SwiftUI

// MARK: - Reference Image View with Grid Overlay
/// Displays the darkfantasy.png reference image with an optional grid overlay
/// for comparing against the shader output

struct ReferenceImageView: View {
    @Environment(\.dismiss) private var dismiss
    let showGrid: Bool

    // Grid configuration - 4 columns x 6 rows for portrait image
    let gridColumns = 4
    let gridRows = 6

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black.ignoresSafeArea()

                // Reference image - fill entire screen
                if let image = UIImage(named: "darkfantasy") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }

                // Grid overlay
                if showGrid {
                    GridOverlay(columns: gridColumns, rows: gridRows)
                }

                // Back button
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(.ultraThinMaterial.opacity(0.8))
                                .clipShape(Circle())
                        }
                        .padding(.top, 50)
                        .padding(.leading, 16)

                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Grid Overlay View
struct GridOverlay: View {
    let columns: Int
    let rows: Int

    var body: some View {
        GeometryReader { geometry in
            let cellWidth = geometry.size.width / CGFloat(columns)
            let cellHeight = geometry.size.height / CGFloat(rows)

            ZStack {
                // Vertical lines
                ForEach(0...columns, id: \.self) { col in
                    Path { path in
                        let x = CGFloat(col) * cellWidth
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    }
                    .stroke(Color.cyan.opacity(0.7), lineWidth: 1)
                }

                // Horizontal lines
                ForEach(0...rows, id: \.self) { row in
                    Path { path in
                        let y = CGFloat(row) * cellHeight
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(Color.cyan.opacity(0.7), lineWidth: 1)
                }

                // Grid labels (A1, A2, B1, B2, etc.)
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<columns, id: \.self) { col in
                        let label = "\(Character(UnicodeScalar(65 + col)!))\(row + 1)"
                        Text(label)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                            .position(
                                x: CGFloat(col) * cellWidth + cellWidth / 2,
                                y: CGFloat(row) * cellHeight + 20
                            )
                    }
                }
            }
        }
    }
}

#Preview {
    ReferenceImageView(showGrid: true)
}
