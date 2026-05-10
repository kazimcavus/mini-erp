# mini-erp — Ürün yükleme Excel şablonu

macOS **SwiftUI** uygulaması: **gömülü** ana `.xlsx` şablonunu (ilk sayfa başlıkları + isteğe bağlı baseline satırı), her ürün/varyant için `Bilgiler.xlsx` verileriyle doldurarak **çok satırlı ürün yükleme dosyası** üretir.

**EN:** Generates product-upload Excel from a master template plus per-variation `Bilgiler.xlsx` files—multi-color rows, categories, barcodes, Turkish price formatting, discounted/list price rules.

## Gereksinimler

- macOS  
- [Swift](https://www.swift.org/) (SwiftPM ile derleme)

## Çalıştırma

```bash
swift run ProductTemplateBuilder
```

## Ana şablon (gömülü)

Dosya: `Sources/ProductTemplateBuilder/Resources/UrunYuklemeSablonu.xlsx`. **İlk satır** dışa aktarımda kullanılan sütun başlıklarıdır (birebir Ticimax şablonuyla aynı olmalı). **İkinci satır** yoksa veya boşsa baseline yok sayılır; bilinen başlıklar `TemplateMapper` ile, diğer sütunlar baseline’dan (varsa) kopyalanır. Çıktıda **Excel şablonu oluştur** ile **kaydet** panelinde istediğin klasöre yazılır.

Şablonu güncellemek için bu dosyayı değiştirip projeyi yeniden derle.

## Özellikler (özet)

- Çoklu çıktı rengi için ayrı satır; `Bilgiler` içinden renk/ifade eşlemesi  
- Kategori ağacı ve breadcrumb seçimi; gömülü katalog verisi  
- Barkod sırası, `VARYASYONKODU` ve şablon başlıklarına göre eşleştirme  
- İndirimli fiyat: en yakın **5 TL** adımına yuvarlama; liste/satış fiyatı seçilen indirim kuralına göre  
- Türkçe fiyat gösterimi (virgül ondalık, binlik ayraçsız çıktı); Excel hücreleri sade (beyaz) bırakılır  
- Ticimax'tan indirilen ürün listesindeki aynı `OZELALAN1` gruplarından ilgili ürünler Excel'i üretir
- Ticimax ürün listesi + `Ürünler.xlsx` teknik kaynak listesinden `urunteknikdetaylari` formatında teknik detay Excel'i üretir; `Menşei` satırı STOKKODU bazında seçilebilir

## Akış

1. Sol panelden isteğe bağlı başlangıç barkodu.  
2. **Ürün Ekle** ile stok kodu, ürün adı, renk satırları ve `Bilgiler.xlsx` seçimi.  
3. Kategori ağacından kategori / breadcrumb seçimi.  
4. **Excel şablonu oluştur** ile çıktı `.xlsx` kaydı.  
5. **İlgili Ürünler Oluştur** ile Ticimax ürün listesini seçip `URUNKARTIID` / `ILGILIURUNKARTIID` dosyası üretimi.  
6. **Teknik Detaylar Oluştur** ile Ticimax ürün listesini ve `Ürünler.xlsx` kaynak listesini seçip Menşei eklenecek STOKKODU satırlarını onaylama.  

## Geliştirme

Swift Package Manager:

```bash
swift build
```
