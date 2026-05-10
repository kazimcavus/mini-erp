import SwiftUI

struct AddProductView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            ModalHeaderView(
                title: "Ürün Kartı",
                subtitle: "SKU satırlarını, kategori yolunu ve Bilgiler.xlsx kaynağını tek akışta hazırla.",
                systemImage: "plus.circle.fill",
                onClose: { dismiss() }
            )

            HStack(alignment: .top, spacing: 18) {
                inputTable
                settingsPanel
            }
            .frame(maxHeight: .infinity, alignment: .top)

            footer
        }
        .padding(22)
        .background(AppTheme.windowBackground)
    }

    private var inputTable: some View {
        CardContainer(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("SKU satırları", systemImage: "square.grid.2x2")
                Text("Renk sütunu çıktı tonu olarak yazılır. Bilgiler’deki örnek renk otomatik bulunup bu değerle değiştirilir.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text("Excel’de iki yan yana sütun (stok kodu ve ürün adı) seçip kopyalayın; ilk stok kutusuna yapıştırınca tüm satırlar dolar.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                ScrollView {
                    VStack(alignment: .leading, spacing: 9) {
                        columnHeaderRow
                        ForEach($viewModel.draftRows) { $row in
                            let rowId = $row.wrappedValue.id
                            draftGridRow(binding: $row, isFirstStockRow: rowId == viewModel.draftRows.first?.id)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.visible)

                Button {
                    viewModel.addDraftRow()
                } label: {
                    Label("SKU satırı ekle", systemImage: "plus")
                }
                .buttonStyle(MacButtonStyle(kind: .secondary))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var columnHeaderRow: some View {
        HStack(spacing: 10) {
            header("Stok kodu")
                .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
            header("Ürün adı")
                .frame(minWidth: 140, maxWidth: .infinity, alignment: .leading)
            header("Renk (çıktı)")
                .frame(minWidth: 88, maxWidth: .infinity, alignment: .leading)
            Text("")
                .frame(width: 30)
        }
    }

    @ViewBuilder
    private func draftGridRow(binding: Binding<ProductDraftRow>, isFirstStockRow: Bool) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Group {
                if isFirstStockRow {
                    StockCodePasteTextField(
                        text: binding.stockCode,
                        onTwoColumnPaste: { pairs in viewModel.applyTwoColumnSkuNamePaste(rows: pairs) }
                    )
                    .frame(height: 38)
                    .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
                } else {
                    TextField("", text: binding.stockCode)
                        .textFieldStyle(RoundedInputStyle())
                        .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
                }
            }
            TextField("", text: binding.productName)
                .textFieldStyle(RoundedInputStyle())
                .frame(minWidth: 140, maxWidth: .infinity, alignment: .leading)
            TextField("", text: binding.color)
                .textFieldStyle(RoundedInputStyle())
                .frame(minWidth: 88, maxWidth: .infinity, alignment: .leading)
            Button {
                viewModel.removeDraftRow(binding.wrappedValue)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red.opacity(0.8))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .help("Satırı kaldır")
        }
    }

    private var settingsPanel: some View {
        CardContainer(padding: 18) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sectionTitle("Aktarım Bilgileri", systemImage: "slider.horizontal.3")

                    Picker("Önyazı Tipi", selection: $viewModel.selectedIntroType) {
                        ForEach(IntroType.allCases) { type in
                            Text(viewModel.introLabels[type] ?? type.rawValue).tag(type)
                        }
                    }

                    Picker("Liste fiyatı hesabı", selection: $viewModel.selectedStrikeThroughPreset) {
                        ForEach(StrikeThroughDiscountPreset.allCases) { preset in
                            Text(preset.label).tag(preset)
                        }
                    }
                    Text("Bilgiler’deki indirimli fiyat yazılır; liste fiyatı seçilen kurala göre hesaplanır.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider().opacity(0.6)

                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("Kategori Ağacı", systemImage: "folder")
                        CategoryTreePickerView(
                            nodes: EmbeddedCatalog.categoryTree,
                            selectedID: viewModel.selectedCatalogID,
                            onSelect: viewModel.selectCatalog
                        )
                        .frame(height: 250)
                    }

                    selectedCategorySummary
                    variationFilePicker
                }
                .padding(1)
            }
        }
        .frame(width: 430, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private var selectedCategorySummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kategori yolu (breadcrumb)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(viewModel.selectedBreadcrumb.isEmpty ? "-" : viewModel.selectedBreadcrumb)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(2)
            Text("Excel’daki kategori sütunu (KATEGORILER)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            Text(viewModel.selectedCategory.isEmpty ? "-" : viewModel.selectedCategory)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(14)
        .background(Color.black.opacity(0.025), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var variationFilePicker: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.badge.gearshape")
                .foregroundStyle(AppTheme.accent)
                .frame(width: 32, height: 32)
                .background(AppTheme.accentSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text("Bilgiler.xlsx")
                    .font(.system(size: 13, weight: .semibold))
                Text(viewModel.fileSettings.variationURL?.lastPathComponent ?? "Dosya seçilmedi")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Button {
                viewModel.chooseVariationFile()
            } label: {
                Label("Seç", systemImage: "folder")
            }
            .buttonStyle(MacButtonStyle(kind: .secondary))
            .help("Bilgiler.xlsx seç")
        }
        .padding(14)
        .background(Color.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }

    private var footer: some View {
        CardContainer(padding: 14) {
            HStack {
                if let message = viewModel.status.message {
                    StatusBadge(status: viewModel.status, message: message)
                } else {
                    Label("Ürün kartı eklemeye hazır", systemImage: "checkmark.circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Vazgeç") {
                    dismiss()
                }
                .buttonStyle(MacButtonStyle(kind: .secondary))

                Button {
                    viewModel.addDraftsToList()
                } label: {
                    Label("Listeye Ekle", systemImage: "plus")
                }
                .buttonStyle(MacButtonStyle(kind: .primary))
            }
        }
    }

    private func sectionTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.primary.opacity(0.86))
    }

    private func header(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
    }
}
