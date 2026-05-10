import SwiftUI

struct CategoryTreePickerView: View {
    let nodes: [CategoryTreeNode]
    let selectedID: String
    let onSelect: (CatalogSelection) -> Void

    @State private var searchText = ""

    private var displayedNodes: [CategoryTreeNode] {
        Self.filteredTree(nodes, query: searchText)
    }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                TextField("Kategori ara…", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }

            if displayedNodes.isEmpty, !trimmedQuery.isEmpty {
                Text("“\(trimmedQuery)” için sonuç yok.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor).opacity(0.7))
                    }
            } else {
                List {
                    OutlineGroup(displayedNodes, children: \.outlineChildren) { node in
                        if let selection = node.selection {
                            Button {
                                onSelect(selection)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: selectedID == selection.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedID == selection.id ? Color.accentColor : .secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(node.name)
                                            .font(.callout.weight(selectedID == selection.id ? .semibold : .regular))
                                        if node.path.contains(">") {
                                            Text(node.path)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    if selection.variantCount > 1 {
                                        Text("\(selection.variantCount) varyant")
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color(nsColor: .controlBackgroundColor), in: Capsule())
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        } else {
                            Label(node.name, systemImage: "folder")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor).opacity(0.7))
                }
            }
        }
        /// SKU ızgarasından Tab ile bu bloka gelinmesin; seçim fare ile.
        .focusable(false)
    }

    /// Ağacı süzer: ada, breadcrumb veya Excel kategori metnine göre; eşleşen dalların üst klasörleri tutulur.
    private static func filteredTree(_ nodes: [CategoryTreeNode], query: String) -> [CategoryTreeNode] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return nodes }

        var out: [CategoryTreeNode] = []
        for node in nodes {
            let childFiltered = filteredTree(node.children, query: q)
            let selfHit = matchesQuery(node, q)
            guard selfHit || !childFiltered.isEmpty else { continue }
            let nextChildren = childFiltered.isEmpty ? node.children : childFiltered
            out.append(
                CategoryTreeNode(id: node.id, name: node.name, path: node.path, selection: node.selection, children: nextChildren)
            )
        }
        return out
    }

    private static func matchesQuery(_ node: CategoryTreeNode, _ q: String) -> Bool {
        if localizedContains(node.name, q) { return true }
        if localizedContains(node.path.replacingOccurrences(of: ">", with: " "), q) { return true }
        guard let sel = node.selection else { return false }
        if localizedContains(sel.breadcrumb, q) { return true }
        return localizedContains(sel.category, q)
    }

    private static func localizedContains(_ haystack: String, _ needle: String) -> Bool {
        haystack.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}
