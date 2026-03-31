import SwiftUI

struct SelectionOverlayView: View {
    let onStartSelection: (CGPoint) -> Void
    let onUpdateSelection: (CGRect) -> Void
    let onEndSelection: (CGRect) -> Void
    let onCancel: () -> Void

    @State private var isDragging = false
    @State private var startPoint: CGPoint = .zero
    @State private var currentPoint: CGPoint = .zero

    private var selectionRect: CGRect {
        CGRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )
    }

    var body: some View {
        ZStack {
            // Full screen background that catches all events
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Selection rectangle overlay
            if isDragging {
                // Darken outside selection
                GeometryReader { geometry in
                    // Selection area (clear)
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: selectionRect.width, height: selectionRect.height)
                        .position(x: selectionRect.midX, y: selectionRect.midY)

                    // Border
                    Rectangle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: selectionRect.width, height: selectionRect.height)
                        .position(x: selectionRect.midX, y: selectionRect.midY)

                    // Size label
                    if selectionRect.width > 50 && selectionRect.height > 50 {
                        Text("\(Int(selectionRect.width)) × \(Int(selectionRect.height))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.blue)
                            .cornerRadius(4)
                            .position(x: selectionRect.midX, y: selectionRect.minY - 15)
                    }
                }
            }

            // Instructions
            if !isDragging {
                VStack {
                    Text("拖拽选择截图区域")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)

                    Text("按 Esc 取消")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        startPoint = value.startLocation
                        onStartSelection(value.startLocation)
                    }

                    currentPoint = value.location
                    onUpdateSelection(selectionRect)
                }
                .onEnded { value in
                    isDragging = false
                    currentPoint = value.location

                    let rect = CGRect(
                        x: min(startPoint.x, currentPoint.x),
                        y: min(startPoint.y, currentPoint.y),
                        width: abs(currentPoint.x - startPoint.x),
                        height: abs(currentPoint.y - startPoint.y)
                    )

                    onEndSelection(rect)
                }
        )
        .onTapGesture {
            // Handle tap gesture if needed
        }
    }
}