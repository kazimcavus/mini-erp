import SwiftUI

struct PriceUpdateView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPreset: StrikeThroughDiscountPreset = .percentOff20

    var body: some View {
        VStack(spacing: 18) {
            ModalHeaderView(
                title: "Fiyat Güncelleme",
                subtitle: "Ürün listesini, SKU fiyat listesine göre yeni fiyatlarla dışa aktar.",
                systemImage: "tag.fill",
                onClose: { dismiss() }
            )

            CardContainer(padding: 18) {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Liste fiyatı hesabı", systemImage: "percent")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.86))

                    Picker("Liste fiyatı hesabı", selection: $selectedPreset) {
                        ForEach(StrikeThroughDiscountPreset.allCases) { preset in
                            Text(preset.label).tag(preset)
                        }
                    }

                    Text("INDIRIMLIFIYAT m² fiyatı ve varyasyondaki ölçüden hesaplanır; SATISFIYATI seçilen kuralla yazılır.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            footer
        }
        .padding(22)
        .background(AppTheme.windowBackground)
    }

    private var footer: some View {
        CardContainer(padding: 14) {
            HStack {
                if let message = viewModel.status.message {
                    StatusBadge(status: viewModel.status, message: message)
                } else {
                    Label("Fiyat güncelleme hazır", systemImage: "checkmark.circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Vazgeç") {
                    dismiss()
                }
                .buttonStyle(MacButtonStyle(kind: .secondary))

                Button {
                    if viewModel.exportPriceUpdateTemplate(strikeThroughPreset: selectedPreset) {
                        dismiss()
                    }
                } label: {
                    Label("Oluştur", systemImage: "tablecells")
                }
                .buttonStyle(MacButtonStyle(kind: .primary))
            }
        }
    }
}

struct PriceUpdateView_Previews: PreviewProvider {
    static var previews: some View {
        PriceUpdateView()
            .environmentObject(AppViewModel())
            .frame(width: 560, height: 380)
    }
}
