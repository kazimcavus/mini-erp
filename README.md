# Ticimax ERP Şablon

macOS SwiftUI uygulaması. Sabit ürün yükleme şablonundan gerçek `.xlsx` export üretir.

## Çalıştırma

```bash
swift run ProductTemplateBuilder
```

## Sabit Kaynaklar

Ana ürün yükleme şablonu:

`/Users/kazimcavus/Downloads/2501-Urun-Yukleme-Sablon-1-Son.xlsx`

Kategori, breadcrumb ve Tip 1/2/3 önyazı verisi şu dosyadan uygulamaya gömülüdür:

`/Users/kazimcavus/Downloads/urunlerexcel_04987ba3.xlsx`

## Akış

- Sol panelde başlangıç barkodu girilir.
- Ürün Ekle ile ürün kartı açılır.
- Kart içinde STOKKODU, ürün adı ve renk satırları girilir.
- Aynı karttaki tüm satırlar için bir `Bilgiler.xlsx` seçilir.
- Kategori ağacından yol seçilir.
- Uygulama seçilen breadcrumb yoluna göre Excel’deki örneklerden en sık kullanılan `KATEGORILER` çıktısını otomatik yazar.
- Export sırasında her varyasyon satırı için barkod bir artar ve metin olarak yazılır.
