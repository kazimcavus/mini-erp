import Foundation

struct CatalogSelection: Identifiable, Hashable {
    var id: String { breadcrumb }
    let breadcrumb: String
    let category: String
    let sourceCount: Int
    let variantCount: Int
    var pathComponents: [String] { breadcrumb.split(separator: ">").map { String($0) } }
    var displayName: String { pathComponents.last ?? breadcrumb }
}

struct CategoryTreeNode: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    let selection: CatalogSelection?
    let children: [CategoryTreeNode]
    var outlineChildren: [CategoryTreeNode]? { children.isEmpty ? nil : children }
}

struct IntroTemplate: Identifiable, Hashable {
    let id: IntroType
    let label: String
    let html: String
}

enum EmbeddedCatalog {
    static let categorySelections: [CatalogSelection] = [
        CatalogSelection(breadcrumb: "Halı Aksesuarları", category: "Halı Aksesuarları;", sourceCount: 1, variantCount: 1),
        CatalogSelection(breadcrumb: "Tüm Halılar>Akrilik Halı", category: "Makine Halıları;Salon Halısı;Antre Halısı;Koridor Halısı;Yatak Odası Halısı;Mutfak Halısı;Tüm Halılar>Akrilik Halı;Çocuk Odası Halısı;Tüm Halılar;Tüm Halılar>Düz Renk Halı;", sourceCount: 84, variantCount: 4),
        CatalogSelection(breadcrumb: "Tüm Halılar>Bohem Halı", category: "Makine Halıları;Salon Halısı;Antre Halısı;Koridor Halısı;Yatak Odası Halısı;Mutfak Halısı;Çocuk Odası Halısı;Tüm Halılar;Tüm Halılar>Bohem Halı;", sourceCount: 304, variantCount: 7),
        CatalogSelection(breadcrumb: "Tüm Halılar>Dana Derisi Halı", category: "Salon Halısı;Antre Halısı;Yatak Odası Halısı;Tüm Halılar;Tüm Halılar>Dana Derisi Halı;", sourceCount: 13, variantCount: 1),
        CatalogSelection(breadcrumb: "Tüm Halılar>Düz Renk Halı", category: "Makine Halıları;Salon Halısı;Antre Halısı;Koridor Halısı;Yatak Odası Halısı;Mutfak Halısı;Çocuk Odası Halısı;Tüm Halılar;Tüm Halılar>Kaymaz Taban Halı;Tüm Halılar>Düz Renk Halı;", sourceCount: 295, variantCount: 4),
        CatalogSelection(breadcrumb: "Tüm Halılar>Jüt Halı", category: "Makine Halıları;Salon Halısı;Antre Halısı;Koridor Halısı;Yatak Odası Halısı;Mutfak Halısı;Tüm Halılar;Tüm Halılar>Jüt Halı;", sourceCount: 56, variantCount: 4),
        CatalogSelection(breadcrumb: "Tüm Halılar>Kaymaz Taban Halı", category: "Makine Halıları;Salon Halısı;Antre Halısı;Koridor Halısı;Yatak Odası Halısı;Mutfak Halısı;Çocuk Odası Halısı;Tüm Halılar;Tüm Halılar>Bohem Halı;Tüm Halılar>Kaymaz Taban Halı;", sourceCount: 152, variantCount: 1),
        CatalogSelection(breadcrumb: "Tüm Halılar>Kesme Halı", category: "Makine Halıları;Salon Halısı;Antre Halısı;Koridor Halısı;Yatak Odası Halısı;Mutfak Halısı;Çocuk Odası Halısı;Tüm Halılar;Tüm Halılar>Kesme Halı;", sourceCount: 224, variantCount: 3),
        CatalogSelection(breadcrumb: "Tüm Halılar>Makinede Yıkanabilir Halı", category: "Makine Halıları;Salon Halısı;Antre Halısı;Koridor Halısı;Yatak Odası Halısı;Mutfak Halısı;Çocuk Odası Halısı;Tüm Halılar;Tüm Halılar>Makinede Yıkanabilir Halı;Kaymaz Taban Halı;", sourceCount: 115, variantCount: 2),
        CatalogSelection(breadcrumb: "Tüm Halılar>Oval Halı", category: "Makine Halıları;Salon Halısı;Antre Halısı;Koridor Halısı;Yatak Odası Halısı;Mutfak Halısı;Çocuk Odası Halısı;Tüm Halılar;Tüm Halılar>Bohem Halı;Tüm Halılar>Oval Halı;", sourceCount: 2, variantCount: 1),
        CatalogSelection(breadcrumb: "Tüm Halılar>Peluş Halı", category: "Makine Halıları;Salon Halısı;Antre Halısı;Koridor Halısı;Yatak Odası Halısı;Mutfak Halısı;Çocuk Odası Halısı;Tüm Halılar;Tüm Halılar>Shaggy Halı;Tüm Halılar>Makinede Yıkanabilir Halı;Tüm Halılar>Yuvarlak Halı;Tüm Halılar>Peluş Halı;", sourceCount: 16, variantCount: 2),
        CatalogSelection(breadcrumb: "Tüm Halılar>Sisal Halı", category: "Makine Halıları;Salon Halısı;Antre Halısı;Koridor Halısı;Yatak Odası Halısı;Mutfak Halısı;Çocuk Odası Halısı;Tüm Halılar;Tüm Halılar>Sisal Halı;Tüm Halılar>Kesme Halı;Tüm Halılar>Düz Renk Halı;", sourceCount: 592, variantCount: 7),
        CatalogSelection(breadcrumb: "Tüm Halılar>Vintage Halı", category: "Makine Halıları;Salon Halısı;Antre Halısı;Koridor Halısı;Yatak Odası Halısı;Mutfak Halısı;Tüm Halılar;Tüm Halılar>Vintage Halı;", sourceCount: 418, variantCount: 1),
        CatalogSelection(breadcrumb: "Tüm Halılar>Vintage Sisal Halı", category: "Makine Halıları;Salon Halısı;Antre Halısı;Koridor Halısı;Yatak Odası Halısı;Mutfak Halısı;Tüm Halılar;Tüm Halılar>Vintage Halı;Tüm Halılar>Sisal Halı;Tüm Halılar>Vintage Sisal Halı;", sourceCount: 1, variantCount: 1),
        CatalogSelection(breadcrumb: "Tüm Halılar>İskandinav Halı", category: "Makine Halıları;Salon Halısı;Antre Halısı;Koridor Halısı;Yatak Odası Halısı;Mutfak Halısı;Çocuk Odası Halısı;Tüm Halılar;Tüm Halılar>İskandinav Halı;", sourceCount: 268, variantCount: 6),
        CatalogSelection(breadcrumb: "Çocuk Odası Halısı", category: "Makine Halıları;Salon Halısı;Antre Halısı;Koridor Halısı;Yatak Odası Halısı;Mutfak Halısı;Çocuk Odası Halısı;Tüm Halılar;", sourceCount: 6, variantCount: 1),
    ]

    static let categoryTree: [CategoryTreeNode] = CategoryTreeBuilder.build(from: categorySelections)

    static let introTemplates: [IntroTemplate] = [
        IntroTemplate(id: .tip1, label: "Tip 1: Genel", html: BundledIntroHTML.tip1),
        IntroTemplate(id: .tip2, label: "Tip 2: Üçlü Bilgi", html: BundledIntroHTML.tip2),
        IntroTemplate(id: .tip3, label: "Tip 3: Yuvarlak Kesme", html: BundledIntroHTML.tip3),
        IntroTemplate(id: .tip4, label: "Tip 4: Dikdörtgen Kesme", html: BundledIntroHTML.tip4),
        IntroTemplate(id: .tip5, label: "Tip 5: Dana Derisi", html: BundledIntroHTML.tip5),
    ]
}

private enum CategoryTreeBuilder {
    static func build(from selections: [CatalogSelection]) -> [CategoryTreeNode] {
        let sorted = selections.sorted { lhs, rhs in
            sortKey(lhs.breadcrumb) < sortKey(rhs.breadcrumb)
        }
        return buildLevel(prefix: [], selections: sorted)
    }

    private static func buildLevel(prefix: [String], selections: [CatalogSelection]) -> [CategoryTreeNode] {
        var names: [String] = []
        for selection in selections {
            let components = selection.pathComponents
            guard components.count > prefix.count, Array(components.prefix(prefix.count)) == prefix else { continue }
            let name = components[prefix.count]
            if !names.contains(name) { names.append(name) }
        }
        return names.map { name in
            let pathComponents = prefix + [name]
            let path = pathComponents.joined(separator: ">")
            let exactSelection = selections.first { $0.breadcrumb == path }
            let children = buildLevel(prefix: pathComponents, selections: selections)
            return CategoryTreeNode(id: path, name: name, path: path, selection: exactSelection, children: children)
        }
    }

    private static func sortKey(_ breadcrumb: String) -> String {
        if breadcrumb == "Halı Aksesuarları" { return "00-" + breadcrumb }
        if breadcrumb.hasPrefix("Tüm Halılar>") { return "10-" + breadcrumb }
        if breadcrumb == "Çocuk Odası Halısı" { return "20-" + breadcrumb }
        return "30-" + breadcrumb
    }
}
