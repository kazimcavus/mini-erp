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
                status = .warning("Her satırda STOKKODU ve ürün adı dolu olmalı.")
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
        let templateURL = AppDefaults.mainTemplateURL
        guard FileManager.default.fileExists(atPath: templateURL.path) else {
            status = .warning("Ana şablon dosyası bulunamadı: \(templateURL.path)")
            return
        }
        guard !products.isEmpty else {
            status = .warning("Aktarım için önce en az bir ürün ekle.")
            return
        }
        guard let outputURL = FilePanelService.saveXLSX(defaultName: "urun-yukleme-template.xlsx") else { return }

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
        guard let sourceURL = FilePanelService.chooseXLSX(title: "Ticimax ürün listesini seç") else { return }
        guard let outputURL = FilePanelService.saveXLSX(defaultName: "urun-ilgili-urunler.xlsx") else { return }

        do {
            let table = try reader.readFirstSheet(from: sourceURL)
            let rows = try relatedProductsBuilder.makeRows(from: table)
            guard !rows.isEmpty else {
                status = .warning("Aynı OZELALAN1 değerine göre ilgili ürün satırı bulunamadı.")
                return
            }
            try writer.writeRelatedProducts(outputURL: outputURL, rows: rows)
            status = .success("İlgili ürünler Excel'i \(rows.count) satırla oluşturuldu.")
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    func prepareTechnicalDetailsTemplate() {
        guard let ticimaxURL = FilePanelService.chooseXLSX(title: "Ticimax ürün listesini seç") else { return }
        guard let sourceURL = FilePanelService.chooseXLSX(title: "Ürünler.xlsx teknik detay kaynak listesini seç") else { return }

        do {
            let ticimaxTable = try reader.readFirstSheet(from: ticimaxURL)
            let sourceTable = try reader.readFirstSheet(from: sourceURL)
            let prepared = try technicalDetailsBuilder.products(from: ticimaxTable, sourceTable: sourceTable)
            guard !prepared.products.isEmpty else {
                status = .warning("STOKKODU eşleşmesi bulunan ürün bulunamadı.")
                return
            }
            technicalDetailDraft = TechnicalDetailDraft(
                ticimaxTable: ticimaxTable,
                sourceTable: sourceTable,
                products: prepared.products,
                selectedOriginStockCodes: Set(prepared.products.map(\.stockCode)),
                missingSourceStockCodes: prepared.missingSourceStockCodes
            )
            let missingMessage = prepared.missingSourceStockCodes.isEmpty ? "" : " \(prepared.missingSourceStockCodes.count) STOKKODU kaynak listede bulunamadı."
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
}
