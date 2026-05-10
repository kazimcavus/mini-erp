import Foundation

/// Ana ürün yükleme şablonu: SwiftPM kaynak paketindeki `UrunYuklemeSablonu.xlsx` (başlık satırı birebir olmalı).
/// İlk veri satırı “baseline”: `TemplateMapper` eşleşmeyen sütunlar oradan kopyalanır; yalnız başlık da olabilir.
enum ProductUploadTemplateLocator {
    enum ResourceError: LocalizedError {
        case missingBundledXLSX

        var errorDescription: String? {
            switch self {
            case .missingBundledXLSX:
                "Gömülü şablon bulunamadı (UrunYuklemeSablonu.xlsx). Projeyi yeniden derleyin."
            }
        }
    }

    /// Okuma ve yazma için: paket içindeki şablon dosyası URL’si (salt okunur kopya yeterli).
    static func bundledTemplateURL() throws -> URL {
        guard let url = Bundle.module.url(forResource: "UrunYuklemeSablonu", withExtension: "xlsx") else {
            throw ResourceError.missingBundledXLSX
        }
        return url
    }
}
