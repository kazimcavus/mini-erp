import SwiftUI

struct ProductListTable: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        Table(viewModel.products) {
            TableColumn("STOKKODU", value: \.stockCode)
            TableColumn("Ürün Adı", value: \.productName)
            TableColumn("Renk") { product in
                Text(product.color).lineLimit(2)
            }
            TableColumn("Kaynak") { product in
                Text(product.sourceColorPhrase.isEmpty ? "—" : product.sourceColorPhrase)
                    .lineLimit(1)
            }
            TableColumn("Önyazı") { product in
                Text(product.introType.rawValue)
            }
            TableColumn("Kategori Çıktısı") { product in
                Text(product.category)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            TableColumn("Breadcrumb", value: \.breadcrumb)
            TableColumn("Varyasyon Dosyası") { product in
                Text(product.variationFileURL.lastPathComponent)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            TableColumn("İşlemler") { product in
                HStack(spacing: 8) {
                    Button {
                        viewModel.editingProduct = product
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.borderless)
                    .help("Düzenle")
                    Button {
                        viewModel.deleteProduct(product)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Sil")
                }
            }
        }
        .overlay {
            if viewModel.products.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Henüz ürün yok")
                        .font(.headline)
                    Text("Ürün Ekle ile ilk ürün kartını oluştur.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
