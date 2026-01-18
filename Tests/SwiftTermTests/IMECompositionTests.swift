//
//  IMECompositionTests.swift
//
//  Tests for IME composition preview functionality
//

#if os(macOS)
import Foundation
import Testing
import AppKit

@testable import SwiftTerm

@Suite(.serialized)
final class IMECompositionTests {

    /// Test that IME composition view is created on first use when showIMEComposition is called
    @Test func testIMECompositionViewCreatedOnFirstUse() {
        let terminalView = TerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))

        // Enable IME composition preview
        terminalView.showsIMECompositionPreview = true

        // Before any IME input, view should not exist yet (lazy creation)
        // Note: didSet might create the view, but we want to ensure showIMEComposition also creates it
        terminalView.imeCompositionView?.removeFromSuperview()
        terminalView.imeCompositionView = nil

        // Simulate first IME input by calling showIMEComposition
        terminalView.showIMEComposition(text: "ㅎ")

        // View should be created
        #expect(terminalView.imeCompositionView != nil, "IME composition view should be created on first use")
    }

    /// Test that IME composition view displays the correct text
    @Test func testIMECompositionViewDisplaysText() {
        let terminalView = TerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        terminalView.showsIMECompositionPreview = true

        // Simulate Korean composition: ㅎ → 하 → 한
        terminalView.showIMEComposition(text: "ㅎ")
        #expect(terminalView.imeCompositionView?.text == "ㅎ")

        terminalView.showIMEComposition(text: "하")
        #expect(terminalView.imeCompositionView?.text == "하")

        terminalView.showIMEComposition(text: "한")
        #expect(terminalView.imeCompositionView?.text == "한")
    }

    /// Test that IME composition view is hidden when text is nil
    @Test func testIMECompositionViewHiddenWhenTextNil() {
        let terminalView = TerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        terminalView.showsIMECompositionPreview = true

        // Show composition
        terminalView.showIMEComposition(text: "한")
        #expect(terminalView.imeCompositionView?.isHidden == false)

        // Clear composition (simulates unmarkText)
        terminalView.showIMEComposition(text: nil)
        #expect(terminalView.imeCompositionView?.isHidden == true)
    }

    /// Test that IME composition does nothing when preview is disabled
    @Test func testIMECompositionDisabledWhenPreviewOff() {
        let terminalView = TerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))

        // Keep preview disabled (default)
        terminalView.showsIMECompositionPreview = false

        // Try to show composition
        terminalView.showIMEComposition(text: "ㅎ")

        // View should not be created
        #expect(terminalView.imeCompositionView == nil)
    }

    /// Test setMarkedText triggers IME composition view update
    @Test func testSetMarkedTextTriggersCompositionView() {
        let terminalView = TerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        terminalView.showsIMECompositionPreview = true

        // Clear any existing view
        terminalView.imeCompositionView?.removeFromSuperview()
        terminalView.imeCompositionView = nil

        // Call setMarkedText (simulates IME input)
        terminalView.setMarkedText("ㅎ", selectedRange: NSRange(), replacementRange: NSRange())

        // View should be created and show the text
        #expect(terminalView.imeCompositionView != nil, "setMarkedText should create IME composition view")
        #expect(terminalView.imeCompositionView?.text == "ㅎ")
    }

    /// Test that unmarkText clears markedTextStorage after inserting
    @Test func testUnmarkTextClearsMarkedTextStorage() {
        let terminalView = TerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        terminalView.showsIMECompositionPreview = true

        // Simulate Korean composition
        terminalView.setMarkedText("한", selectedRange: NSRange(), replacementRange: NSRange())
        #expect(terminalView.markedTextStorage == "한", "markedTextStorage should contain the marked text")
        #expect(terminalView.hasMarkedText() == true, "hasMarkedText should return true")

        // Finalize composition by calling unmarkText
        terminalView.unmarkText()

        // Marked text should be cleared
        #expect(terminalView.markedTextStorage == nil, "markedTextStorage should be nil after unmarkText")
        #expect(terminalView.hasMarkedText() == false, "hasMarkedText should return false after unmarkText")
    }

    /// Test complete Korean composition flow: setMarkedText → unmarkText
    @Test func testCompleteKoreanCompositionFlow() {
        let terminalView = TerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        terminalView.showsIMECompositionPreview = true

        // Simulate full Korean composition: ㅎ → 하 → 한
        terminalView.setMarkedText("ㅎ", selectedRange: NSRange(), replacementRange: NSRange())
        #expect(terminalView.markedTextStorage == "ㅎ")

        terminalView.setMarkedText("하", selectedRange: NSRange(), replacementRange: NSRange())
        #expect(terminalView.markedTextStorage == "하")

        terminalView.setMarkedText("한", selectedRange: NSRange(), replacementRange: NSRange())
        #expect(terminalView.markedTextStorage == "한")

        // Finalize - this should call insertText internally
        terminalView.unmarkText()

        // After unmarkText, storage should be cleared
        #expect(terminalView.markedTextStorage == nil)
        #expect(terminalView.hasMarkedText() == false)
    }

    /// Test that IME position tracking variables are initialized correctly
    @Test func testIMEPositionTrackingInitialState() {
        let terminalView = TerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        terminalView.showsIMECompositionPreview = true

        // Initially tracking variables should be reset
        #expect(terminalView.imeLastBufferX == -1)
        #expect(terminalView.imeLastInsertWidth == 0)
    }

    /// Test that tracking variables reset when composition ends
    @Test func testTrackingVariablesResetOnCompositionEnd() {
        let terminalView = TerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        terminalView.showsIMECompositionPreview = true

        // Show composition
        terminalView.showIMEComposition(text: "가")

        // Then clear composition
        terminalView.showIMEComposition(text: nil)

        // Tracking should be cleared
        #expect(terminalView.imeLastBufferX == -1, "imeLastBufferX should be reset after composition ends")
        #expect(terminalView.imeLastInsertWidth == 0, "imeLastInsertWidth should be reset after composition ends")
    }

    /// Test Unicode column width calculation for various characters
    @Test func testUnicodeColumnWidthCalculation() {
        // Test that UnicodeUtil.columnWidth returns correct values
        // Korean: width 2
        let koreanWidth = UnicodeUtil.columnWidth(rune: "한".unicodeScalars.first!)
        #expect(koreanWidth == 2, "Korean character should have width 2")

        // ASCII: width 1
        let asciiWidth = UnicodeUtil.columnWidth(rune: "a".unicodeScalars.first!)
        #expect(asciiWidth == 1, "ASCII character should have width 1")

        // Japanese Hiragana: width 2
        let hiraganaWidth = UnicodeUtil.columnWidth(rune: "あ".unicodeScalars.first!)
        #expect(hiraganaWidth == 2, "Japanese hiragana should have width 2")

        // Chinese: width 2
        let chineseWidth = UnicodeUtil.columnWidth(rune: "中".unicodeScalars.first!)
        #expect(chineseWidth == 2, "Chinese character should have width 2")
    }

    /// Test overlay is created with correct structure for CJK text
    @Test func testOverlayCreatedForCJKText() {
        let terminalView = TerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        terminalView.showsIMECompositionPreview = true

        // Show composition with CJK character
        terminalView.showIMEComposition(text: "한")

        // Overlay should exist and have the text
        #expect(terminalView.imeCompositionView != nil, "Overlay should be created")
        #expect(terminalView.imeCompositionView?.text == "한", "Overlay should show the composition text")
        #expect(terminalView.imeCompositionView?.isHidden == false, "Overlay should be visible")
    }

    /// Test multiple character composition width calculation
    @Test func testMultiCharacterCompositionWidth() {
        // Test width calculation for multi-character strings
        let testCases: [(String, Int)] = [
            ("한", 2),       // Single Korean
            ("한글", 4),     // Two Korean
            ("abc", 3),     // Three ASCII
            ("한a글", 5),   // Mixed: 2 + 1 + 2
        ]

        for (text, expectedWidth) in testCases {
            var calculatedWidth = 0
            for scalar in text.unicodeScalars {
                let w = UnicodeUtil.columnWidth(rune: scalar)
                calculatedWidth += max(w, 1)
            }
            #expect(calculatedWidth == expectedWidth, "Width of '\(text)' should be \(expectedWidth), got \(calculatedWidth)")
        }
    }
}

#endif
