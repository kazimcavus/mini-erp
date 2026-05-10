import SwiftUI

enum AppTheme {
    static let windowBackground = Color(red: 0.961, green: 0.961, blue: 0.969)
    static let cardBackground = Color(nsColor: .windowBackgroundColor)
    static let sidebarBackground = Color(nsColor: .windowBackgroundColor).opacity(0.72)
    static let accent = Color(red: 0.176, green: 0.388, blue: 0.914)
    static let accentSoft = Color(red: 0.176, green: 0.388, blue: 0.914).opacity(0.10)
    static let border = Color.black.opacity(0.07)
    static let softBorder = Color.white.opacity(0.68)
    static let mutedText = Color.secondary
}

struct CardContainer<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.cardBackground)
                    .shadow(color: .black.opacity(0.055), radius: 18, x: 0, y: 8)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            }
    }
}

struct StatPillView: View {
    let title: String
    let systemImage: String
    var tint: Color = AppTheme.accent

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.primary.opacity(0.78))
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(tint.opacity(0.08), in: Capsule())
            .overlay {
                Capsule().stroke(tint.opacity(0.14), lineWidth: 1)
            }
    }
}

struct MacButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
        case subtle
    }

    var kind: Kind = .secondary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, kind == .primary ? 15 : 13)
            .padding(.vertical, 9)
            .foregroundStyle(foregroundColor)
            .background(background(isPressed: configuration.isPressed), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            }
            .shadow(color: shadowColor, radius: kind == .primary ? 8 : 0, x: 0, y: 4)
            .opacity(configuration.isPressed ? 0.82 : 1)
    }

    private var foregroundColor: Color {
        switch kind {
        case .primary: .white
        case .secondary: .primary.opacity(0.84)
        case .subtle: .secondary
        }
    }

    private var borderColor: Color {
        switch kind {
        case .primary: Color.white.opacity(0.18)
        case .secondary: AppTheme.border
        case .subtle: Color.clear
        }
    }

    private var shadowColor: Color {
        switch kind {
        case .primary: AppTheme.accent.opacity(0.20)
        case .secondary, .subtle: .clear
        }
    }

    private func background(isPressed: Bool) -> Color {
        switch kind {
        case .primary: isPressed ? AppTheme.accent.opacity(0.82) : AppTheme.accent
        case .secondary: isPressed ? Color.black.opacity(0.055) : Color.white.opacity(0.82)
        case .subtle: isPressed ? Color.black.opacity(0.045) : Color.clear
        }
    }
}

struct ModalHeaderView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: AppTheme.accent.opacity(0.20), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(MacButtonStyle(kind: .subtle))
            .help("Kapat")
        }
    }
}

struct RoundedInputStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            }
    }
}

struct FileSettingsView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        CardContainer(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Başlangıç Barkodu", systemImage: "barcode.viewfinder")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.82))

                TextField("", text: $viewModel.startingBarcode)
                    .textFieldStyle(.plain)
                    .font(.system(.title3, design: .monospaced).weight(.medium))
                    .padding(.horizontal, 13)
                    .frame(height: 46)
                    .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    }

                Text("Boş bırakırsan barkod kolonu boş kalır.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Ana üretim akışından ayrı, ek Excel araçları (sidebar).
struct SidebarExcelToolsView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        CardContainer(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Label("Ek Excel araçları", systemImage: "wrench.and.screwdriver")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.82))

                Text("Ürün listesi oluşturmaktan bağımsız işlemler.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 8) {
                    toolRow(
                        title: "İlgili Ürünler",
                        subtitle: "Ticimax ürün listesi → ilişkilendirilmiş Excel",
                        systemImage: "link",
                        help: "Kaynak Excel’den OZELALAN1’a göre ilgili ürün satırları üretir."
                    ) {
                        viewModel.exportRelatedProductsTemplate()
                    }

                    toolRow(
                        title: "Teknik Detaylar",
                        subtitle: "Ticimax liste + Ürünler kaynağı→ şablon",
                        systemImage: "list.clipboard",
                        help: "İki Excel seçilir; Menşei seçimi penceresi açılır, ardından dışa aktarım yapılır."
                    ) {
                        viewModel.prepareTechnicalDetailsTemplate()
                    }

                    toolRow(
                        title: "Çekim klasörleri",
                        subtitle: "Bilgiler.xlsx → Fiyatlar + Varyasyon",
                        systemImage: "camera.fill",
                        help: "Ana klasör seçilir; alt klasörlerdeki Bilgiler dosyasından formülsüz, klasör adlı .xlsx üretilir."
                    ) {
                        viewModel.batchNormalizeBilgilerFolders()
                    }
                }
            }
        }
    }

    private func toolRow(
        title: String,
        subtitle: String,
        systemImage: String,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.accentSoft, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.88))
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.028), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
