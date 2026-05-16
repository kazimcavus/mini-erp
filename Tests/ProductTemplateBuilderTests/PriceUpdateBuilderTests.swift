import XCTest
@testable import ProductTemplateBuilder

final class PriceUpdateBuilderTests: XCTestCase {
    func testSquareMetersFromVariation() {
        XCTAssertEqual(
            PriceUpdateBuilder.squareMeters(fromVariation: "Ölçü;160x230,Renk;Kırmızı"),
            Decimal(string: "3.68")
        )
        XCTAssertEqual(
            PriceUpdateBuilder.squareMeters(fromVariation: "Olcu;120 x 180,Renk;Bej"),
            Decimal(string: "2.16")
        )
        XCTAssertNil(PriceUpdateBuilder.squareMeters(fromVariation: "Renk;Bej"))
        XCTAssertNil(PriceUpdateBuilder.squareMeters(fromVariation: "Ölçü;,Renk;Bej"))
    }

    func testFiltersToPriceListSKUsAndCalculatesPercent20ListPrice() throws {
        let builder = PriceUpdateBuilder()
        let productHeaders = ["STOKKODU", "SATISFIYATI", "INDIRIMLIFIYAT", "VARYASYON", "URUNADI"]
        let productTable = table(
            headers: productHeaders,
            rows: [
                ["SKU-1", "0", "0", "Ölçü;160x230,Renk;Kırmızı", "Halı 1"],
                ["SKU-1", "0", "0", "Ölçü;200x290,Renk;Kırmızı", "Halı 1"],
                ["SKU-2", "0", "0", "Ölçü;120x180,Renk;Bej", "Halı 2"],
            ]
        )
        let priceTable = table(headers: ["SKU", "Fiyat"], rows: [["SKU-1", "1001"]])

        let result = try builder.makeExport(productTable: productTable, priceTable: priceTable, preset: .percentOff20)

        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.matchedSKUCount, 1)
        XCTAssertEqual(result.rows.map { $0[0] }, ["SKU-1", "SKU-1"])
        XCTAssertEqual(values(result, header: "INDIRIMLIFIYAT"), ["3683,68", "5805,8"])
        XCTAssertEqual(values(result, header: "SATISFIYATI"), ["4605", "7255"])
    }

    func testCalculatesPercent50ListPriceAndParsesTurkishPrice() throws {
        let builder = PriceUpdateBuilder()
        let productTable = table(
            headers: ["STOKKODU", "SATISFIYATI", "INDIRIMLIFIYAT", "VARYASYON"],
            rows: [["SKU-2", "0", "0", "Ölçü;120x180,Renk;Bej"]]
        )
        let priceTable = table(headers: ["STOKKODU", "M2 Fiyatı"], rows: [["SKU-2", "1.000,50"]])

        let result = try builder.makeExport(productTable: productTable, priceTable: priceTable, preset: .percentOff50)

        XCTAssertEqual(values(result, header: "INDIRIMLIFIYAT"), ["2161,08"])
        XCTAssertEqual(values(result, header: "SATISFIYATI"), ["4320"])
    }

    func testInvalidMatchedMeasureThrows() {
        let builder = PriceUpdateBuilder()
        let productTable = table(
            headers: ["STOKKODU", "SATISFIYATI", "INDIRIMLIFIYAT", "VARYASYON"],
            rows: [["SKU-1", "0", "0", "Renk;Bej"]]
        )
        let priceTable = table(headers: ["SKU", "Fiyat"], rows: [["SKU-1", "1000"]])

        XCTAssertThrowsError(
            try builder.makeExport(productTable: productTable, priceTable: priceTable, preset: .percentOff20)
        )
    }

    private func values(_ result: PriceUpdateExportResult, header: String) -> [String] {
        guard let index = result.headers.firstIndex(of: header) else { return [] }
        return result.rows.map { $0[index] }
    }

    private func table(headers: [String], rows: [[String]]) -> WorkbookTable {
        WorkbookTable(
            sheetName: "Sheet1",
            headers: headers,
            rows: rows.map { values in
                Dictionary(uniqueKeysWithValues: zip(headers, values))
            }
        )
    }
}
