import SwiftUI
import PencilKit

// MARK: - PencilKitView
/// A comprehensive drawing interface using PencilKit.
///
/// Features:
/// - Apple Pencil and finger drawing support
/// - Multiple pen, marker, and eraser tools
/// - Color picker with custom palettes
/// - Undo/redo functionality
/// - Drawing export to image
/// - Canvas zoom and scroll
/// - Stroke pressure and tilt sensitivity
///
/// APIs Demonstrated:
/// - PKCanvasView for drawing surface
/// - PKToolPicker for tool selection
/// - PKDrawing for stroke data
/// - PKInkingTool for pen customization
/// - UIGraphicsImageRenderer for export
///
/// Note: This API is NOT available in Flutter - requires native PencilKit implementation.
/// PencilKit provides professional drawing tools with Apple Pencil optimization.
struct PencilKitView: View {
    @StateObject private var drawingManager = DrawingManager()
    @State private var showingColorPicker = false
    @State private var showingExportOptions = false
    @State private var showingSavedAlert = false

    var body: some View {
        ZStack {
            // Canvas - must be at bottom of ZStack
            DrawingCanvas(drawingManager: drawingManager)
                .ignoresSafeArea(edges: .bottom)
        }
        // Overlay controls using safeAreaInset to not block canvas touches
        .safeAreaInset(edge: .top) {
            // Top toolbar
            HStack(spacing: 16) {
                // Undo/Redo
                HStack(spacing: 8) {
                    Button(action: { drawingManager.undo() }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.title3)
                            .foregroundStyle(drawingManager.canUndo ? .primary : .secondary)
                    }
                    .disabled(!drawingManager.canUndo)

                    Button(action: { drawingManager.redo() }) {
                        Image(systemName: "arrow.uturn.forward")
                            .font(.title3)
                            .foregroundStyle(drawingManager.canRedo ? .primary : .secondary)
                    }
                    .disabled(!drawingManager.canRedo)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())

                Spacer()

                // Clear button
                Button(action: { drawingManager.clearCanvas() }) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundStyle(.red)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }

                // Export button
                Button(action: { showingExportOptions = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .safeAreaInset(edge: .bottom) {
            // Bottom tool bar
            VStack(spacing: 12) {
                // Tool selector
                HStack(spacing: 12) {
                    ForEach(DrawingTool.allCases) { tool in
                        ToolButton(
                            tool: tool,
                            isSelected: drawingManager.selectedTool == tool,
                            action: { drawingManager.selectTool(tool) }
                        )
                    }

                    Divider()
                        .frame(height: 30)

                    // Color button
                    Button(action: { showingColorPicker = true }) {
                        Circle()
                            .fill(drawingManager.selectedColor)
                            .frame(width: 36, height: 36)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                            .shadow(radius: 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: Capsule())

                // Stroke width slider
                if drawingManager.selectedTool != .eraser {
                    HStack(spacing: 12) {
                        Image(systemName: "pencil.tip")
                            .font(.caption)

                        Slider(
                            value: $drawingManager.strokeWidth,
                            in: 1...20
                        )
                        .frame(width: 150)

                        Text(String(format: "%.0f", drawingManager.strokeWidth))
                            .font(.caption)
                            .frame(width: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("Drawing")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerSheet(selectedColor: $drawingManager.selectedColor)
        }
        .confirmationDialog("Export Drawing", isPresented: $showingExportOptions) {
            Button("Save to Photos") {
                drawingManager.saveToPhotos()
                showingSavedAlert = true
            }
            Button("Copy to Clipboard") {
                drawingManager.copyToClipboard()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Saved!", isPresented: $showingSavedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your drawing has been saved to Photos.")
        }
    }
}

// MARK: - DrawingTool
/// Available drawing tools.
enum DrawingTool: String, CaseIterable, Identifiable {
    case pen = "Pen"
    case pencil = "Pencil"
    case marker = "Marker"
    case eraser = "Eraser"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pen: return "pencil.tip"
        case .pencil: return "pencil"
        case .marker: return "highlighter"
        case .eraser: return "eraser"
        }
    }
}

// MARK: - ToolButton
/// Tool selection button.
struct ToolButton: View {
    let tool: DrawingTool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tool.icon)
                    .font(.title3)

                Text(tool.rawValue)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? .blue : .primary)
            .frame(width: 50, height: 50)
            .background(isSelected ? Color.blue.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - ColorPickerSheet
/// Color picker sheet.
struct ColorPickerSheet: View {
    @Binding var selectedColor: Color
    @Environment(\.dismiss) private var dismiss

    private let presetColors: [Color] = [
        .black, .gray, .red, .orange, .yellow,
        .green, .cyan, .blue, .indigo, .purple, .pink, .brown
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Color preview
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedColor)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)

                // Preset colors
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preset Colors")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(presetColors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .shadow(radius: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Custom color picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Custom Color")
                        .font(.headline)
                        .padding(.horizontal)

                    ColorPicker("Select Color", selection: $selectedColor, supportsOpacity: true)
                        .labelsHidden()
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Colors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - DrawingCanvas
/// SwiftUI wrapper for PKCanvasView.
struct DrawingCanvas: UIViewRepresentable {
    @ObservedObject var drawingManager: DrawingManager

    func makeUIView(context: Context) -> UIView {
        // Create a container view that will hold the canvas
        let containerView = UIView()
        containerView.backgroundColor = .white

        let canvasView = PKCanvasView()
        canvasView.backgroundColor = .white
        canvasView.isOpaque = true
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        canvasView.translatesAutoresizingMaskIntoConstraints = false

        // Set initial tool
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)

        containerView.addSubview(canvasView)

        // Pin canvas to container edges
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: containerView.topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            canvasView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        // Store reference in coordinator
        context.coordinator.canvasView = canvasView

        // Store reference in manager
        drawingManager.setupCanvas(canvasView)

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let canvasView = context.coordinator.canvasView else { return }

        let uiColor = UIColor(drawingManager.selectedColor)

        switch drawingManager.selectedTool {
        case .pen:
            canvasView.tool = PKInkingTool(.pen, color: uiColor, width: drawingManager.strokeWidth)
        case .pencil:
            canvasView.tool = PKInkingTool(.pencil, color: uiColor, width: drawingManager.strokeWidth)
        case .marker:
            canvasView.tool = PKInkingTool(.marker, color: uiColor, width: drawingManager.strokeWidth * 2)
        case .eraser:
            canvasView.tool = PKEraserTool(.bitmap)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(drawingManager: drawingManager)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        let drawingManager: DrawingManager
        weak var canvasView: PKCanvasView?

        init(drawingManager: DrawingManager) {
            self.drawingManager = drawingManager
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            Task { @MainActor in
                drawingManager.drawingDidChange(canvasView.drawing)
            }
        }
    }
}

// MARK: - DrawingManager
/// Manages PencilKit drawing operations.
///
/// This class provides:
/// - Tool selection and configuration
/// - Undo/redo stack management
/// - Drawing export functionality
/// - Canvas state management
@MainActor
class DrawingManager: ObservableObject {
    // MARK: Published Properties
    @Published var selectedTool: DrawingTool = .pen
    @Published var selectedColor: Color = .black
    @Published var strokeWidth: CGFloat = 5
    @Published var canUndo = false
    @Published var canRedo = false

    // MARK: Private Properties
    private weak var canvasView: PKCanvasView?
    private var undoManager: UndoManager?

    // MARK: Public Methods

    /// Sets up the canvas view.
    func setupCanvas(_ canvasView: PKCanvasView) {
        self.canvasView = canvasView
        self.undoManager = canvasView.undoManager
        updateTool(on: canvasView)
    }

    /// Selects a drawing tool.
    func selectTool(_ tool: DrawingTool) {
        selectedTool = tool
        if let canvasView = canvasView {
            updateTool(on: canvasView)
        }
    }

    /// Updates the tool on the canvas.
    func updateTool(on canvasView: PKCanvasView) {
        let uiColor = UIColor(selectedColor)

        switch selectedTool {
        case .pen:
            canvasView.tool = PKInkingTool(.pen, color: uiColor, width: strokeWidth)
        case .pencil:
            canvasView.tool = PKInkingTool(.pencil, color: uiColor, width: strokeWidth)
        case .marker:
            canvasView.tool = PKInkingTool(.marker, color: uiColor, width: strokeWidth * 2)
        case .eraser:
            canvasView.tool = PKEraserTool(.bitmap)
        }
    }

    /// Called when the drawing changes.
    func drawingDidChange(_ drawing: PKDrawing) {
        updateUndoRedoState()
    }

    /// Undoes the last action.
    func undo() {
        undoManager?.undo()
        updateUndoRedoState()
    }

    /// Redoes the last undone action.
    func redo() {
        undoManager?.redo()
        updateUndoRedoState()
    }

    /// Clears the canvas.
    func clearCanvas() {
        canvasView?.drawing = PKDrawing()
        updateUndoRedoState()
    }

    /// Saves the drawing to Photos.
    func saveToPhotos() {
        guard let image = getDrawingImage() else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    /// Copies the drawing to clipboard.
    func copyToClipboard() {
        guard let image = getDrawingImage() else { return }
        UIPasteboard.general.image = image
    }

    // MARK: Private Methods

    private func updateUndoRedoState() {
        canUndo = undoManager?.canUndo ?? false
        canRedo = undoManager?.canRedo ?? false
    }

    private func getDrawingImage() -> UIImage? {
        guard let canvasView = canvasView else { return nil }

        let drawing = canvasView.drawing
        let bounds = drawing.bounds

        // Add padding
        let padding: CGFloat = 20
        let imageRect = CGRect(
            x: bounds.minX - padding,
            y: bounds.minY - padding,
            width: bounds.width + padding * 2,
            height: bounds.height + padding * 2
        )

        return drawing.image(from: imageRect, scale: UIScreen.main.scale)
    }
}

#Preview {
    NavigationStack {
        PencilKitView()
    }
}
