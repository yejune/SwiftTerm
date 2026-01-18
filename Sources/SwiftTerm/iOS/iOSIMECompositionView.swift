//
//  iOSIMECompositionView.swift
//  SwiftTerm
//
//  A view that displays IME composition text (e.g., Korean ㅎ → 하 → 한)
//  as an overlay at the cursor position.
//

#if os(iOS)
import UIKit

/// A view that displays IME composition text during input method composition
class iOSIMECompositionView: UIView {

    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// The composition text to display
    var text: String? {
        didSet {
            label.text = text
            isHidden = text == nil || text?.isEmpty == true
        }
    }

    /// The font to use for rendering (should match terminal font)
    var font: UIFont? {
        didSet {
            label.font = font
        }
    }

    /// Text color for the composition text
    var textColor: UIColor = .label {
        didSet {
            label.textColor = textColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        // No background, border, or shadow - just inline text like auto-completion
        backgroundColor = .clear

        // Add label with no padding
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        isHidden = true
    }

    /// Updates the view's appearance to match the terminal's current colors
    func updateColors(background: UIColor, foreground: UIColor, border: UIColor) {
        // No background for inline appearance
        textColor = foreground
        label.textColor = foreground
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
