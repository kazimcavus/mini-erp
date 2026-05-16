import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var fileSettings = FileSettings()
    @Published var products: [ProductEntry] = []
    @Published var draftRows: [ProductDraftRow] = [ProductDraftRow()]
    @Published var selectedIntroType: IntroType = .tip1
    @Published var selectedStrikeThroughPreset: StrikeThroughDiscountPreset = .percentOff20
    @Published var selectedCategory = ""
    @Published var selectedBreadcrumb = ""
    @Published var selectedCatalogID = ""
    @Published var startingBarcode = ""
    @Published var introLabels: [IntroType: String] = Dictionary(uniqueKeysWithValues: EmbeddedCatalog.introTemplates.map { ($0.id, $0.label) })
    @Published var status: AppStatus = .idle
    @Published var editingProduct: ProductEntry?
    @Published var technicalDetailDraft: TechnicalDetailDraft?

    private let reader = ExcelReader()
    private let writer = ExcelWriter()
    private let mapper = TemplateMapper()
    private let relatedProductsBuilder = RelatedProductsBuilder()
    private let technicalDetailsBuilder = TechnicalDetailsBuilder()
    private let priceUpdateBuilder = PriceUpdateBuilder()

    init() {
        if let selection = EmbeddedCatalog.categorySelections.first {
            selectCatalog(selection)
        }
    }

    func chooseVariationFile() {
        guard let url = FilePanelService.chooseXLSX() else { return }
        fileSettings.variationURL = url
        status = .success("Bilgiler.xlsx dosyası seçildi.")
    }

    func selectCatalog(_ selection: CatalogSelection) {
        selectedCatalogID = selection.id
        selectedCategory = selection.category
        selectedBreadcrumb = selection.breadcrumb
    }

    func addDraftRow() {
        draftRows.append(ProductDraftRow())
    }

    func removeDraftRow(_ row: ProductDraftRow) {
        draftRows.removeAll { $0.id == row.id }
        if draftRows.isEmpty { draftRows.append(ProductDraftRow()) }
    }

    /// Ürün adı yazılıp/yapıştırılınca renk alanı adın başından türetilir (kullanıcı sonra düzeltebilir).
    func syncDraftRowProductName(rowId: UUID, name: String) {
        guard let i = draftRows.firstIndex(where: { $0.id == rowId }) else { return }
        draftRows[i].productName = name
        draftRows[i].color = ProductNameColorInference.inferredColor(fromProductName: name)
    }

    /// İlk stok kutusuna Excel’den (iki yan yana sütun + çok satır) yapıştırıldığında satırları doldurur.
    func applyTwoColumnSkuNamePaste(rows: [(String, String)]) {
        guard !rows.isEmpty else { return }
        while draftRows.count < rows.count {
            draftRows.append(ProductDraftRow())
        }
        for i in rows.indices {
            draftRows[i].stockCode = rows[i].0
            syncDraftRowProductName(rowId: draftRows[i].id, name: rows[i].1)
        }
        status = .success("\(rows.count) satır stok kodu ve ürün adı yapıştırıldı.")
    }

    private func inferSourceColorPhrase(from url: URL) throws -> String {
        let table = try reader.readFirstSheet(from: url)
        for row in table.rows {
            for (key, value) in row where ExcelHeaderNormalizer.matches(key, "RENK") {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
        }
        for row in table.rows {
            for (_, value) in row {
                if let extracted = Self.extractRenkSemicolonColor(value), !extracted.isEmpty {
                    return extracted
                }
            }
        }
        return ""
    }

    /// `Renk;Bej` içinden örnek rengi çıkarır (Bilgiler’de ayrı RENK sütunu yoksa).
    private static func extractRenkSemicolonColor(_ raw: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"(?i)Renk\s*;\s*([^,]+)"#, options: []) else { return nil }
        let range = NSRange(raw.startIndex..., in: raw)
        guard let match = regex.firstMatch(in: raw, options: [], range: range),
              match.numberOfRanges >= 2,
              let cap = Range(match.range(at: 1), in: raw)
        else { return nil }
        return String(raw[cap]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func addDraftsToList() {
        guard let variationURL = fileSettings.variationURL else {
            status = .warning("Önce Bilgiler.xlsx varyasyon dosyasını seç.")
            return
        }
        let validRows = draftRows.filter { !$0.isEmpty }
        guard !validRows.isEmpty else {
            status = .warning("En az bir ürün satırı gir.")
            return
        }
        guard !selectedCategory.isEmpty else {
            status = .warning("Kategori ağacından bir kategori seç.")
            return
        }
        guard !selectedBreadcrumb.isEmpty else {
            status = .warning("Breadcrumb için bir kategori yolu seç.")
            return
        }

        for row in validRows {
            guard !row.stockCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !row.productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                status = .warning("Her satırda stok kodu ve ürün adı dolu olmalı.")
                return
            }
            guard !row.color.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                status = .warning("Her satırda Renk dolu olmalı.")
                return
            }
        }

        let inferredSource = ((try? inferSourceColorPhrase(from: variationURL)) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var added = 0
        for row in validRows {
            let stock = row.stockCode.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = row.productName.trimmingCharacters(in: .whitespacesAndNewlines)
            let targetColor = row.color.trimmingCharacters(in: .whitespacesAndNewlines)

            products.append(
                ProductEntry(
                    stockCode: stock,
                    productName: name,
                    color: targetColor,
                    sourceColorPhrase: inferredSource,
                    outputColorVariants: [],
                    introType: selectedIntroType,
                    category: selectedCategory,
                    breadcrumb: selectedBreadcrumb,
                    variationFileURL: variationURL,
                    strikeThroughDiscountPreset: selectedStrikeThroughPreset
                )
            )
            added += 1
        }
        draftRows = [ProductDraftRow()]
        status = .success("\(added) ürün kartı listeye eklendi.")
    }

    func deleteProducts(at offsets: IndexSet) {
        products.remove(atOffsets: offsets)
    }

    func deleteProduct(_ product: ProductEntry) {
        products.removeAll { $0.id == product.id }
    }

    func updateProduct(_ product: ProductEntry) {
        guard let index = products.firstIndex(where: { $0.id == product.id }) else { return }
        products[index] = product
        editingProduct = nil
        status = .success("Ürün güncellendi.")
    }

    func exportTemplate() {
        let templateURL: URL
        do {
            templateURL = try ProductUploadTemplateLocator.bundledTemplateURL()
        } catch {
            status = .failure(error.localizedDescription)
            return
        }
        guard !products.isEmpty else {
            status = .warning("Aktarım için önce en az bir ürün ekle.")
            return
        }
        guard let outputURL = FilePanelService.saveXLSX(
            defaultName: "urun-yukleme-template.xlsx",
            title: "Excel şablonunu kaydet",
            message: "Kayıt konumunu ve dosya adını seçin. Şablon gömülü kopyadan üretilir; başlık satırı sabittir."
        ) else { return }

        do {
            let headers = try reader.readHeaders(fromTemplate: templateURL)
            let baseline = try reader.readBaselineRow(fromTemplate: templateURL)
            var variationsByProduct: [UUID: [VariationRow]] = [:]
            for product in products {
                let table = try reader.readFirstSheet(from: product.variationFileURL)
                variationsByProduct[product.id] = table.rows.map { VariationRow(values: $0) }
            }
            let outputRows = mapper.makeRows(
                products: products,
                baselineKeyedByHeader: baseline,
                startingBarcode: startingBarcode,
                variationRowsByProductID: variationsByProduct,
                templateHeaders: headers
            )
            try writer.write(templateURL: templateURL, outputURL: outputURL, headers: headers, rows: outputRows)
            status = .success("Excel şablonu \(outputRows.count) satırla oluşturuldu.")
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    func exportRelatedProductsTemplate() {
        guard let sourceURL = FilePanelService.chooseXLSX(title: "Ürün listesi Excel dosyasını seç") else { return }
        guard let outputURL = FilePanelService.saveXLSX(defaultName: "urun-ilgili-urunler.xlsx") else { return }

        do {
            let table = try reader.readFirstSheet(from: sourceURL)
            let rows = try relatedProductsBuilder.makeRows(from: table)
            guard !rows.isEmpty else {
                status = .warning("Aynı özel alan 1 değerine göre ilgili ürün satırı bulunamadı.")
                return
            }
            try writer.writeRelatedProducts(outputURL: outputURL, rows: rows)
            status = .success("İlgili ürünler Excel'i \(rows.count) satırla oluşturuldu.")
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    @discardableResult
    func exportPriceUpdateTemplate(strikeThroughPreset: StrikeThroughDiscountPreset) -> Bool {
        guard let productURL = FilePanelService.chooseXLSX(title: "Ürün listesi Excel dosyasını seç") else { return false }
        guard let priceURL = FilePanelService.chooseXLSX(title: "SKU ve fiyat listesini seç") else { return false }

        do {
            let productTable = try reader.readFirstSheet(from: productURL)
            let priceTable = try reader.readFirstSheet(from: priceURL)
            let result = try priceUpdateBuilder.makeExport(
                productTable: productTable,
                priceTable: priceTable,
                preset: strikeThroughPreset
            )

            guard let outputURL = FilePanelService.saveXLSX(defaultName: "fiyat-guncelleme-urun-listesi.xlsx") else { return false }
            try writer.writeWorkbook(outputURL: outputURL, headers: result.headers, rows: result.rows)

            var messages = [
                "Fiyat güncelleme Excel'i \(result.rows.count) satırla oluşturuldu (\(result.matchedSKUCount) SKU)."
            ]
            if !result.unmatchedPriceSKUs.isEmpty {
                messages.append("\(result.unmatchedPriceSKUs.count) SKU ürün listesinde bulunamadı: \(preview(result.unmatchedPriceSKUs))")
            }
            if !result.invalidPriceSKUs.isEmpty {
                messages.append("\(result.invalidPriceSKUs.count) fiyat satırı atlandı: \(preview(result.invalidPriceSKUs))")
            }
            status = .success(messages.joined(separator: "\n"))
            return true
        } catch {
            status = .failure(error.localizedDescription)
            return false
        }
    }

    func prepareTechnicalDetailsTemplate() {
        guard let ticimaxURL = FilePanelService.chooseXLSX(title: "Ürün listesi Excel dosyasını seç") else { return }
        guard let sourceURL = FilePanelService.chooseXLSX(title: "Ürünler.xlsx teknik detay kaynak listesini seç") else { return }

        do {
            let ticimaxTable = try reader.readFirstSheet(from: ticimaxURL)
            let sourceTable = try reader.readFirstSheet(from: sourceURL)
            let prepared = try technicalDetailsBuilder.products(from: ticimaxTable, sourceTable: sourceTable)
            guard !prepared.products.isEmpty else {
                status = .warning("Stok kodu eşleşmesi bulunan ürün bulunamadı.")
                return
            }
            technicalDetailDraft = TechnicalDetailDraft(
                ticimaxTable: ticimaxTable,
                sourceTable: sourceTable,
                products: prepared.products,
                selectedOriginStockCodes: Set(prepared.products.map(\.stockCode)),
                missingSourceStockCodes: prepared.missingSourceStockCodes
            )
            let missingMessage = prepared.missingSourceStockCodes.isEmpty ? "" : " \(prepared.missingSourceStockCodes.count) stok kodu kaynak listede bulunamadı."
            status = .success("\(prepared.products.count) ürün Menşei seçimi için hazır.\(missingMessage)")
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    func setOriginSelected(stockCode: String, isSelected: Bool) {
        guard var draft = technicalDetailDraft else { return }
        if isSelected {
            draft.selectedOriginStockCodes.insert(stockCode)
        } else {
            draft.selectedOriginStockCodes.remove(stockCode)
        }
        technicalDetailDraft = draft
    }

    func selectAllOrigins() {
        guard var draft = technicalDetailDraft else { return }
        draft.selectedOriginStockCodes = Set(draft.products.map(\.stockCode))
        technicalDetailDraft = draft
    }

    func clearAllOrigins() {
        guard var draft = technicalDetailDraft else { return }
        draft.selectedOriginStockCodes = []
        technicalDetailDraft = draft
    }

    /// Çekim kök klasöründeki tüm görselleri masaüstünde `DDMMYYYY-Fotograflar` içine kopyalar.
    func exportShootFolderPhotosToDesktop() {
        guard let root = FilePanelService.chooseFolder(title: "Görsellerin bulunduğu kök klasörü seçin") else { return }
        do {
            let result = try ShootPhotoExporter.copyAllImages(from: root)
            if result.copiedCount == 0 {
                status = .warning("Bu klasörde desteklenen görsel dosyası bulunamadı.")
            } else {
                status = .success("\(result.copiedCount) görsel masaüstüne kopyalandı: \(result.destinationFolder.path)")
            }
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    /// Foto çekimi gibi yapılarda ana klasörü seçip alt klasörlerdeki `Bilgiler.xlsx` dosyalarını
    /// `{klasörAdı}.xlsx` olarak yeniden yazar (yalnız Fiyatlar + Varyasyon, formülsüz).
    func batchNormalizeBilgilerFolders() {
        guard let root = FilePanelService.chooseFolder(title: "Çekim ana klasörünü seçin (içinde ürün klasörleri)") else { return }
        do {
            let result = try BilgilerFolderBatchNormalizer.process(rootFolder: root, reader: reader, writer: writer)
            var lines: [String] = [
                "\(result.convertedCount) ürün klasörü işlendi: her birinde klasör adıyla .xlsx kaydedildi (sütunlar: Fiyatlar, Varyasyon; formül yok)."
            ]
            if result.skipped.isEmpty == false {
                lines.append("Atlanan (\(result.skipped.count)): \(result.skipped.prefix(3).joined(separator: " · "))\(result.skipped.count > 3 ? " …" : "")")
            }
            if result.failures.isEmpty == false {
                lines.append("Hata (\(result.failures.count)): \(result.failures.prefix(2).joined(separator: " · "))\(result.failures.count > 2 ? " …" : "")")
            }
            let message = lines.joined(separator: "\n")
            if result.convertedCount == 0, result.failures.isEmpty == false {
                status = .failure(message)
            } else if result.convertedCount == 0 {
                status = .warning(message)
            } else {
                status = .success(message)
            }
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    func exportTechnicalDetailsTemplate() {
        guard let draft = technicalDetailDraft else { return }
        guard let outputURL = FilePanelService.saveXLSX(defaultName: "urun-teknik-detaylari.xlsx") else { return }

        do {
            let rows = try technicalDetailsBuilder.makeRows(
                ticimaxTable: draft.ticimaxTable,
                sourceTable: draft.sourceTable,
                originStockCodes: draft.selectedOriginStockCodes
            )
            guard !rows.isEmpty else {
                status = .warning("Teknik detay satırı oluşturulamadı.")
                return
            }
            try writer.writeTechnicalDetails(outputURL: outputURL, rows: rows)
            technicalDetailDraft = nil
            status = .success("Teknik detaylar Excel'i \(rows.count) satırla oluşturuldu.")
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    private func preview(_ values: [String], limit: Int = 5) -> String {
        let shown = values.prefix(limit).joined(separator: ", ")
        return values.count > limit ? "\(shown), …" : shown
    }
}
