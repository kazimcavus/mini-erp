import SwiftUI

struct MainView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showingAddProduct = false

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 18) {
                Text(AppBranding.sidebarTitle)
                    .font(.title2.weight(.bold))
                Text(AppBranding.sidebarSubtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                FileSettingsView()
                Spacer()
            }
            .padding(20)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.45))
            .navigationSplitViewColumnWidth(min: 320, ideal: 360)
        } detail: {
            VStack(spacing: 0) {
                header
                ProductListTable()
                footer
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .sheet(isPresented: $showingAddProduct) {
                AddProductView()
                    .environmentObject(viewModel)
                    .frame(minWidth: 1040, minHeight: 680)
            }
            .sheet(item: $viewModel.editingProduct) { product in
                EditProductView(product: product)
                    .environmentObject(viewModel)
                    .frame(width: 620, height: 420)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ürün Listesi")
                    .font(.title.weight(.semibold))
                Text("\(viewModel.products.count) ürün kartı aktarım için hazır")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 10) {
                Label("\(EmbeddedCatalog.categorySelections.count) kategori yolu", systemImage: "list.bullet.indent")
                Label("\(IntroType.allCases.count) önyazı tipi", systemImage: "text.alignleft")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            Button {
                showingAddProduct = true
            } label: {
                Label("Ürün Ekle", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if let message = viewModel.status.message {
                StatusBadge(status: viewModel.status, message: message)
            }
            Spacer()
            Button {
                viewModel.exportTemplate()
            } label: {
                Label("Excel Şablonu Oluştur", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.products.isEmpty)
        }
        .padding(20)
        .background(.bar)
    }
}
