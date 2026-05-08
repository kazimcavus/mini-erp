import SwiftUI

struct FileSettingsView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Başlangıç Barkodu")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("", text: $viewModel.startingBarcode)
                .textFieldStyle(.plain)
                .font(.system(.title3, design: .monospaced).weight(.medium))
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor).opacity(0.7))
                }
            Text("Boş bırakırsan barkod kolonu boş kalır.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }
}
