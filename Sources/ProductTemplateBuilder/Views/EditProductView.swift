import SwiftUI

struct EditProductView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var product: ProductEntry

    /// Başlık + ara boşluklar + footer + düşey padding (ScrollView’a kalan orta band).
    private static let chromeHeightEstimate: CGFloat = 275

    init(product: ProductEntry) {
        _product = State(initialValue: product)
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 18) {
                ModalHeaderView(
                    title: "Ürünü Düzenle",
                    subtitle: "Ürün kartı bilgilerini ve aktarım ayarlarını güncelle.",
                    systemImage: "pencil.circle.fill",
                    onClose: { dismiss() }
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        CardContainer(padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                sectionTitle("Ürün bilgileri", systemImage: "cube.box")
                                field("Stok kodu", text: $product.stockCode)
                                field("Ürün adı", text: $product.productName)
                                field("Renk", text: $product.color)
                                field("Bilgiler’de aranacak örnek renk", text: $product.sourceColorPhrase)

                                Text(
                                    "Dosyada geçen örnek renk bu değer ile değiştirilir. Boş bırakırsan yalnızca Renk sütunu güncellenir."
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)

                                Divider().opacity(0.55)

                                sectionTitle("Aktarım Bilgileri", systemImage: "slider.horizontal.3")

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

                                Picker(
                                    "Kategori yolu",
                                    selection: Binding(
                                        get: { product.breadcrumb },
                                        set: { breadcrumb in
                                            if let selection = EmbeddedCatalog.categorySelections.first(where: { $0.breadcrumb == breadcrumb }) {
                                                product.breadcrumb = selection.breadcrumb
                                                product.category = selection.category
                                            }
                                        }
                                    )
                                ) {
                                    ForEach(EmbeddedCatalog.categorySelections) { selection in
                                        Text(selection.breadcrumb).tag(selection.breadcrumb)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            /// Scrollbar ile alanların üst üste binmesini önlemek için.
                            .padding(.trailing, 26)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.visible)
                .frame(height: max(240, geo.size.height - Self.chromeHeightEstimate))
                .clipped()

                footer
            }
            .padding(22)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .background(AppTheme.windowBackground)
        }
    }

    private var footer: some View {
        CardContainer(padding: 14) {
            HStack(spacing: 12) {
                Label("Liste ve Excel çıktısında güncel değerler kullanılır.", systemImage: "checkmark.circle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 12)

                Button("Vazgeç") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .buttonStyle(MacButtonStyle(kind: .secondary))

                Button {
                    product.outputColorVariants = []
                    viewModel.updateProduct(product)
                    dismiss()
                } label: {
                    Label("Kaydet", systemImage: "checkmark")
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(MacButtonStyle(kind: .primary))
            }
        }
    }

    private func sectionTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.primary.opacity(0.86))
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
