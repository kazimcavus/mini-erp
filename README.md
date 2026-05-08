# mini-erp — Ürün yükleme Excel şablonu

macOS **SwiftUI** uygulaması: sabit bir ana `.xlsx` şablonunu, her ürün/varyant için `Bilgiler.xlsx` verileriyle doldurarak **çok satırlı ürün yükleme dosyası** üretir.

**EN:** Generates product-upload Excel from a master template plus per-variation `Bilgiler.xlsx` files—multi-color rows, categories, barcodes, Turkish price formatting, discounted/list price rules.

## Gereksinimler

- macOS  
- [Swift](https://www.swift.org/) (SwiftPM ile derleme)

## Çalıştırma

```bash
swift run ProductTemplateBuilder
```

## Şablon yolu

Ana şablon dosyasının yolu kodda sabittir: `Sources/ProductTemplateBuilder/Models/AppModels.swift` içindeki `AppDefaults.mainTemplateURL`. Kendi ortamında bu yolu gerçek `.xlsx` dosyana göre güncelle.

## Özellikler (özet)

- Çoklu çıktı rengi için ayrı satır; `Bilgiler` içinden renk/ifade eşlemesi  
- Kategori ağacı ve breadcrumb seçimi; gömülü katalog verisi  
- Barkod sırası, `VARYASYONKODU` ve şablon başlıklarına göre eşleştirme  
- İndirimli fiyat: en yakın **5 TL** adımına yuvarlama; liste/satış fiyatı seçilen indirim kuralına göre  
- Türkçe fiyat gösterimi (virgül ondalık, binlik ayraçsız çıktı); Excel hücreleri sade (beyaz) bırakılır  

## Akış

1. Sol panelden isteğe bağlı başlangıç barkodu.  
2. **Ürün Ekle** ile stok kodu, ürün adı, renk satırları ve `Bilgiler.xlsx` seçimi.  
3. Kategori ağacından kategori / breadcrumb seçimi.  
4. **Excel şablonu oluştur** ile çıktı `.xlsx` kaydı.  

## Geliştirme

Swift Package Manager:

```bash
swift build
```
