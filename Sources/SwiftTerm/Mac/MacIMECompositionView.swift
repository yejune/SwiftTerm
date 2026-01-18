//
//  MacIMECompositionView.swift
//  SwiftTerm
//
//  A view that displays IME composition text (e.g., Korean ㅎ → 하 → 한)
//  as an overlay at the cursor position.
//

#if os(macOS)
import AppKit

/// A view that displays IME composition text during input method composition
class MacIMECompositionView: NSView {

    private let textField: NSTextField = {
        let field = NSTextField(labelWithString: "")
        field.alignment = .center
        field.translatesAutoresizingMaskIntoConstraints = false
        field.drawsBackground = false
        field.isBezeled = false
        field.isEditable = false
        field.isSelectable = false
        return field
    }()

    /// The composition text to display
    var text: String? {
        didSet {
            textField.stringValue = text ?? ""
            isHidden = text == nil || text?.isEmpty == true
        }
    }

    /// The font to use for rendering (should match terminal font)
    var font: NSFont? {
        didSet {
            textField.font = font
        }
    }

    /// Text color for the composition text
    var textColor: NSColor = .labelColor {
        didSet {
            textField.textColor = textColor
        }
    }

    /// Background color for overlay mode (to cover underlying text)
    var backgroundColor: NSColor = .clear {
        didSet {
            layer?.backgroundColor = backgroundColor.cgColor
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        wantsLayer = true

        // No background, border, or shadow - just inline text like auto-completion
        layer?.backgroundColor = NSColor.clear.cgColor

        // Add text field with no padding
        addSubview(textField)
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        isHidden = true
    }

    /// Updates the view's appearance to match the terminal's current colors
    func updateColors(background: NSColor, foreground: NSColor, border: NSColor) {
        // No background for inline appearance
        textColor = foreground
        textField.textColor = foreground
    }

    /// Calculates the preferred size for the given text
    func preferredSize(for text: String) -> CGSize {
        guard let font = font else { return .zero }
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = (text as NSString).size(withAttributes: attributes)
        // No padding - inline text like auto-completion
        return textSize
    }
}

#endif
