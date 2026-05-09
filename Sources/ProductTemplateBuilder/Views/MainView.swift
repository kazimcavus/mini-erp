import SwiftUI

struct MainView: View {
    var body: some View {
        AppShellView()
    }
}

struct AppShellView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showingAddProduct = false

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
                .frame(width: 300)

            VStack(spacing: 18) {
                MainHeaderView(showingAddProduct: $showingAddProduct)
                ProductTableCardView(showingAddProduct: $showingAddProduct)
                BottomActionBarView()
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppTheme.windowBackground)
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
        .sheet(item: $viewModel.technicalDetailDraft) { _ in
            TechnicalDetailOriginSelectionView()
                .environmentObject(viewModel)
                .frame(minWidth: 760, minHeight: 620)
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            appIdentity
            FileSettingsView()
            sidebarStats
            Spacer()
        }
        .padding(22)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(AppTheme.sidebarBackground)
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(AppTheme.border)
                .frame(width: 1)
        }
    }

    private var appIdentity: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(LinearGradient(colors: [AppTheme.accent, Color.cyan.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 46, height: 46)
                    .shadow(color: AppTheme.accent.opacity(0.22), radius: 10, x: 0, y: 6)
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(AppBranding.sidebarTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                Text(AppBranding.sidebarSubtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var sidebarStats: some View {
        VStack(spacing: 10) {
            SidebarStatusRow(title: "Ürün Kartı", value: "\(viewModel.products.count)", systemImage: "cube.box")
            SidebarStatusRow(title: "Varyasyon", value: variationSummary, systemImage: "square.grid.2x2")
            SidebarStatusRow(title: "Barkod Durumu", value: viewModel.startingBarcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Boş" : "Hazır", systemImage: "barcode")
        }
    }

    private var variationSummary: String {
        viewModel.products.isEmpty ? "0" : "Hazır"
    }

}

struct SidebarStatusRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 30, height: 30)
                .background(AppTheme.accentSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.84))
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.softBorder, lineWidth: 1)
        }
    }
}

struct MainHeaderView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Binding var showingAddProduct: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ürün Listesi")
                    .font(.system(size: 32, weight: .bold))
                Text("Excel aktarımı için ürün kartlarını hazırla")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    StatPillView(title: "\(viewModel.products.count) ürün kartı", systemImage: "cube.box")
                    StatPillView(title: readinessText, systemImage: readinessIcon, tint: readinessTint)
                }
            }
            Spacer(minLength: 18)
            Button {
                showingAddProduct = true
            } label: {
                Label("Ürün Ekle", systemImage: "plus")
            }
            .buttonStyle(MacButtonStyle(kind: .primary))
            .keyboardShortcut("n", modifiers: [.command])
        }
    }

    private var readinessText: String {
        viewModel.products.isEmpty ? "Excel aktarımı için hazır değil" : "Excel aktarımı için hazır"
    }

    private var readinessIcon: String {
        viewModel.products.isEmpty ? "exclamationmark.circle" : "checkmark.circle"
    }

    private var readinessTint: Color {
        viewModel.products.isEmpty ? .orange : .green
    }
}

struct BottomActionBarView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        CardContainer(padding: 14) {
            HStack(spacing: 12) {
                statusArea
                Spacer(minLength: 16)
                actionGroup
            }
        }
    }

    private var statusArea: some View {
        Group {
            if let message = viewModel.status.message {
                StatusBadge(status: viewModel.status, message: message)
            } else {
                Label("Hazır", systemImage: "checkmark.circle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionGroup: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.exportRelatedProductsTemplate()
            } label: {
                Label("İlgili Ürünler", systemImage: "link")
            }
            .buttonStyle(MacButtonStyle(kind: .secondary))

            Button {
                viewModel.prepareTechnicalDetailsTemplate()
            } label: {
                Label("Teknik Detaylar", systemImage: "list.clipboard")
            }
            .buttonStyle(MacButtonStyle(kind: .secondary))

            Button {
                viewModel.exportTemplate()
            } label: {
                Label("Excel Şablonu Oluştur", systemImage: "tablecells")
            }
            .buttonStyle(MacButtonStyle(kind: .primary))
            .disabled(viewModel.products.isEmpty)
            .opacity(viewModel.products.isEmpty ? 0.48 : 1)
            .help(viewModel.products.isEmpty ? "Excel oluşturmak için önce ürün ekle." : "Ürün yükleme Excel şablonunu oluştur")
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(AppViewModel())
            .frame(width: 1180, height: 760)
    }
}
