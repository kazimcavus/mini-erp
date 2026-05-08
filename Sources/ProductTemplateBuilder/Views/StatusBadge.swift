import SwiftUI

struct StatusBadge: View {
    let status: AppStatus
    let message: String

    var body: some View {
        Label(message, systemImage: icon)
            .font(.callout)
            .foregroundStyle(color)
            .lineLimit(2)
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
