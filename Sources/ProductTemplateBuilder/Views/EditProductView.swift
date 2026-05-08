import SwiftUI

struct EditProductView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var product: ProductEntry

    init(product: ProductEntry) {
        _product = State(initialValue: product)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ürünü Düzenle")
                .font(.title2.weight(.semibold))
            TextField("STOKKODU", text: $product.stockCode)
                .textFieldStyle(.roundedBorder)
            TextField("Ürün adı", text: $product.productName)
                .textFieldStyle(.roundedBorder)
            TextField("Renk (çıktı)", text: $product.color)
                .textFieldStyle(.roundedBorder)
            TextField("Bilgiler’de aranacak örnek renk (otomatik doldurulur; isteğe göre düzenle)", text: $product.sourceColorPhrase)
                .textFieldStyle(.roundedBorder)
            Text("Dosyada geçen örnek renk bu değer ile değiştirilir. Alanı boş bırakırsan yalnızca Renk sütunu güncellenir, diğer metinler olduğu gibi kalır.")
                .font(.caption2)
                .foregroundStyle(.secondary)
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
            Spacer()
            HStack {
                Button("Vazgeç") {
                    dismiss()
                }
                Spacer()
                Button("Kaydet") {
                    product.outputColorVariants = []
                    viewModel.updateProduct(product)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
        .frame(minWidth: 420, minHeight: 360)
    }
}
