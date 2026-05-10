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
                /// Sabit küçük yükseklik formu kesiyordu; min boyut + Edit içi ScrollView alt butonları gösterir.
                .frame(minWidth: 640, idealWidth: 680, minHeight: 620, idealHeight: 680)
        }
        .sheet(item: $viewModel.technicalDetailDraft) { _ in
            TechnicalDetailOriginSelectionView()
                .environmentObject(viewModel)
                .frame(minWidth: 760, idealWidth: 880, minHeight: 620, idealHeight: 720)
        }
    }
}

struct SidebarView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            appIdentity
            FileSettingsView()
            SidebarExcelToolsView()
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

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(AppViewModel())
            .frame(width: 1180, height: 760)
    }
}
