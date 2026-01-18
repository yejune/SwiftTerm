//
//  AppleIMESupportTests.swift
//
//  Tests for shared IME support utilities (AppleIMESupport.swift)
//  These tests run on both macOS and iOS platforms
//

#if os(macOS) || os(iOS) || os(visionOS)
import Foundation
import Testing
import CoreGraphics

@testable import SwiftTerm

@Suite(.serialized)
final class AppleIMESupportTests {

    // MARK: - IMEUtils.cellWidth Tests

    /// Test cell width calculation for ASCII characters
    @Test func testCellWidthASCII() {
        let width = IMEUtils.cellWidth(for: "abc")
        #expect(width == 3, "ASCII string 'abc' should have width 3")
    }

    /// Test cell width calculation for Korean characters
    @Test func testCellWidthKorean() {
        let width = IMEUtils.cellWidth(for: "한글")
        #expect(width == 4, "Korean string '한글' should have width 4 (2 + 2)")
    }

    /// Test cell width calculation for Japanese Hiragana
    @Test func testCellWidthJapanese() {
        let width = IMEUtils.cellWidth(for: "あいう")
        #expect(width == 6, "Japanese hiragana 'あいう' should have width 6 (2 + 2 + 2)")
    }

    /// Test cell width calculation for Chinese characters
    @Test func testCellWidthChinese() {
        let width = IMEUtils.cellWidth(for: "中文")
        #expect(width == 4, "Chinese string '中文' should have width 4 (2 + 2)")
    }

    /// Test cell width calculation for mixed content
    @Test func testCellWidthMixed() {
        let width = IMEUtils.cellWidth(for: "한a글")
        #expect(width == 5, "Mixed string '한a글' should have width 5 (2 + 1 + 2)")
    }

    /// Test cell width calculation for empty string
    @Test func testCellWidthEmpty() {
        let width = IMEUtils.cellWidth(for: "")
        #expect(width == 0, "Empty string should have width 0")
    }

    /// Test cell width calculation for single characters
    @Test func testCellWidthSingleCharacters() {
        let testCases: [(String, Int)] = [
            ("a", 1),   // ASCII
            ("한", 2),  // Korean
            ("あ", 2),  // Japanese Hiragana
            ("中", 2),  // Chinese
            ("!", 1),   // Punctuation
            ("1", 1),   // Digit
        ]

        for (char, expectedWidth) in testCases {
            let width = IMEUtils.cellWidth(for: char)
            #expect(width == expectedWidth, "Character '\(char)' should have width \(expectedWidth), got \(width)")
        }
    }

    // MARK: - IMEUtils.adjustedCursorColumn Tests

    /// Test cursor column when no tracking (lastBufferX = -1)
    @Test func testAdjustedCursorColumnNoTracking() {
        let col = IMEUtils.adjustedCursorColumn(
            currentBufferX: 10,
            lastBufferX: -1,
            lastInsertWidth: 0
        )
        #expect(col == 10, "With no tracking, should return currentBufferX")
    }

    /// Test cursor column with echo delay compensation
    @Test func testAdjustedCursorColumnWithEchoDelay() {
        // Scenario: inserted "한" (width 2) at position 5, buffer.x hasn't updated yet
        let col = IMEUtils.adjustedCursorColumn(
            currentBufferX: 5,
            lastBufferX: 5,
            lastInsertWidth: 2
        )
        #expect(col == 7, "Should compensate for echo delay: 5 + 2 = 7")
    }

    /// Test cursor column when buffer has already updated
    @Test func testAdjustedCursorColumnBufferUpdated() {
        // Scenario: inserted text at position 5, buffer.x already moved to 7
        let col = IMEUtils.adjustedCursorColumn(
            currentBufferX: 7,
            lastBufferX: 5,
            lastInsertWidth: 2
        )
        #expect(col == 7, "When buffer updated, should return currentBufferX directly")
    }

    // MARK: - IMEUtils.calculateOverlayFrame Tests

    /// Test overlay frame calculation for macOS (flipped Y)
    @Test func testCalculateOverlayFrameMacOS() {
        let frame = IMEUtils.calculateOverlayFrame(
            for: "한",
            cursorRow: 0,
            currentBufferX: 0,
            lastBufferX: -1,
            lastInsertWidth: 0,
            cellDimension: CGSize(width: 10, height: 20),
            frameHeight: 400,
            flipY: true
        )

        #expect(frame.origin.x == 0, "X should be at column 0")
        #expect(frame.origin.y == 380, "Y should be flipped: 400 - (0 + 1) * 20 = 380")
        #expect(frame.size.width == 20, "Width should be 2 cells * 10 = 20")
        #expect(frame.size.height == 20, "Height should be 1 cell = 20")
    }

    /// Test overlay frame calculation for iOS (non-flipped Y)
    @Test func testCalculateOverlayFrameiOS() {
        let frame = IMEUtils.calculateOverlayFrame(
            for: "한",
            cursorRow: 0,
            currentBufferX: 0,
            lastBufferX: -1,
            lastInsertWidth: 0,
            cellDimension: CGSize(width: 10, height: 20),
            frameHeight: 400,
            flipY: false
        )

        #expect(frame.origin.x == 0, "X should be at column 0")
        #expect(frame.origin.y == 0, "Y should be at row 0 (non-flipped)")
        #expect(frame.size.width == 20, "Width should be 2 cells * 10 = 20")
        #expect(frame.size.height == 20, "Height should be 1 cell = 20")
    }

    /// Test overlay frame with cursor at non-zero position
    @Test func testCalculateOverlayFrameWithOffset() {
        let frame = IMEUtils.calculateOverlayFrame(
            for: "abc",
            cursorRow: 5,
            currentBufferX: 10,
            lastBufferX: -1,
            lastInsertWidth: 0,
            cellDimension: CGSize(width: 8, height: 16),
            frameHeight: 480,
            flipY: false
        )

        #expect(frame.origin.x == 80, "X should be 10 * 8 = 80")
        #expect(frame.origin.y == 80, "Y should be 5 * 16 = 80")
        #expect(frame.size.width == 24, "Width should be 3 cells * 8 = 24")
        #expect(frame.size.height == 16, "Height should be 1 cell = 16")
    }

    /// Test overlay frame with echo delay compensation
    @Test func testCalculateOverlayFrameWithEchoDelay() {
        let frame = IMEUtils.calculateOverlayFrame(
            for: "글",
            cursorRow: 0,
            currentBufferX: 5,
            lastBufferX: 5,
            lastInsertWidth: 2,
            cellDimension: CGSize(width: 10, height: 20),
            frameHeight: 400,
            flipY: false
        )

        // X should be adjusted: (5 + 2) * 10 = 70
        #expect(frame.origin.x == 70, "X should compensate for echo delay: (5 + 2) * 10 = 70")
    }

    // MARK: - Integration Tests

    /// Test complete Korean composition scenario
    @Test func testKoreanCompositionScenario() {
        // Simulating: typing "한글" at cursor position (0, 0)
        let cellDim = CGSize(width: 10, height: 20)
        let frameHeight: CGFloat = 400

        // Step 1: Type "ㅎ" (composing)
        let frame1 = IMEUtils.calculateOverlayFrame(
            for: "ㅎ",
            cursorRow: 0,
            currentBufferX: 0,
            lastBufferX: -1,
            lastInsertWidth: 0,
            cellDimension: cellDim,
            frameHeight: frameHeight,
            flipY: false
        )
        #expect(frame1.size.width == 20, "Composing 'ㅎ' should occupy 2 cells")

        // Step 2: "ㅎ" → "하" (still composing)
        let frame2 = IMEUtils.calculateOverlayFrame(
            for: "하",
            cursorRow: 0,
            currentBufferX: 0,
            lastBufferX: -1,
            lastInsertWidth: 0,
            cellDimension: cellDim,
            frameHeight: frameHeight,
            flipY: false
        )
        #expect(frame2.size.width == 20, "Composing '하' should occupy 2 cells")

        // Step 3: "하" → "한" (still composing)
        let frame3 = IMEUtils.calculateOverlayFrame(
            for: "한",
            cursorRow: 0,
            currentBufferX: 0,
            lastBufferX: -1,
            lastInsertWidth: 0,
            cellDimension: cellDim,
            frameHeight: frameHeight,
            flipY: false
        )
        #expect(frame3.size.width == 20, "Composing '한' should occupy 2 cells")
    }

    /// Test mixed language composition scenario
    @Test func testMixedLanguageScenario() {
        let testCases: [(String, Int)] = [
            ("Hello", 5),      // English only
            ("안녕", 4),       // Korean only
            ("Hi안녕", 6),     // Mixed: 2 + 4
            ("123한글", 7),    // Numbers + Korean: 3 + 4
        ]

        for (text, expectedCells) in testCases {
            let width = IMEUtils.cellWidth(for: text)
            #expect(width == expectedCells, "'\(text)' should be \(expectedCells) cells, got \(width)")
        }
    }

    // MARK: - Unicode Normalization Tests

    /// Test that NFD (decomposed) Korean is properly handled
    @Test func testNFDKoreanNormalization() {
        // NFD decomposed "아" = ㅇ (U+110B) + ㅏ (U+1161)
        let nfdAh = "\u{110B}\u{1161}"  // Decomposed "아"
        let nfcAh = "아"  // Precomposed "아"

        // Verify NFC normalization works
        let normalized = nfdAh.precomposedStringWithCanonicalMapping
        #expect(normalized == nfcAh, "NFD should normalize to NFC: got '\(normalized)'")

        // After normalization, width should be same
        #expect(IMEUtils.cellWidth(for: normalized) == IMEUtils.cellWidth(for: nfcAh),
                "Normalized NFD and NFC Korean should have same cell width")
    }

    /// Test that Korean text sent to terminal is properly normalized
    @Test func testKoreanInputNormalization() {
        // Simulating IME input that might be in NFD form
        let possibleNFD = "아하"  // This could be NFD or NFC depending on IME
        let normalized = possibleNFD.precomposedStringWithCanonicalMapping

        // Width should be 4 (2 + 2) for both forms
        #expect(IMEUtils.cellWidth(for: normalized) == 4,
                "Normalized '아하' should be 4 cells")

        // Verify the string is in NFC form (single characters, not jamo)
        #expect(normalized.count == 2, "NFC '아하' should be 2 characters")
    }

    /// Test decomposed vs composed Korean width calculation
    @Test func testDecomposedKoreanWidth() {
        // "한" decomposed into individual jamo
        let decomposedHan = "\u{1112}\u{1161}\u{11AB}"  // ㅎ + ㅏ + ㄴ
        let composedHan = "한"

        // Cell width should be 2 for composed form
        #expect(IMEUtils.cellWidth(for: composedHan) == 2,
                "Composed '한' should be 2 cells")

        // Normalize and verify
        let normalized = decomposedHan.precomposedStringWithCanonicalMapping
        #expect(normalized == composedHan, "Decomposed 한 should normalize to composed 한")
    }
}

#endif
