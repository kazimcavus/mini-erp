import SwiftUI

struct AddProductView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ürün Kartı")
                        .font(.title2.weight(.semibold))
                    Text("Her SKU satırının Renk sütunu çıktıya yazılır. Bilgiler’de geçen örnek renk, dosyadan otomatik bulunup bu sütundaki metinle değiştirilir. Bej, Gri gibi tonlar için ayrı satır ekleyebilirsin.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
            }
            .padding(20)

            HStack(alignment: .top, spacing: 20) {
                inputTable
                settingsPanel
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            HStack {
                if let message = viewModel.status.message {
                    StatusBadge(status: viewModel.status, message: message)
                }
                Spacer()
                Button {
                    viewModel.addDraftsToList()
                } label: {
                    Label("Listeye Ekle", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
            .background(.bar)
        }
    }

    private var inputTable: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SKU satırları")
                .font(.headline)
            Text("Renk: Bu ürün satırı için Excel’deki çıktı tonu (Bilgiler’deki örnek kelime dosyadan otomatik değiştirilir).")
                .font(.caption)
                .foregroundStyle(.secondary)
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
                GridRow {
                    Text("STOKKODU").font(.caption.weight(.semibold))
                    Text("Ürün Adı").font(.caption.weight(.semibold))
                    Text("Renk").font(.caption.weight(.semibold))
                    Text("").frame(width: 28)
                }
                ForEach($viewModel.draftRows) { $row in
                    GridRow {
                        TextField("", text: $row.stockCode)
                            .textFieldStyle(.roundedBorder)
                        TextField("", text: $row.productName)
                            .textFieldStyle(.roundedBorder)
                        TextField("", text: $row.color)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            viewModel.removeDraftRow(row)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                        .help("Satırı kaldır")
                    }
                }
            }
            Button {
                viewModel.addDraftRow()
            } label: {
                Label("SKU satırı ekle", systemImage: "plus")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Aktarım Bilgileri")
                .font(.headline)
            Picker("Önyazı Tipi", selection: $viewModel.selectedIntroType) {
                ForEach(IntroType.allCases) { type in
                    Text(viewModel.introLabels[type] ?? type.rawValue).tag(type)
                }
            }

            Picker("SATISFIYATI (üstü çizili liste)", selection: $viewModel.selectedStrikeThroughPreset) {
                ForEach(StrikeThroughDiscountPreset.allCases) { preset in
                    Text(preset.label).tag(preset)
                }
            }
            Text("Bilgiler’deki satır fiyatı (Fiyatlar / İndirimli kolonları) yazılır; aynı değerden liste fiyatı geri hesaplanır.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Kategori Ağacı")
                    .font(.subheadline.weight(.semibold))
                CategoryTreePickerView(
                    nodes: EmbeddedCatalog.categoryTree,
                    selectedID: viewModel.selectedCatalogID,
                    onSelect: viewModel.selectCatalog
                )
                .frame(height: 274)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Seçilen Breadcrumb")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(viewModel.selectedBreadcrumb)
                    .font(.callout)
                    .lineLimit(2)
                Text("Excel KATEGORILER çıktısı")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                Text(viewModel.selectedCategory)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            Divider()
            HStack {
                VStack(alignment: .leading) {
                    Text("Bilgiler.xlsx")
                        .font(.subheadline.weight(.medium))
                    Text(viewModel.fileSettings.variationURL?.lastPathComponent ?? "Dosya seçilmedi")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                Button {
                    viewModel.chooseVariationFile()
                } label: {
                    Image(systemName: "folder")
                }
                .help("Bilgiler.xlsx seç")
            }
        }
        .frame(width: 420, alignment: .topLeading)
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
    }
}
