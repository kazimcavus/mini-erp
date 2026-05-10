import Foundation

enum AddProductSKUField: Hashable, Sendable {
    case stock, name, color
}

/// SKU ızgarasında Tab / odak senkronu ve satıra kaydırma için tanımlayıcı.
struct AddProductSKUFocus: Hashable, Sendable {
    let rowId: UUID
    let field: AddProductSKUField
}
