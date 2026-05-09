import SwiftUI

struct TechnicalDetailOriginSelectionView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            ModalHeaderView(
                title: "Menşei Seçimi",
                subtitle: "Menşei teknik detayının ekleneceği STOKKODU satırlarını seç.",
                systemImage: "mappin.and.ellipse",
                onClose: {
                    viewModel.technicalDetailDraft = nil
                    dismiss()
                }
            )

            content
            footer
        }
        .padding(22)
        .background(AppTheme.windowBackground)
    }

    private var content: some View {
        CardContainer(padding: 0) {
            VStack(spacing: 0) {
                if let draft = viewModel.technicalDetailDraft {
                    toolbar(draft)
                    Divider().opacity(0.55)
                    Table(draft.products) {
                        TableColumn("Menşei") { product in
                            Toggle("", isOn: Binding(
                                get: { viewModel.technicalDetailDraft?.selectedOriginStockCodes.contains(product.stockCode) ?? false },
                                set: { viewModel.setOriginSelected(stockCode: product.stockCode, isSelected: $0) }
                            ))
                            .labelsHidden()
                        }
                        .width(70)
                        TableColumn("STOKKODU", value: \.stockCode)
                        TableColumn("Ürün Kart ID", value: \.productCardID)
                        TableColumn("Ürün Adı") { product in
                            Text(product.productName)
                                .lineLimit(2)
                        }
                    }
                    .frame(maxHeight: .infinity)

                    if !draft.missingSourceStockCodes.isEmpty {
                        missingSourceText(draft)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 28))
                            .foregroundStyle(.orange)
                        Text("Teknik detay hazırlığı bulunamadı.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)
                }
            }
        }
    }

    private func toolbar(_ draft: TechnicalDetailDraft) -> some View {
        HStack(spacing: 10) {
            StatPillView(title: "\(draft.products.count) eşleşen ürün", systemImage: "checkmark.circle", tint: .green)
            StatPillView(title: "\(draft.selectedOriginStockCodes.count) Menşei seçili", systemImage: "mappin.and.ellipse")
            if !draft.missingSourceStockCodes.isEmpty {
                StatPillView(title: "\(draft.missingSourceStockCodes.count) eksik", systemImage: "exclamationmark.triangle", tint: .orange)
            }
            Spacer()
            Button("Hepsini Seç") {
                viewModel.selectAllOrigins()
            }
            .buttonStyle(MacButtonStyle(kind: .secondary))
            Button("Hepsini Kaldır") {
                viewModel.clearAllOrigins()
            }
            .buttonStyle(MacButtonStyle(kind: .secondary))
        }
        .padding(16)
    }

    private func missingSourceText(_ draft: TechnicalDetailDraft) -> some View {
        Text("Kaynak listede bulunamayan STOKKODU: \(draft.missingSourceStockCodes.prefix(8).joined(separator: ", "))\(draft.missingSourceStockCodes.count > 8 ? " ..." : "")")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.08))
    }

    private var footer: some View {
        CardContainer(padding: 14) {
            HStack {
                if let message = viewModel.status.message {
                    StatusBadge(status: viewModel.status, message: message)
                } else {
                    Label("Seçimleri kontrol et, ardından Excel oluştur.", systemImage: "checkmark.circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Vazgeç") {
                    viewModel.technicalDetailDraft = nil
                    dismiss()
                }
                .buttonStyle(MacButtonStyle(kind: .secondary))
                Button {
                    viewModel.exportTechnicalDetailsTemplate()
                } label: {
                    Label("Excel Oluştur", systemImage: "tablecells")
                }
                .buttonStyle(MacButtonStyle(kind: .primary))
                .disabled(viewModel.technicalDetailDraft?.products.isEmpty ?? true)
                .opacity((viewModel.technicalDetailDraft?.products.isEmpty ?? true) ? 0.48 : 1)
            }
        }
    }
}
