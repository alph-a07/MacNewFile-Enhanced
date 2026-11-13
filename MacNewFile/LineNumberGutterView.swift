import Cocoa

public class LineNumberGutterView: NSRulerView {
    private var lineNumberAttributes: [NSAttributedString.Key: Any] = [:]
    private var currentLineAttributes: [NSAttributedString.Key: Any] = [:]

    public init(textView: NSTextView) {
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 44.0
        updateAttributes()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateAttributes() {
        let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        let color = NSColor.secondaryLabelColor
        lineNumberAttributes = [
            .font: font,
            .foregroundColor: color
        ]
        currentLineAttributes = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ]
    }

    public override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = clientView as? NSTextView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else {
            return
        }

        let content = textView.string as NSString
        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: textContainer)
        let visibleCharRange = layoutManager.characterRange(forGlyphRange: visibleGlyphRange, actualGlyphRange: nil)

        // Calculate line number for visible range
        var lineNumber = 1
        content.enumerateSubstrings(in: NSRange(location: 0, length: content.length), options: [.byLines, .substringNotRequired]) { _, substringRange, _, stop in
            if substringRange.location >= visibleCharRange.location {
                stop.pointee = true
            } else {
                lineNumber += 1
            }
        }

        // Draw background for ruler
        NSColor.windowBackgroundColor.setFill()
        rect.fill()

        // Draw line separator
        let separatorRect = NSRect(x: self.ruleThickness - 1, y: rect.minY, width: 1, height: rect.height)
        NSColor.separatorColor.setFill()
        separatorRect.fill()

        var glyphIndex = visibleGlyphRange.location
        while glyphIndex < NSMaxRange(visibleGlyphRange) {
            let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            let lineRange = content.lineRange(for: NSRange(location: charIndex, length: 0))
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)

            let yPos = lineRect.minY + textView.textContainerInset.height - textView.visibleRect.minY

            let numString = "\(lineNumber)"
            let str = NSAttributedString(string: numString, attributes: lineNumberAttributes)
            let strSize = str.size()
            let drawPoint = NSPoint(x: self.ruleThickness - 8 - strSize.width, y: yPos + (lineRect.height - strSize.height) / 2)
            str.draw(at: drawPoint)

            glyphIndex = NSMaxRange(layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil))
            lineNumber += 1
        }
    }
}
