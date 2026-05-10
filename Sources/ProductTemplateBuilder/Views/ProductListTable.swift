import SwiftUI

struct ProductTableCardView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Binding var showingAddProduct: Bool

    var body: some View {
        CardContainer(padding: 0) {
            VStack(spacing: 0) {
                cardHeader
                Divider().opacity(0.55)
                if viewModel.products.isEmpty {
                    EmptyProductStateView(showingAddProduct: $showingAddProduct)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    tableContent
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var cardHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Aktarım Listesi")
                    .font(.system(size: 16, weight: .semibold))
                Text("\(viewModel.products.count) ürün kartı listede")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Label("Varyasyon dosyaları bağlı", systemImage: "doc.badge.gearshape")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var tableContent: some View {
        ScrollView(.horizontal) {
            VStack(spacing: 0) {
                ProductTableHeader()
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.products) { product in
                            ProductTableRow(product: product)
                            if product.id != viewModel.products.last?.id {
                                Divider()
                                    .padding(.leading, 18)
                                    .opacity(0.46)
                            }
                        }
                    }
                }
            }
            .frame(width: ProductTableLayout.totalWidth)
        }
    }
}

private enum ProductTableLayout {
    static let spacing: CGFloat = 12
    static let horizontalPadding: CGFloat = 18
    static let stock: CGFloat = 130
    static let name: CGFloat = 250
    static let color: CGFloat = 92
    static let source: CGFloat = 120
    static let intro: CGFloat = 88
    static let category: CGFloat = 230
    static let breadcrumb: CGFloat = 180
    static let file: CGFloat = 190
    static let actions: CGFloat = 84

    static let totalWidth: CGFloat =
        stock + name + color + source + intro + category + breadcrumb + file + actions +
        (spacing * 8) + (horizontalPadding * 2)
}

struct ProductTableHeader: View {
    var body: some View {
        HStack(spacing: ProductTableLayout.spacing) {
            header("Stok kodu", width: ProductTableLayout.stock)
            header("Ürün adı", width: ProductTableLayout.name)
            header("Renk", width: ProductTableLayout.color)
            header("Kaynak renk örneği", width: ProductTableLayout.source)
            header("Önyazı tipi", width: ProductTableLayout.intro)
            header("Kategori çıktısı", width: ProductTableLayout.category)
            header("Kategori yolu", width: ProductTableLayout.breadcrumb)
            header("Bilgiler dosyası", width: ProductTableLayout.file)
            header("İşlemler", width: ProductTableLayout.actions)
        }
        .padding(.horizontal, ProductTableLayout.horizontalPadding)
        .frame(height: 42)
        .background(Color.black.opacity(0.018))
    }

    private func header(_ value: String, width: CGFloat) -> some View {
        Text(value)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .frame(width: width, alignment: .leading)
    }
}

struct ProductTableRow: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let product: ProductEntry
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: ProductTableLayout.spacing) {
            stockCell
            mainText(product.productName, width: ProductTableLayout.name, lineLimit: 2)
            colorCell
            secondaryText(product.sourceColorPhrase.isEmpty ? "-" : product.sourceColorPhrase, width: ProductTableLayout.source)
            introCell
            secondaryText(product.category, width: ProductTableLayout.category)
            secondaryText(product.breadcrumb, width: ProductTableLayout.breadcrumb)
            fileCell
            actionsCell
        }
        .padding(.horizontal, ProductTableLayout.horizontalPadding)
        .frame(minHeight: 58)
        .background(isHovered ? AppTheme.accent.opacity(0.045) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }

    private var stockCell: some View {
        Text(product.stockCode)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundStyle(.primary.opacity(0.86))
            .lineLimit(1)
            .truncationMode(.middle)
            .frame(width: ProductTableLayout.stock, alignment: .leading)
    }

    private var colorCell: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(AppTheme.accent.opacity(0.24))
                .frame(width: 8, height: 8)
            Text(product.color)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
        }
        .frame(width: ProductTableLayout.color, alignment: .leading)
    }

    private var introCell: some View {
        Text(product.introType.rawValue)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppTheme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.accentSoft, in: Capsule())
            .frame(width: ProductTableLayout.intro, alignment: .leading)
    }

    private var fileCell: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc")
                .foregroundStyle(.secondary)
            Text(product.variationFileURL.lastPathComponent)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .frame(width: ProductTableLayout.file, alignment: .leading)
    }

    private var actionsCell: some View {
        HStack(spacing: 6) {
            Button {
                viewModel.editingProduct = product
            } label: {
                Image(systemName: "pencil")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .help("Düzenle")

            Button {
                viewModel.deleteProduct(product)
            } label: {
                Image(systemName: "trash")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red.opacity(0.82))
            .help("Sil")
        }
        .frame(width: ProductTableLayout.actions, alignment: .leading)
    }

    private func mainText(_ value: String, width: CGFloat, lineLimit: Int = 1) -> some View {
        Text(value)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.primary.opacity(0.88))
            .lineLimit(lineLimit)
            .truncationMode(.tail)
            .frame(width: width, alignment: .leading)
    }

    private func secondaryText(_ value: String, width: CGFloat) -> some View {
        Text(value)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(width: width, alignment: .leading)
    }
}

struct EmptyProductStateView: View {
    @Binding var showingAddProduct: Bool

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AppTheme.accentSoft)
                    .frame(width: 84, height: 84)
                Image(systemName: "shippingbox")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
            }
            VStack(spacing: 6) {
                Text("Henüz ürün yok")
                    .font(.system(size: 22, weight: .semibold))
                Text("Ürün Ekle ile ilk ürün kartını oluştur.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            Button {
                showingAddProduct = true
            } label: {
                Label("İlk Ürünü Ekle", systemImage: "plus")
            }
            .buttonStyle(MacButtonStyle(kind: .primary))
        }
        .padding(40)
    }
}

struct ProductListTable: View {
    @State private var showingAddProduct = false

    var body: some View {
        ProductTableCardView(showingAddProduct: $showingAddProduct)
    }
}

struct ProductTableCardView_Previews: PreviewProvider {
    static var previews: some View {
        ProductTableCardView(showingAddProduct: .constant(false))
            .environmentObject(AppViewModel())
            .frame(width: 980, height: 560)
            .padding()
            .background(AppTheme.windowBackground)
    }
}
