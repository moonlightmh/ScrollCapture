import SwiftUI

struct ToastView: View {
    let message: String
    let action: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white)

            if action != nil {
                Button("打开") {
                    action?()
                }
                .font(.system(size: 12))
                .foregroundColor(.white)
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.8))
        .cornerRadius(8)
        .onTapGesture {
            if let action = action {
                action()
            }
        }
    }
}