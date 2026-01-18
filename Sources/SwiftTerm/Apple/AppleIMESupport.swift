//
//  AppleIMESupport.swift
//
//  Shared IME composition support for iOS and macOS terminal views
//
//  Created by Claude Code on 2026-01-17.
//

#if os(macOS) || os(iOS) || os(visionOS)
import Foundation
import CoreGraphics

// MARK: - IME Utility Functions

/// Utility functions for IME composition - shared between iOS and macOS
enum IMEUtils {

    /// Calculates the display width in terminal cells for a string
    /// Uses Unicode East Asian Width for accurate CJK character handling
    /// - Parameter text: The text to measure
    /// - Returns: Width in terminal cells
    static func cellWidth(for text: String) -> Int {
        var width = 0
        for scalar in text.unicodeScalars {
            let w = UnicodeUtil.columnWidth(rune: scalar)
            width += max(w, 1)  // At least 1 for printable characters
        }
        return width
    }

    /// Calculates the cursor column considering echo delay compensation
    /// - Parameters:
    ///   - currentBufferX: Current terminal buffer X position
    ///   - lastBufferX: Buffer X position at last insert
    ///   - lastInsertWidth: Width of the last inserted text
    /// - Returns: Adjusted cursor column
    static func adjustedCursorColumn(
        currentBufferX: Int,
        lastBufferX: Int,
        lastInsertWidth: Int
    ) -> Int {
        // If buffer.x hasn't changed since last insert, add the insert width
        // This compensates for echo delay in terminal emulators
        if lastBufferX >= 0 && currentBufferX == lastBufferX {
            return lastBufferX + lastInsertWidth
        }
        return currentBufferX
    }

    /// Calculates the IME overlay frame
    /// - Parameters:
    ///   - text: The composition text
    ///   - cursorRow: Terminal buffer Y position
    ///   - currentBufferX: Current terminal buffer X position
    ///   - lastBufferX: Buffer X position at last insert (-1 if not tracking)
    ///   - lastInsertWidth: Width of the last inserted text
    ///   - cellDimension: Cell size (width, height)
    ///   - frameHeight: Container frame height
    ///   - flipY: Whether to flip Y coordinate (macOS uses flipped coordinates)
    /// - Returns: The calculated frame for the IME overlay
    static func calculateOverlayFrame(
        for text: String,
        cursorRow: Int,
        currentBufferX: Int,
        lastBufferX: Int,
        lastInsertWidth: Int,
        cellDimension: CGSize,
        frameHeight: CGFloat,
        flipY: Bool
    ) -> CGRect {
        let cursorCol = adjustedCursorColumn(
            currentBufferX: currentBufferX,
            lastBufferX: lastBufferX,
            lastInsertWidth: lastInsertWidth
        )

        let cellCount = cellWidth(for: text)
        let x = CGFloat(cursorCol) * cellDimension.width
        let y: CGFloat

        if flipY {
            // macOS: origin at bottom-left
            y = frameHeight - CGFloat(cursorRow + 1) * cellDimension.height
        } else {
            // iOS: origin at top-left
            y = CGFloat(cursorRow) * cellDimension.height
        }

        return CGRect(
            x: x,
            y: y,
            width: cellDimension.width * CGFloat(cellCount),
            height: cellDimension.height
        )
    }
}

#endif
