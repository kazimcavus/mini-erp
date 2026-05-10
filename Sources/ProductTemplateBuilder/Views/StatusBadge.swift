import SwiftUI

struct StatusBadge: View {
    let status: AppStatus
    let message: String

    var body: some View {
        Label {
            Text(message)
                .font(.callout)
                .multilineTextAlignment(.leading)
                .lineLimit(8)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: icon)
        }
        .foregroundStyle(color)
    }

    private var icon: String {
        switch status {
        case .idle: "circle"
        case .success: "checkmark.circle"
        case .failure: "xmark.octagon"
        case .warning: "exclamationmark.triangle"
        }
    }

    private var color: Color {
        switch status {
        case .idle: .secondary
        case .success: .green
        case .failure: .red
        case .warning: .orange
        }
    }
}
