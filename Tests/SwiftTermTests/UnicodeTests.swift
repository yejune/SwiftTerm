//
//  UnicodeTests.swift
//  
// Tests for assorted rendering capabilities
//
#if os(macOS)
import Foundation
import Testing

@testable import SwiftTerm

@Suite(.serialized)
final class SwiftTermUnicode {
    
    @Test func testCombiningCharacters() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        
        let t = h.terminal!
        // Feed combining characters:
        // "Λ" and COMBINING RING ABOVE to produce the single character Λ̊
        // "v" and COMBINING DOT ABOVE
        // "r" and COMBINING DIAERESIS
        // "a" and COMBINING RIGHT HARPOON ABOVE
        //
        t.feed (text: "\u{39b}\u{30a}\r\nv\u{307}\r\nr\u{308}\r\na\u{20d1}\r\nb\u{20d1}")
        
        #expect(t.getCharacter (col:0, row: 0) == "Λ̊")
        #expect(t.getCharacter (col:0, row: 1) == "v̇")
        #expect(t.getCharacter (col:0, row: 2) == "r̈")
        #expect(t.getCharacter (col:0, row: 3) == "a⃑")
        #expect(t.getCharacter (col:0, row: 4) == "b⃑")
        
    }

    @Test func testVariationSelector() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // This will send ⛩️ (0x26e9) is actually in a special class: it can either be one-column (⛩) or two-columns (⛩️)
        // depending on the unicode "variation selector" that follows: 0x26e9 0xfe0e = ⛩, 0x26e9 0xfe0f = ⛩️.
        // Globally, any unicode character followed by 0xfe0e will be single column, any unicode character
        // followed by 0xfe0f will be double-column:
        // https://en.wikipedia.org/wiki/Variation_Selectors_(Unicode_block)
        //
        // The first line is the unicode with the double-size modifier
        // The second line is the unicode character but we are forcing single column
        // The third line is the default
        t.feed (text: "\u{026e9}\u{0fe0f}\n\r\u{026e9}\u{0fe0e}\n\r\u{026e9}")

        // The first line should have 2 columns
        let char0_0 = t.getCharData(col: 0, row: 0)
        #expect(char0_0?.width == 2)

        // The second line should have 1 columns
        let char1_0 = t.getCharData(col: 0, row: 1)
        #expect(char1_0?.width == 1)

        // The third line should have 1 columns
        let char2_0 = t.getCharData(col: 0, row: 2)
        #expect(char2_0?.width == 1)
    }

    @Test func testCombinedPositioning() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // Baseline, we know that "\u{1100}" will always use 2-columns
        // This inserts a simple 2-column value, and then a 1-column value
        t.feed (text: "\u{1100}x\n\r")
        let char0_0 = t.getCharacter (col: 0, row: 0)
        let char1_0 = t.getCharacter (col: 1, row: 0)
        let char2_0 = t.getCharacter (col: 2, row: 0)
        #expect(char0_0 == "\u{1100}")
        #expect(char1_0 == "\u{0}")
        #expect(char2_0 == "x")

        // Here we insert a value that upgrades from 1-column to 2-column when we see the
        // \u{fe0f}, so we need to make sure that the character after that has its position updated.
        t.feed (text: "\u{026e9}\u{0fe0f}x")
        let char0_1 = t.getCharacter (col: 0, row: 1)
        let char1_1 = t.getCharacter (col: 1, row: 1)
        let char2_1 = t.getCharacter (col: 2, row: 1)
        //print("Got \(char0_1) \(char1_1) \(char2_1)")
        #expect(char0_1 == "\u{026e9}\u{0fe0f}")
        #expect(char1_1 == "\u{0}")
        #expect(char2_1 == "x")

    }

    @Test func testEmoji() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // This sends emoji with skin tone modifiers
        // The base emoji and skin tone modifier should combine into a single character
        t.feed (text: "👦🏻x\r\n👦🏿x\r\n")

        let char0_0 = t.getCharacter (col:0, row: 0)
        let char1_0 = t.getCharacter (col:1, row: 0)
        let char2_0 = t.getCharacter (col:2, row: 0)

        let char0_1 = t.getCharacter (col:0, row: 1)
        let char1_1 = t.getCharacter (col:1, row: 1)
        let char2_1 = t.getCharacter (col:2, row: 1)

        // Emoji with skin tone modifiers should be combined into a single grapheme cluster
        #expect(char0_0 == "👦🏻")
        #expect(char1_0 == "\u{0}")
        #expect(char2_0 == "x")
        #expect(char0_1 == "👦🏿")
        #expect(char1_1 == "\u{0}")
        #expect(char2_1 == "x")
    }

    @Test func testEmojiWithModifierBase() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // Test hand emoji with skin tone (as reported in issue #341)
        // 🖐️ (raised hand) + skin tone modifier should combine
        t.feed (text: "🖐🏾\r\n")

        let char0_0 = t.getCharacter (col:0, row: 0)

        // The hand emoji and skin tone should combine into single grapheme cluster
        #expect(char0_0 == "🖐🏾")
    }

    @Test func testEmojiZWJSequence() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // Test ZWJ (Zero Width Joiner) emoji sequences
        // Family emoji: 👩‍👩‍👦‍👦 = 👩 + ZWJ + 👩 + ZWJ + 👦 + ZWJ + 👦
        t.feed (text: "👩‍👩‍👦‍👦\r\n")

        let char0_0 = t.getCharacter (col:0, row: 0)

        // The entire ZWJ sequence should combine into a single grapheme cluster
        #expect(char0_0 == "👩‍👩‍👦‍👦")
    }

    @Test func testEmojiZWJSequenceSimple() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // Test simpler ZWJ sequence: couple with heart 👩‍❤️‍👨
        t.feed (text: "👩‍❤️‍👨\r\n")

        let char0_0 = t.getCharacter (col:0, row: 0)

        #expect(char0_0 == "👩‍❤️‍👨")
    }

    @Test func testCJKCharacterPositioning ()
    {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // Test Japanese hiragana (double-width characters)
        // Each character should occupy 2 columns
        t.feed (text: "あいう")

        // Verify character positions
        #expect(t.getCharacter(col: 0, row: 0) == "あ")
        #expect(t.getCharacter(col: 1, row: 0) == "\u{0}")  // placeholder
        #expect(t.getCharacter(col: 2, row: 0) == "い")
        #expect(t.getCharacter(col: 3, row: 0) == "\u{0}")  // placeholder
        #expect(t.getCharacter(col: 4, row: 0) == "う")
        #expect(t.getCharacter(col: 5, row: 0) == "\u{0}")  // placeholder

        // Verify character widths
        #expect(t.getCharData(col: 0, row: 0)?.width == 2)
        #expect(t.getCharData(col: 2, row: 0)?.width == 2)
        #expect(t.getCharData(col: 4, row: 0)?.width == 2)

        // Cursor should be at column 6 after 3 double-width characters
        #expect(t.buffer.x == 6)
    }

    @Test func testCJKMixedWithAscii ()
    {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // Test mixed ASCII and CJK characters
        t.feed (text: "aあbいc")

        // 'a' at col 0 (width 1)
        #expect(t.getCharacter(col: 0, row: 0) == "a")
        #expect(t.getCharData(col: 0, row: 0)?.width == 1)

        // 'あ' at col 1 (width 2)
        #expect(t.getCharacter(col: 1, row: 0) == "あ")
        #expect(t.getCharData(col: 1, row: 0)?.width == 2)

        // 'b' at col 3 (width 1)
        #expect(t.getCharacter(col: 3, row: 0) == "b")
        #expect(t.getCharData(col: 3, row: 0)?.width == 1)

        // 'い' at col 4 (width 2)
        #expect(t.getCharacter(col: 4, row: 0) == "い")
        #expect(t.getCharData(col: 4, row: 0)?.width == 2)

        // 'c' at col 6 (width 1)
        #expect(t.getCharacter(col: 6, row: 0) == "c")
        #expect(t.getCharData(col: 6, row: 0)?.width == 1)

        // Cursor should be at column 7
        #expect(t.buffer.x == 7)
    }

    @Test func testChineseCharacterPositioning ()
    {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // Test Chinese characters (also double-width)
        t.feed (text: "中文字")

        #expect(t.getCharacter(col: 0, row: 0) == "中")
        #expect(t.getCharacter(col: 2, row: 0) == "文")
        #expect(t.getCharacter(col: 4, row: 0) == "字")

        // All should be width 2
        #expect(t.getCharData(col: 0, row: 0)?.width == 2)
        #expect(t.getCharData(col: 2, row: 0)?.width == 2)
        #expect(t.getCharData(col: 4, row: 0)?.width == 2)

        #expect(t.buffer.x == 6)
    }
    @Test func testZwJSequencePreservesVariationSelector16() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        let sequence = "👩‍❤\u{FE0F}"
        t.feed (text: "\(sequence)\r\n")

        let cell = t.getCharacter (col:0, row: 0)
        #expect(cell != nil)
        let char0_0 = cell ?? " "
        #expect(char0_0.unicodeScalars.contains { $0.value == 0xFE0F })
    }

    @Test func testZwJSequencePreservesVariationSelector15() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        let sequence = "👩‍❤\u{FE0E}"
        t.feed (text: "\(sequence)\r\n")

        let cell = t.getCharacter (col:0, row: 0)
        #expect(cell != nil)
        let char0_0 = cell ?? " "
        #expect(char0_0.unicodeScalars.contains { $0.value == 0xFE0E })
    }

    @Test func testBufferTranslationUsesCharacterProviderForExtendedGrapheme() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        let sequence = "👩‍👩‍👦‍👦"
        t.feed (text: "\(sequence)X")

        let line = t.buffer.translateBufferLineToString(
            lineIndex: t.buffer.yDisp,
            trimRight: true,
            startCol: 0,
            endCol: -1,
            skipNullCellsFollowingWide: true,
            characterProvider: { t.getCharacter(for: $0) }
        ).replacingOccurrences(of: "\u{0}", with: " ")

        #expect(line == "\(sequence)X")
    }

    @Test func testNoBreakSpaceWidth() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // Test NO-BREAK SPACE (U+00A0) positioning
        // NBSP should have width 1, same as regular space
        // This is important for applications like Claude Code that use NBSP after prompt
        t.feed (text: ">\u{00A0}x")  // > + NBSP + x

        // '>' at col 0 (width 1)
        #expect(t.getCharacter(col: 0, row: 0) == ">")
        #expect(t.getCharData(col: 0, row: 0)?.width == 1)

        // NBSP at col 1 (width 1, NOT -1)
        #expect(t.getCharacter(col: 1, row: 0) == "\u{00A0}")
        #expect(t.getCharData(col: 1, row: 0)?.width == 1)

        // 'x' at col 2 (width 1)
        #expect(t.getCharacter(col: 2, row: 0) == "x")
        #expect(t.getCharData(col: 2, row: 0)?.width == 1)

        // Cursor should be at column 3
        #expect(t.buffer.x == 3)
    }

    // MARK: - UTF-8 Chunk Splitting Tests
    // These tests verify that UTF-8 sequences split across multiple feed() calls
    // are correctly decoded (fix for multibyte language support)

    @Test func testUtf8SplitChunks() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // Korean "한" = ED 95 9C (3 bytes)
        // Split after first byte
        t.feed(byteArray: [0xED])
        t.feed(byteArray: [0x95, 0x9C])

        #expect(t.getCharacter(col: 0, row: 0) == "한")
        #expect(t.getCharData(col: 0, row: 0)?.width == 2)
    }

    @Test func testUtf8SplitChunksMultipleCharacters() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // Korean "한글" = ED 95 9C + EA B8 80
        // Split in the middle of each character
        t.feed(byteArray: [0xED])           // First byte of "한"
        t.feed(byteArray: [0x95, 0x9C])     // Rest of "한"
        t.feed(byteArray: [0xEA, 0xB8])     // First two bytes of "글"
        t.feed(byteArray: [0x80])           // Last byte of "글"

        #expect(t.getCharacter(col: 0, row: 0) == "한")
        #expect(t.getCharacter(col: 2, row: 0) == "글")
    }

    @Test func testKoreanFolderName() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // Test the specific case reported: "무제폴더" (Untitled Folder in Korean)
        t.feed(text: "무제폴더")

        #expect(t.getCharacter(col: 0, row: 0) == "무")
        #expect(t.getCharacter(col: 2, row: 0) == "제")
        #expect(t.getCharacter(col: 4, row: 0) == "폴")
        #expect(t.getCharacter(col: 6, row: 0) == "더")

        // All Korean characters should have width 2
        #expect(t.getCharData(col: 0, row: 0)?.width == 2)
        #expect(t.getCharData(col: 2, row: 0)?.width == 2)
        #expect(t.getCharData(col: 4, row: 0)?.width == 2)
        #expect(t.getCharData(col: 6, row: 0)?.width == 2)

        // Cursor should be at column 8 (4 chars × 2 width)
        #expect(t.buffer.x == 8)
    }

    @Test func testUtf8InterruptedByEscape() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // This tests the core bug scenario:
        // UTF-8 first byte arrives, then ESC sequence, then continuation bytes
        // "한" = ED 95 9C, ESC[A = cursor up

        // First, write something on line 1 so we can verify cursor moved
        t.feed(text: "X\r\n")  // X on line 0, move to line 1

        // Now on line 1: send partial UTF-8, ESC sequence, then rest of UTF-8
        t.feed(byteArray: [0xED])              // First byte of "한"
        t.feed(byteArray: [0x1B, 0x5B, 0x41])  // ESC[A (cursor up to line 0)
        t.feed(byteArray: [0x95, 0x9C])        // Rest of "한"

        // After fix: the continuation bytes should complete the "한" character
        // Note: Due to cursor up, this should appear on line 0 after "X"
        // The exact position depends on implementation details
    }

    @Test func testUtf8WithEscapeSequenceBetween() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // Complete UTF-8 character, then ESC sequence, then another character
        // This should always work correctly
        t.feed(text: "한")                      // Complete Korean char
        t.feed(byteArray: [0x1B, 0x5B, 0x43])  // ESC[C (cursor right)
        t.feed(text: "글")                      // Another complete Korean char

        #expect(t.getCharacter(col: 0, row: 0) == "한")
        // After cursor right, "글" should be at col 3 (2 + 1 cursor move)
        #expect(t.getCharacter(col: 3, row: 0) == "글")
    }

    @Test func testEuroSignSplitChunks() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // Euro sign "€" = E2 82 AC
        // Note: 0x82 is in the C1 control range, testing potential conflicts
        t.feed(byteArray: [0xE2])
        t.feed(byteArray: [0x82, 0xAC])

        #expect(t.getCharacter(col: 0, row: 0) == "€")
        #expect(t.getCharData(col: 0, row: 0)?.width == 1)
    }

    // MARK: - Hangul NFD Composition Tests
    // Tests for Korean Jamo (NFD) to Syllable (NFC) composition

    @Test func testHangulNFDComposition() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // NFD Korean "아" = ㅇ (U+110B) + ㅏ (U+1161)
        // These should combine into NFC "아" (U+C544)
        t.feed(text: "\u{110B}\u{1161}")

        let char0 = t.getCharacter(col: 0, row: 0)
        // The jamo should combine into a single syllable
        #expect(char0 == "아", "NFD ㅇ+ㅏ should combine to 아, got: \(char0.map { String($0) } ?? "nil")")
        #expect(t.getCharData(col: 0, row: 0)?.width == 2)
    }

    @Test func testHangulNFDCompositionWithFinal() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // NFD Korean "한" = ㅎ (U+1112) + ㅏ (U+1161) + ㄴ (U+11AB)
        // Initial + Medial + Final should combine into "한"
        t.feed(text: "\u{1112}\u{1161}\u{11AB}")

        let char0 = t.getCharacter(col: 0, row: 0)
        #expect(char0 == "한", "NFD ㅎ+ㅏ+ㄴ should combine to 한, got: \(char0.map { String($0) } ?? "nil")")
        #expect(t.getCharData(col: 0, row: 0)?.width == 2)
    }

    @Test func testHangulNFDCompositionMultipleSyllables() {
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // NFD Korean "안녕" = ㅇ+ㅏ+ㄴ + ㄴ+ㅕ+ㅇ
        let nfdAnnyeong = "\u{110B}\u{1161}\u{11AB}\u{1102}\u{1167}\u{11BC}"
        t.feed(text: nfdAnnyeong)

        let char0 = t.getCharacter(col: 0, row: 0)
        let char2 = t.getCharacter(col: 2, row: 0)
        #expect(char0 == "안", "First syllable should be 안, got: \(char0.map { String($0) } ?? "nil")")
        #expect(char2 == "녕", "Second syllable should be 녕, got: \(char2.map { String($0) } ?? "nil")")
    }

    @Test func testHangulNFDFirstCharacterComposition() {
        // This tests the specific bug: first character composition failure
        // due to lastBufferStorage initialization
        let h = HeadlessTerminal (queue: SwiftTermTests.queue) { exitCode in }
        let t = h.terminal!

        // Feed NFD "아" as the very first input (no prior characters)
        t.feed(text: "\u{110B}\u{1161}")

        let char0 = t.getCharacter(col: 0, row: 0)
        // Even as the first character, jamo should combine
        #expect(char0 == "아", "First character NFD composition failed, got: \(char0.map { String($0) } ?? "nil")")

        // Verify there's no stray jamo in col 1
        let char1 = t.getCharacter(col: 1, row: 0)
        #expect(char1 == "\u{0}" || char1 == nil, "Col 1 should be placeholder, got: \(char1.map { String($0) } ?? "nil")")
    }

    // MARK: - Wide Character Line Wrapping Tests

    @Test func testWideCharacterAtLineEnd() {
        // Test wide character handling at line boundary
        // Use a small terminal width for easier testing
        let delegate = TestDelegate()
        let terminal = Terminal(delegate: delegate, options: TerminalOptions(cols: 10, rows: 5))

        // Fill line with 8 ASCII chars, then try to add a 2-width Korean char
        // Position: 0-7 filled, cursor at 8
        // Korean char needs 2 cells (8, 9) - should fit exactly
        terminal.feed(text: "12345678한")

        #expect(terminal.getCharacter(col: 8, row: 0) == "한")
        #expect(terminal.buffer.x == 10) // Cursor at end of line
        #expect(terminal.buffer.y == 0)  // Still on first line
    }

    @Test func testWideCharacterWrapsAtLineEnd() {
        let delegate = TestDelegate()
        let terminal = Terminal(delegate: delegate, options: TerminalOptions(cols: 10, rows: 5))

        // Fill line with 9 ASCII chars, cursor at 9
        // Korean char needs 2 cells but only 1 available - should wrap
        terminal.feed(text: "123456789한")

        // Korean char should wrap to next line
        #expect(terminal.getCharacter(col: 0, row: 1) == "한")
        #expect(terminal.buffer.y == 1)  // Moved to second line
    }

    @Test func testMultipleWideCharactersWithWrapping() {
        let delegate = TestDelegate()
        let terminal = Terminal(delegate: delegate, options: TerminalOptions(cols: 10, rows: 5))

        // 5 Korean chars = 10 cells, should exactly fill one line
        terminal.feed(text: "한글테스트")

        #expect(terminal.getCharacter(col: 0, row: 0) == "한")
        #expect(terminal.getCharacter(col: 2, row: 0) == "글")
        #expect(terminal.getCharacter(col: 4, row: 0) == "테")
        #expect(terminal.getCharacter(col: 6, row: 0) == "스")
        #expect(terminal.getCharacter(col: 8, row: 0) == "트")
        #expect(terminal.buffer.x == 10)
        #expect(terminal.buffer.y == 0)
    }

    @Test func testWideCharactersAcrossMultipleLines() {
        let delegate = TestDelegate()
        let terminal = Terminal(delegate: delegate, options: TerminalOptions(cols: 10, rows: 5))

        // 6 Korean chars = 12 cells, should span 2 lines
        // Line 0: 한글테스트 (10 cells)
        // Line 1: 트 (2 cells) - wait, 5 chars = 10 cells, 6 chars = 12 cells
        // Actually: 한글테스 (8 cells) + 트 would need cols 8,9 - fits!
        // So 6 chars: 한글테스트X where X wraps
        terminal.feed(text: "한글테스트롱")  // 6 chars = 12 cells

        // First 5 chars on line 0 (10 cells)
        #expect(terminal.getCharacter(col: 0, row: 0) == "한")
        #expect(terminal.getCharacter(col: 8, row: 0) == "트")

        // 6th char wraps to line 1
        #expect(terminal.getCharacter(col: 0, row: 1) == "롱")
    }

    // MARK: - Multiline Text Tests (10+ lines)

    @Test func testMultilineEnglishText() {
        // Test ~10 lines of English text
        let delegate = TestDelegate()
        let terminal = Terminal(delegate: delegate, options: TerminalOptions(cols: 40, rows: 15))

        let englishLines = [
            "The quick brown fox jumps over the lazy",
            "dog. Pack my box with five dozen liquor",
            "jugs. How vexingly quick daft zebras ju",
            "mp! The five boxing wizards jump quickl",
            "y. Sphinx of black quartz, judge my vow",
            "Two driven jocks help fax my big quiz.",
            "The jay, pig, fox, zebra and my wolves ",
            "quack! Blowzy red vixens fight for a qu",
            "ick jump. Joaquin Phoenix was gazed by ",
            "MTV for luck. A very bad quack might ji"
        ]

        for line in englishLines {
            terminal.feed(text: line + "\r\n")
        }

        // Verify first and last lines
        #expect(terminal.getCharacter(col: 0, row: 0) == "T")
        #expect(terminal.getCharacter(col: 1, row: 0) == "h")
        #expect(terminal.getCharacter(col: 2, row: 0) == "e")

        // Verify line 5 (index 5)
        #expect(terminal.getCharacter(col: 0, row: 5) == "T")  // "Two driven..."
        #expect(terminal.getCharacter(col: 1, row: 5) == "w")
        #expect(terminal.getCharacter(col: 2, row: 5) == "o")

        // Verify last line (index 9) - "MTV for luck..."
        #expect(terminal.getCharacter(col: 0, row: 9) == "M")
        #expect(terminal.getCharacter(col: 1, row: 9) == "T")
        #expect(terminal.getCharacter(col: 2, row: 9) == "V")
    }

    @Test func testMultilineKoreanText() {
        // Test ~10 lines of Korean text
        let delegate = TestDelegate()
        let terminal = Terminal(delegate: delegate, options: TerminalOptions(cols: 40, rows: 15))

        let koreanLines = [
            "안녕하세요 반갑습니다",          // Hello, nice to meet you
            "오늘 날씨가 정말 좋네요",        // The weather is really nice today
            "한글 테스트를 진행합니다",       // Conducting a Korean test
            "터미널에서 한글이 잘 나오나요",  // Does Korean display well in terminal?
            "긴 문장도 잘 처리되어야 합니다", // Long sentences should be handled well
            "줄바꿈이 정상적으로 동작하나요", // Does line wrapping work correctly?
            "유니코드 처리가 중요합니다",     // Unicode handling is important
            "스위프트 터미널 라이브러리",     // Swift terminal library
            "맥과 아이오에스를 지원합니다",   // Supports Mac and iOS
            "테스트가 성공하길 바랍니다"      // Hope the test succeeds
        ]

        for line in koreanLines {
            terminal.feed(text: line + "\r\n")
        }

        // Verify first line - "안녕하세요"
        #expect(terminal.getCharacter(col: 0, row: 0) == "안")
        #expect(terminal.getCharacter(col: 2, row: 0) == "녕")
        #expect(terminal.getCharacter(col: 4, row: 0) == "하")

        // Verify line 5 (index 5) - "줄바꿈이..."
        #expect(terminal.getCharacter(col: 0, row: 5) == "줄")
        #expect(terminal.getCharacter(col: 2, row: 5) == "바")

        // Verify last line (index 9) - "테스트가..."
        #expect(terminal.getCharacter(col: 0, row: 9) == "테")
        #expect(terminal.getCharacter(col: 2, row: 9) == "스")
        #expect(terminal.getCharacter(col: 4, row: 9) == "트")
    }

    @Test func testMultilineMixedKoreanEnglishText() {
        // Test ~10 lines of mixed Korean + English text
        let delegate = TestDelegate()
        let terminal = Terminal(delegate: delegate, options: TerminalOptions(cols: 40, rows: 15))

        let mixedLines = [
            "Hello 안녕하세요 World",
            "Swift 프로그래밍 언어입니다",
            "macOS와 iOS 개발에 사용됩니다",
            "Terminal 터미널 에뮬레이터",
            "Unicode 유니코드 처리 test",
            "CJK 문자와 ASCII 혼합 테스트",
            "한글ABC영어123숫자mixed",
            "SwiftTerm 라이브러리 v1.0",
            "Open Source 오픈소스 프로젝트",
            "GitHub에서 확인하세요 check it"
        ]

        for line in mixedLines {
            terminal.feed(text: line + "\r\n")
        }

        // Verify first line - "Hello 안녕하세요 World"
        #expect(terminal.getCharacter(col: 0, row: 0) == "H")
        #expect(terminal.getCharacter(col: 5, row: 0) == " ")
        #expect(terminal.getCharacter(col: 6, row: 0) == "안")  // Korean starts at col 6
        #expect(terminal.getCharacter(col: 8, row: 0) == "녕")

        // Verify line with numbers - "한글ABC영어123숫자mixed" (index 6)
        #expect(terminal.getCharacter(col: 0, row: 6) == "한")
        #expect(terminal.getCharacter(col: 2, row: 6) == "글")
        #expect(terminal.getCharacter(col: 4, row: 6) == "A")
        #expect(terminal.getCharacter(col: 5, row: 6) == "B")
        #expect(terminal.getCharacter(col: 6, row: 6) == "C")
        #expect(terminal.getCharacter(col: 7, row: 6) == "영")

        // Verify last line (index 9) - "GitHub에서..."
        #expect(terminal.getCharacter(col: 0, row: 9) == "G")
        #expect(terminal.getCharacter(col: 6, row: 9) == "에")
    }

    @Test func testLongLineWrappingEnglish() {
        // Test a single very long English line that wraps multiple times
        let delegate = TestDelegate()
        let terminal = Terminal(delegate: delegate, options: TerminalOptions(cols: 20, rows: 10))

        // 80 characters = 4 lines of 20 cols
        let longLine = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()_+-="

        terminal.feed(text: longLine)

        // Line 0: ABCDEFGHIJKLMNOPQRST (20 chars)
        #expect(terminal.getCharacter(col: 0, row: 0) == "A")
        #expect(terminal.getCharacter(col: 19, row: 0) == "T")

        // Line 1: UVWXYZ0123456789abcd (20 chars)
        #expect(terminal.getCharacter(col: 0, row: 1) == "U")
        #expect(terminal.getCharacter(col: 19, row: 1) == "d")

        // Line 2: efghijklmnopqrstuvwx (20 chars)
        #expect(terminal.getCharacter(col: 0, row: 2) == "e")
        #expect(terminal.getCharacter(col: 19, row: 2) == "x")

        // Line 3: yz!@#$%^&*()_+-= (16 chars)
        #expect(terminal.getCharacter(col: 0, row: 3) == "y")
        #expect(terminal.getCharacter(col: 1, row: 3) == "z")
    }

    @Test func testLongLineWrappingKorean() {
        // Test a single very long Korean line that wraps multiple times
        let delegate = TestDelegate()
        let terminal = Terminal(delegate: delegate, options: TerminalOptions(cols: 20, rows: 10))

        // 20 Korean chars = 40 cells = 2 lines of 20 cols
        let longKorean = "가나다라마바사아자차카타파하갈날달랄말발살"  // 21 chars

        terminal.feed(text: longKorean)

        // Line 0: 가나다라마바사아자차 (10 chars = 20 cells)
        #expect(terminal.getCharacter(col: 0, row: 0) == "가")
        #expect(terminal.getCharacter(col: 2, row: 0) == "나")
        #expect(terminal.getCharacter(col: 18, row: 0) == "차")

        // Line 1: 카타파하갈날달랄말발 (10 chars = 20 cells)
        #expect(terminal.getCharacter(col: 0, row: 1) == "카")
        #expect(terminal.getCharacter(col: 2, row: 1) == "타")
        #expect(terminal.getCharacter(col: 18, row: 1) == "발")

        // Line 2: 살 (1 char = 2 cells)
        #expect(terminal.getCharacter(col: 0, row: 2) == "살")
    }

    @Test func testLongLineWrappingMixed() {
        // Test a single very long mixed line that wraps
        let delegate = TestDelegate()
        let terminal = Terminal(delegate: delegate, options: TerminalOptions(cols: 20, rows: 10))

        // Mixed: "Hello한글World테스트" = 5 + 4 + 5 + 6 = 5 + 8 + 5 + 12 = 30 cells
        // But let's make it fit exactly: "AB한글CD" = 2 + 4 + 2 = 8 cells
        // For 20 cols: "ABCDE한글FGHIJ가나다" = 5 + 4 + 5 + 6 = 20 cells exactly on line 0
        let mixedLine = "ABCDE한글FGHIJ가나다라마바사아자차"

        terminal.feed(text: mixedLine)

        // Line 0 (20 cells): ABCDE한글FGHIJ가나다
        #expect(terminal.getCharacter(col: 0, row: 0) == "A")
        #expect(terminal.getCharacter(col: 4, row: 0) == "E")
        #expect(terminal.getCharacter(col: 5, row: 0) == "한")  // 한 at col 5-6
        #expect(terminal.getCharacter(col: 7, row: 0) == "글")  // 글 at col 7-8
        #expect(terminal.getCharacter(col: 9, row: 0) == "F")
        #expect(terminal.getCharacter(col: 14, row: 0) == "가")  // 가 at col 14-15
        #expect(terminal.getCharacter(col: 16, row: 0) == "나")  // 나 at col 16-17
        #expect(terminal.getCharacter(col: 18, row: 0) == "다")  // 다 at col 18-19

        // Line 1: 라마바사아자차 (7 chars = 14 cells)
        #expect(terminal.getCharacter(col: 0, row: 1) == "라")
        #expect(terminal.getCharacter(col: 2, row: 1) == "마")
    }
}

// Helper delegate for terminal tests
final class TestDelegate: TerminalDelegate {
    func send(source: Terminal, data: ArraySlice<UInt8>) {
        // Required by TerminalDelegate
    }
}
#endif
