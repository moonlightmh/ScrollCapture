import SwiftUI

struct SelectionOverlayView: View {
    let onStartSelection: (CGPoint) -> Void
    let onUpdateSelection: (CGRect) -> Void
    let onEndSelection: (CGRect) -> Void
    let onCancel: () -> Void

    @State private var isDragging = false
    @State private var startPoint: CGPoint = .zero
    @State private var currentPoint: CGPoint = .zero
    @State private var selectionRect: CGRect = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark overlay outside selection
                Color.black.opacity(Constants.UI.overlayAlpha)
                    .ignoresSafeArea()

                // Clear selection area (cutout)
                if isDragging {
                    Rectangle()
                        .frame(width: selectionRect.width, height: selectionRect.height)
                        .position(x: selectionRect.midX, y: selectionRect.midY)
                        .blendMode(.destinationOut)
                }

                // Selection border
                if isDragging {
                    Rectangle()
                        .stroke(Color.white, style: StrokeStyle(lineWidth: Constants.UI.selectionBorderWidth, dash: [5]))
                        .frame(width: selectionRect.width, height: selectionRect.height)
                        .position(x: selectionRect.midX, y: selectionRect.midY)
                }

                // Size label
                if isDragging && selectionRect.width > 0 && selectionRect.height > 0 {
                    VStack {
                        HStack {
                            Text("\(Int(selectionRect.width)) × \(Int(selectionRect.height))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(4)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)
                    .position(x: selectionRect.minX + 60, y: selectionRect.minY + 30)
                }

                // Instructions
                if !isDragging {
                    VStack {
                        Spacer()
                        Text("拖拽选择截图区域")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                        Text("按 Esc 取消")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                }
            }
            .compositingGroup()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            startPoint = value.startLocation
                            onStartSelection(value.startLocation)
                        }
                        currentPoint = value.location
                        let rect = CGRect(
                            x: min(startPoint.x, currentPoint.x),
                            y: min(startPoint.y, currentPoint.y),
                            width: abs(currentPoint.x - startPoint.x),
                            height: abs(currentPoint.y - startPoint.y)
                        )
                        selectionRect = rect
                        onUpdateSelection(rect)
                    }
                    .onEnded { value in
                        isDragging = false
                        let rect = CGRect(
                            x: min(startPoint.x, currentPoint.x),
                            y: min(startPoint.y, currentPoint.y),
                            width: abs(currentPoint.x - startPoint.x),
                            height: abs(currentPoint.y - startPoint.y)
                        )
                        onEndSelection(rect)
                    }
            )
            // Note: Esc key is handled by NSEvent monitor in SelectionOverlayController
        }
    }
}