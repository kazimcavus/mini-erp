import AppKit
import SwiftUI

/// Excel’den kopyalanan iki sütun (tab ayraçlı, çok satır) yapıştırmayı ayıklar; tek hücre / tab yoksa `nil`.
enum ExcelTwoColumnPasteParser {
    static func parse(_ raw: String) -> [(String, String)]? {
        let normalized = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }

        let lines = normalized
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !lines.isEmpty else { return nil }

        if lines.count == 1 {
            let line = lines[0]
            guard line.contains("\t") else { return nil }
            return [splitLine(line)]
        }
        return lines.map { splitLine($0) }
    }

    private static func splitLine(_ line: String) -> (String, String) {
        let parts = line.components(separatedBy: "\t")
        let first = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let second = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : ""
        return (first, second)
    }
}

final class PasteAwareStockNSTextView: NSTextView {
    var structuredPasteHandler: (([(String, String)]) -> Void)?

    override func paste(_ sender: Any?) {
        guard let raw = NSPasteboard.general.string(forType: .string),
              let rows = ExcelTwoColumnPasteParser.parse(raw),
              !rows.isEmpty
        else {
            super.paste(sender)
            return
        }
        structuredPasteHandler?(rows)
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: 38)
    }
}

/// İlk stok kutusu: Excel çoklu yapıştırma. `NSScrollView` SwiftUI ile sıfır genişlik verdiği için düz `NSTextView`.
struct StockCodePasteTextField: NSViewRepresentable {
    typealias NSViewType = PasteAwareStockNSTextView

    @Binding var text: String
    var onTwoColumnPaste: ([(String, String)]) -> Void

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: StockCodePasteTextField

        init(_ parent: StockCodePasteTextField) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> PasteAwareStockNSTextView {
        let tv = PasteAwareStockNSTextView(frame: NSRect(x: 0, y: 0, width: 200, height: 38))
        tv.delegate = context.coordinator
        tv.isRichText = false
        tv.importsGraphics = false
        tv.drawsBackground = false
        tv.backgroundColor = .clear
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false
        tv.isVerticallyResizable = false
        tv.isHorizontallyResizable = false
        tv.font = .systemFont(ofSize: 13, weight: .medium)
        tv.minSize = NSSize(width: 0, height: 38)
        tv.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: 38)
        tv.autoresizingMask = [.width, .maxYMargin]
        tv.string = text
        tv.focusRingType = .default

        tv.wantsLayer = true
        tv.layer?.cornerCurve = .continuous
        tv.layer?.cornerRadius = 11
        tv.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.035).cgColor
        tv.layer?.borderWidth = 1
        tv.layer?.borderColor = NSColor.black.withAlphaComponent(0.07).cgColor
        tv.textContainerInset = NSSize(width: 10, height: 8)
        tv.textContainer?.lineFragmentPadding = 0
        tv.textContainer?.widthTracksTextView = true
        tv.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        tv.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        tv.invalidateIntrinsicContentSize()
        tv.layer?.masksToBounds = true
        return tv
    }

    func updateNSView(_ tv: PasteAwareStockNSTextView, context: Context) {
        context.coordinator.parent = self
        tv.structuredPasteHandler = { rows in
            onTwoColumnPaste(rows)
        }
        if tv.string != text {
            tv.string = text
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: PasteAwareStockNSTextView, context: Context) -> CGSize? {
        guard let pw = proposal.width, pw.isFinite, !pw.isNaN, pw > 1 else {
            return CGSize(width: 200, height: 38)
        }
        return CGSize(width: max(pw, 80), height: 38)
    }
}
