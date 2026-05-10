import SwiftUI

struct EditProductView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var product: ProductEntry

    init(product: ProductEntry) {
        _product = State(initialValue: product)
    }

    var body: some View {
        VStack(spacing: 18) {
            ModalHeaderView(
                title: "Ürünü Düzenle",
                subtitle: "Ürün kartı bilgilerini ve aktarım ayarlarını güncelle.",
                systemImage: "pencil.circle.fill",
                onClose: { dismiss() }
            )

            CardContainer(padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    field("Stok kodu", text: $product.stockCode)
                    field("Ürün adı", text: $product.productName)
                    field("Renk (çıktı)", text: $product.color)
                    field("Bilgiler’de aranacak örnek renk", text: $product.sourceColorPhrase)

                    Text("Dosyada geçen örnek renk bu değer ile değiştirilir. Boş bırakırsan yalnızca Renk sütunu güncellenir.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider().opacity(0.55)

                    Picker("Önyazı tipi", selection: $product.introType) {
                        ForEach(IntroType.allCases) { type in
                            Text(viewModel.introLabels[type] ?? type.rawValue).tag(type)
                        }
                    }

                    Picker("Liste / üstü çizili varsayım", selection: $product.strikeThroughDiscountPreset) {
                        ForEach(StrikeThroughDiscountPreset.allCases) { preset in
                            Text(preset.label).tag(preset)
                        }
                    }

                    Picker("Kategori yolu", selection: Binding(
                        get: { product.breadcrumb },
                        set: { breadcrumb in
                            if let selection = EmbeddedCatalog.categorySelections.first(where: { $0.breadcrumb == breadcrumb }) {
                                product.breadcrumb = selection.breadcrumb
                                product.category = selection.category
                            }
                        }
                    )) {
                        ForEach(EmbeddedCatalog.categorySelections) { selection in
                            Text(selection.breadcrumb).tag(selection.breadcrumb)
                        }
                    }
                }
            }

            CardContainer(padding: 14) {
                HStack {
                    Spacer()
                    Button("Vazgeç") {
                        dismiss()
                    }
                    .buttonStyle(MacButtonStyle(kind: .secondary))

                    Button {
                        product.outputColorVariants = []
                        viewModel.updateProduct(product)
                        dismiss()
                    } label: {
                        Label("Kaydet", systemImage: "checkmark")
                    }
                    .buttonStyle(MacButtonStyle(kind: .primary))
                }
            }
        }
        .padding(22)
        .background(AppTheme.windowBackground)
        .frame(minWidth: 520, minHeight: 500)
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            TextField("", text: text)
                .textFieldStyle(RoundedInputStyle())
        }
    }
}
