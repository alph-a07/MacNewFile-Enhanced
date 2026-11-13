import Cocoa

public class LineNumberGutterView: NSRulerView {
    public override var isFlipped: Bool {
        return true
    }

    public init(textView: NSTextView) {
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 44.0
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateAttributes() {
        needsDisplay = true
    }

    public override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = clientView as? NSTextView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else {
            return
        }

        // Subtle 1px right border for gutter
        let separatorRect = NSRect(x: ruleThickness - 1, y: 0, width: 1, height: bounds.height)
        NSColor.separatorColor.withAlphaComponent(0.25).setFill()
        separatorRect.fill()

        let content = textView.string as NSString
        guard content.length > 0 else {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                .foregroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.6)
            ]
            let str = NSAttributedString(string: "1", attributes: attrs)
            str.draw(at: NSPoint(x: ruleThickness - str.size().width - 8, y: textView.textContainerInset.height))
            return
        }

        var viewRect = textView.visibleRect
        if viewRect.height <= 0 {
            viewRect = textView.bounds
        }
        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: viewRect, in: textContainer)
        let visibleCharRange = layoutManager.characterRange(forGlyphRange: visibleGlyphRange, actualGlyphRange: nil)

        // Find starting line number
        var lineNumber = 1
        content.enumerateSubstrings(in: NSRange(location: 0, length: content.length), options: [.byLines, .substringNotRequired]) { _, substringRange, _, stop in
            if substringRange.location >= visibleCharRange.location {
                stop.pointee = true
            } else {
                lineNumber += 1
            }
        }

        let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.7)
        ]

        var glyphIndex = visibleGlyphRange.location
        while glyphIndex < NSMaxRange(visibleGlyphRange) {
            let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            let lineRange = content.lineRange(for: NSRange(location: charIndex, length: 0))
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)

            let yPos = lineRect.minY + textView.textContainerInset.height - textView.visibleRect.minY

            let numString = "\(lineNumber)"
            let str = NSAttributedString(string: numString, attributes: attrs)
            let strSize = str.size()
            let drawPoint = NSPoint(x: ruleThickness - strSize.width - 8, y: yPos + (lineRect.height - strSize.height) / 2)
            str.draw(at: drawPoint)

            glyphIndex = NSMaxRange(layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil))
            lineNumber += 1
        }
    }
}
