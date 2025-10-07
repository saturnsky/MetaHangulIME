//
//  StringExtensions.swift
//  MetaHangulIME
//
//  String utility extensions for pattern matching
//

import Foundation

extension String {
    /// Python-style slicing with negative index support
    /// - Parameters:
    ///   - start: Start index (nil = 0, negative = from end)
    ///   - end: End index (nil = count, negative = from end)
    /// - Returns: Sliced substring
    ///
    /// Examples:
    /// - "ㄱㄴㄷ".pythonSlice(start: nil, end: nil) → "ㄱㄴㄷ"
    /// - "ㄱㄴㄷ".pythonSlice(start: 0, end: -1) → "ㄱㄴ"
    /// - "ㄱㄴㄷ".pythonSlice(start: -1, end: nil) → "ㄷ"
    /// - "ㄱㄴㄷ".pythonSlice(start: 1, end: 2) → "ㄴ"
    func pythonSlice(start: Int?, end: Int?) -> String {
        let count = self.count

        // 인덱스 정규화
        let startIdx = start.map { $0 >= 0 ? $0 : max(0, count + $0) } ?? 0
        let endIdx = end.map { $0 >= 0 ? $0 : max(0, count + $0) } ?? count

        // 범위 검증
        guard startIdx <= endIdx, startIdx < count else { return "" }

        let actualEnd = min(endIdx, count)

        // String indexing
        let si = index(startIndex, offsetBy: startIdx)
        let ei = index(startIndex, offsetBy: actualEnd)

        return String(self[si..<ei])
    }
}
