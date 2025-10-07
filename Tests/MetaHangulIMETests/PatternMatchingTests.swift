//
//  PatternMatchingTests.swift
//  MetaHangulIME
//
//  Tests for pattern matching functionality in automata
//

import XCTest
@testable import MetaHangulIME

final class PatternMatchingTests: XCTestCase {
    // MARK: - String pythonSlice Tests

    func testPythonSliceBasic() {
        let str = "ㄱㄴㄷ"

        // Full string
        XCTAssertEqual(str.pythonSlice(start: nil, end: nil), "ㄱㄴㄷ")

        // Positive indices
        XCTAssertEqual(str.pythonSlice(start: 0, end: 2), "ㄱㄴ")
        XCTAssertEqual(str.pythonSlice(start: 1, end: 3), "ㄴㄷ")

        // Negative indices
        XCTAssertEqual(str.pythonSlice(start: -1, end: nil), "ㄷ")
        XCTAssertEqual(str.pythonSlice(start: -2, end: nil), "ㄴㄷ")
        XCTAssertEqual(str.pythonSlice(start: 0, end: -1), "ㄱㄴ")
        XCTAssertEqual(str.pythonSlice(start: 0, end: -2), "ㄱ")

        // Mixed
        XCTAssertEqual(str.pythonSlice(start: 1, end: -1), "ㄴ")
    }

    func testPythonSliceEdgeCases() {
        let str = "ㄱ"

        XCTAssertEqual(str.pythonSlice(start: 0, end: -1), "")
        XCTAssertEqual(str.pythonSlice(start: -1, end: nil), "ㄱ")

        let empty = ""
        XCTAssertEqual(empty.pythonSlice(start: nil, end: nil), "")
    }

    // MARK: - Automaton Pattern Tests

    func testFromPatternExactMatch() {
        let automaton = Automaton()

        let pattern = automaton.parseFromPattern("ㅏ")

        XCTAssertTrue(pattern.isExact)
        XCTAssertEqual(pattern.suffix, "ㅏ")
        XCTAssertEqual(pattern.captureMin, 0)
        XCTAssertEqual(pattern.captureMax, 0)

        // Should match exact
        XCTAssertEqual(pattern.match(state: "ㅏ"), "")

        // Should not match
        XCTAssertNil(pattern.match(state: "ㅓ"))
        XCTAssertNil(pattern.match(state: "ㄱㅏ"))
    }

    func testFromPatternPrefixCapture() {
        let automaton = Automaton()

        // {:3}ㅅ - 0~3 chars + "ㅅ"
        let pattern = automaton.parseFromPattern("{:3}ㅅ")

        XCTAssertFalse(pattern.isExact)
        XCTAssertEqual(pattern.suffix, "ㅅ")
        XCTAssertEqual(pattern.captureMin, 0)
        XCTAssertEqual(pattern.captureMax, 3)

        // Should match with capture
        XCTAssertEqual(pattern.match(state: "ㅅ"), "")  // 0 chars + ㅅ
        XCTAssertEqual(pattern.match(state: "ㄱㅅ"), "ㄱ")  // 1 char + ㅅ
        XCTAssertEqual(pattern.match(state: "ㄱㄴㅅ"), "ㄱㄴ")  // 2 chars + ㅅ
        XCTAssertEqual(pattern.match(state: "ㄱㄴㄷㅅ"), "ㄱㄴㄷ")  // 3 chars + ㅅ

        // Should not match (too many prefix chars)
        XCTAssertNil(pattern.match(state: "ㄱㄴㄷㄹㅅ"))  // 4 chars + ㅅ

        // Should not match (wrong suffix)
        XCTAssertNil(pattern.match(state: "ㄱㄴㄷ"))
        XCTAssertNil(pattern.match(state: "ㄱㄴㅁ"))
    }

    func testFromPatternMinMaxRange() {
        let automaton = Automaton()

        // {1:2}ㅏ - 1~2 chars + "ㅏ"
        let pattern = automaton.parseFromPattern("{1:2}ㅏ")

        XCTAssertEqual(pattern.captureMin, 1)
        XCTAssertEqual(pattern.captureMax, 2)

        // Should not match (too few)
        XCTAssertNil(pattern.match(state: "ㅏ"))  // 0 chars

        // Should match
        XCTAssertEqual(pattern.match(state: "ㄱㅏ"), "ㄱ")  // 1 char
        XCTAssertEqual(pattern.match(state: "ㄱㄴㅏ"), "ㄱㄴ")  // 2 chars

        // Should not match (too many)
        XCTAssertNil(pattern.match(state: "ㄱㄴㄷㅏ"))  // 3 chars
    }

    func testToPatternLiteral() {
        let automaton = Automaton()

        let pattern = automaton.parseToPattern("ㅅ")

        XCTAssertTrue(pattern.isSimple)
        XCTAssertEqual(pattern.apply(captured: "anything"), "ㅅ")
    }

    func testToPatternCaptureSlice() {
        let automaton = Automaton()

        // {-1} - last character
        let pattern1 = automaton.parseToPattern("{-1}")
        XCTAssertEqual(pattern1.apply(captured: "ㄱㄴㄷ"), "ㄷ")

        // {:2} - first 2 characters
        let pattern2 = automaton.parseToPattern("{:2}")
        XCTAssertEqual(pattern2.apply(captured: "ㄱㄴㄷ"), "ㄱㄴ")

        // {0:-1} - all except last
        let pattern3 = automaton.parseToPattern("{0:-1}")
        XCTAssertEqual(pattern3.apply(captured: "ㄱㄴㄷ"), "ㄱㄴ")

        // {:} - full capture
        let pattern4 = automaton.parseToPattern("{:}")
        XCTAssertEqual(pattern4.apply(captured: "ㄱㄴㄷ"), "ㄱㄴㄷ")
    }

    func testToPatternComplex() {
        let automaton = Automaton()

        // {-1}ㅅ - last char + "ㅅ"
        let pattern1 = automaton.parseToPattern("{-1}ㅅ")
        XCTAssertEqual(pattern1.apply(captured: "ㄱㄴㄷ"), "ㄷㅅ")

        // {:2}ㅏ{-1} - first 2 + "ㅏ" + last
        let pattern2 = automaton.parseToPattern("{:2}ㅏ{-1}")
        XCTAssertEqual(pattern2.apply(captured: "ㄱㄴㄷ"), "ㄱㄴㅏㄷ")

        // {0:-1}ㅎ - all except last + "ㅎ"
        let pattern3 = automaton.parseToPattern("{0:-1}ㅎ")
        XCTAssertEqual(pattern3.apply(captured: "ㄱㄴㄷ"), "ㄱㄴㅎ")
    }

    // MARK: - Automaton Transition Tests

    func testAutomatonExactTransition() {
        let automaton = ChoseongAutomaton()

        automaton.addTransition(from: "", input: "ㄱ", to: "ㄱ")
        automaton.addTransition(from: "ㄱ", input: "ㄱ", to: "ㄲ")

        let result1 = automaton.transition(currentState: "", inputKey: "ㄱ")
        XCTAssertEqual(result1?.toState, "ㄱ")

        let result2 = automaton.transition(currentState: "ㄱ", inputKey: "ㄱ")
        XCTAssertEqual(result2?.toState, "ㄲ")
    }

    func testAutomatonPatternTransition() {
        let automaton = JongseongAutomaton()

        // Exact transition
        automaton.addTransition(from: "ㄹ", input: "ㄱ", to: "ㄺ")

        // Pattern transition: any 1~2 char prefix + "ㄹ" → prefix + "ㄹㄱ"
        automaton.addTransition(from: "{1:2}ㄹ", input: "ㄱ", to: "{:}ㄹㄱ")

        // Exact match should work
        let result1 = automaton.transition(currentState: "ㄹ", inputKey: "ㄱ")
        XCTAssertEqual(result1?.toState, "ㄺ")

        // Pattern match: "ㄱㄹ" + ㄱ → "ㄱㄹㄱ"
        let result2 = automaton.transition(currentState: "ㄱㄹ", inputKey: "ㄱ")
        XCTAssertEqual(result2?.toState, "ㄱㄹㄱ")

        // Pattern match: "ㄴㄷㄹ" + ㄱ → "ㄴㄷㄹㄱ" (2 chars prefix matches)
        let result3 = automaton.transition(currentState: "ㄴㄷㄹ", inputKey: "ㄱ")
        XCTAssertEqual(result3?.toState, "ㄴㄷㄹㄱ")

        // Should not match: "ㄴㄷㄹㅁㄹ" (4 chars prefix, exceeds max)
        let result4 = automaton.transition(currentState: "ㄴㄷㄹㅁㄹ", inputKey: "ㄱ")
        XCTAssertNil(result4)
    }

    // MARK: - DokkaebiAutomaton Pattern Tests

    func testDokkaebiExactMatch() {
        let dokkaebibul = DokkaebiAutomaton()

        dokkaebibul.addJungseongTransition(
            jongseongState: "ㄳ",
            remainingJong: "ㄱ",
            movedCho: "ㅅ"
        )

        let result = dokkaebibul.processJungseongDokkaebi("ㄳ")
        XCTAssertTrue(result.shouldSplit)
        XCTAssertEqual(result.remainingJongseongState, "ㄱ")
        XCTAssertEqual(result.movedChoseongState, "ㅅ")
    }

    func testDokkaebiPatternMatch() {
        let dokkaebibul = DokkaebiAutomaton()

        // Pattern: 0~3 chars + "ㅅ" → remaining: prefix, moved: last char
        dokkaebibul.addJungseongTransition(
            jongseongState: "{:3}ㅅ",
            remainingJong: "{:3}",
            movedCho: "{-1}"
        )

        // "ㄱㄴㅅ" → remaining: "ㄱㄴ", moved: "ㄴ"
        let result1 = dokkaebibul.processJungseongDokkaebi("ㄱㄴㅅ")
        XCTAssertTrue(result1.shouldSplit)
        XCTAssertEqual(result1.remainingJongseongState, "ㄱㄴ")
        XCTAssertEqual(result1.movedChoseongState, "ㄴ")

        // "ㅅ" → remaining: "" (empty = nil), moved: ""
        let result2 = dokkaebibul.processJungseongDokkaebi("ㅅ")
        XCTAssertTrue(result2.shouldSplit)
        XCTAssertNil(result2.remainingJongseongState)  // empty string → nil
        XCTAssertEqual(result2.movedChoseongState, "")
    }

    func testDokkaebiPatternMatchComplex() {
        let dokkaebibul = DokkaebiAutomaton()

        // Pattern: any length → remaining: all except last, moved: last + "ㅅ"
        dokkaebibul.addJungseongTransition(
            jongseongState: "{:}",
            remainingJong: "{0:-1}",
            movedCho: "{-1}ㅅ"
        )

        // "ㄱㄴㄷ" → remaining: "ㄱㄴ", moved: "ㄷㅅ"
        let result = dokkaebibul.processJungseongDokkaebi("ㄱㄴㄷ")
        XCTAssertTrue(result.shouldSplit)
        XCTAssertEqual(result.remainingJongseongState, "ㄱㄴ")
        XCTAssertEqual(result.movedChoseongState, "ㄷㅅ")
    }

    func testDokkaebiChoseongPattern() {
        let dokkaebibul = DokkaebiAutomaton()

        // Pattern: 0~2 chars + "ㅌ" + input "ㅌ" → remaining: prefix, moved: "ㄸ"
        dokkaebibul.addChoseongTransition(
            jongseongState: "{0:2}ㅌ",
            inputKey: "ㅌ",
            remainingJong: "{:}",
            movedCho: "ㄸ"
        )

        // "ㅌ" + "ㅌ" → remaining: "", moved: "ㄸ"
        let result1 = dokkaebibul.processChoseongDokkaebi("ㅌ", inputKey: "ㅌ")
        XCTAssertTrue(result1.shouldSplit)
        XCTAssertNil(result1.remainingJongseongState)  // empty → nil
        XCTAssertEqual(result1.movedChoseongState, "ㄸ")

        // "ㄱㅌ" + "ㅌ" → remaining: "ㄱ", moved: "ㄸ"
        let result2 = dokkaebibul.processChoseongDokkaebi("ㄱㅌ", inputKey: "ㅌ")
        XCTAssertTrue(result2.shouldSplit)
        XCTAssertEqual(result2.remainingJongseongState, "ㄱ")
        XCTAssertEqual(result2.movedChoseongState, "ㄸ")
    }

    // MARK: - BackspaceAutomaton Pattern Tests

    func testBackspaceExactMatch() {
        let backspace = BackspaceAutomaton()

        backspace.addTransition(from: "ㄲ", to: "ㄱ")
        backspace.addTransition(from: "ㄳ", to: "ㄱ")

        let result1 = backspace.process("ㄲ")
        XCTAssertEqual(result1.newState, "ㄱ")

        let result2 = backspace.process("ㄳ")
        XCTAssertEqual(result2.newState, "ㄱ")

        // No transition defined → complete deletion
        let result3 = backspace.process("ㄱ")
        XCTAssertNil(result3.newState)
    }

    func testBackspacePatternMatch() {
        let backspace = BackspaceAutomaton()

        // Pattern: 1~3 chars + "ㅅ" → remove last char
        backspace.addTransition(from: "{1:3}ㅅ", to: "{0:-1}ㅅ")

        // "ㄱㅅ" → "ㅅ"
        let result1 = backspace.process("ㄱㅅ")
        XCTAssertEqual(result1.newState, "ㅅ")

        // "ㄱㄴㅅ" → "ㄱㅅ"
        let result2 = backspace.process("ㄱㄴㅅ")
        XCTAssertEqual(result2.newState, "ㄱㅅ")

        // "ㄱㄴㄷㅅ" → "ㄱㄴㅅ"
        let result3 = backspace.process("ㄱㄴㄷㅅ")
        XCTAssertEqual(result3.newState, "ㄱㄴㅅ")

        // "ㄱㄴㄷㄹㅅ" should not match (4 chars, exceeds max)
        let result4 = backspace.process("ㄱㄴㄷㄹㅅ")
        XCTAssertNil(result4.newState)  // No match → complete deletion
    }

    // MARK: - Integration Tests

    func testPatternPriority() {
        let automaton = ChoseongAutomaton()

        // Exact match should take priority over pattern match
        automaton.addTransition(from: "ㄱ", input: "ㄱ", to: "ㄲ")  // Exact
        automaton.addTransition(from: "{:2}", input: "ㄱ", to: "{:}ㄱㄱ")  // Pattern

        // Should use exact match
        let result = automaton.transition(currentState: "ㄱ", inputKey: "ㄱ")
        XCTAssertEqual(result?.toState, "ㄲ")
    }

    func testEmptyCaptureHandling() {
        let automaton = Automaton()

        // Empty capture scenario
        let pattern = automaton.parseToPattern("{:3}")

        XCTAssertEqual(pattern.apply(captured: ""), "")
        XCTAssertEqual(pattern.apply(captured: "ㄱ"), "ㄱ")
    }

    func testDokkaebiEmptyRemainingToNil() {
        let dokkaebibul = DokkaebiAutomaton()

        // 사용자 요청 케이스: {:1}ㄷ 패턴에서 "ㄷ" 매치 시 remaining = "" → nil
        dokkaebibul.addChoseongTransition(
            jongseongState: "{:1}ㄷ",
            inputKey: "ㄷ",
            remainingJong: "{:}",  // captured prefix 전체 = ""
            movedCho: "ㄸ"
        )

        // "ㄷ" + "ㄷ" → prefix="" → remaining:nil (종성이 완전히 제거됨)
        let result1 = dokkaebibul.processChoseongDokkaebi("ㄷ", inputKey: "ㄷ")
        XCTAssertTrue(result1.shouldSplit)
        XCTAssertNil(result1.remainingJongseongState)  // ✅ empty string → nil
        XCTAssertEqual(result1.movedChoseongState, "ㄸ")

        // "ㄱㄷ" + "ㄷ" → prefix="ㄱ" → remaining:"ㄱ" (종성 일부 유지)
        let result2 = dokkaebibul.processChoseongDokkaebi("ㄱㄷ", inputKey: "ㄷ")
        XCTAssertTrue(result2.shouldSplit)
        XCTAssertEqual(result2.remainingJongseongState, "ㄱ")
        XCTAssertEqual(result2.movedChoseongState, "ㄸ")

        // "ㄱㄴㄷ" → 범위 초과로 매칭 실패
        let result3 = dokkaebibul.processChoseongDokkaebi("ㄱㄴㄷ", inputKey: "ㄷ")
        XCTAssertFalse(result3.shouldSplit)
    }
}
