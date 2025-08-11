//
//  StandardDubeolsikTests.swift
//  MetaHangulIME
//
//  Tests for Standard Dubeolsik IME
//

import XCTest
@testable import MetaHangulIME

final class StandardDubeolsikTests: XCTestCase {
    var ime: StandardDubeolsik!
    var capturedCommitText: String = ""

    override func setUp() {
        super.setUp()
        ime = StandardDubeolsik()
        ime.delegate = self
        capturedCommitText = ""
    }

    override func tearDown() {
        ime = nil
        super.tearDown()
    }

    // MARK: - Basic Syllable Tests

    func testBasicSyllables() {
        let tests: [(keys: [String], expected: String, description: String)] = [
            (["ㄱ", "ㅏ", "ㄴ"], "간", "간"),
            (["ㅎ", "ㅏ", "ㄴ"], "한", "한"),
            (["ㄱ", "ㅡ", "ㄹ"], "글", "글"),
            (["ㅇ", "ㅓ"], "어", "어"),
            (["ㅁ", "ㅐ", "ㄴ"], "맨", "맨"),
        ]

        for test in tests {
            ime.reset()
            capturedCommitText = ""

            for key in test.keys {
                _ = ime.input(key)
            }

            // Force commit to get final text
            _ = ime.forceCommit()

            let finalText = capturedCommitText
            XCTAssertEqual(finalText, test.expected, "Failed for \(test.description)")
        }
    }

    // MARK: - Compound Vowel Tests

    func testCompoundVowels() {
        let tests: [(keys: [String], expected: String, description: String)] = [
            (["ㄱ", "ㅗ", "ㅏ"], "과", "과"),
            (["ㄱ", "ㅗ", "ㅐ"], "괘", "괘"),
            (["ㄱ", "ㅗ", "ㅣ"], "괴", "괴"),
            (["ㄱ", "ㅜ", "ㅓ"], "궈", "궈"),
            (["ㄱ", "ㅜ", "ㅔ"], "궤", "궤"),
            (["ㄱ", "ㅜ", "ㅣ"], "귀", "귀"),
            (["ㄱ", "ㅡ", "ㅣ"], "긔", "긔"),
        ]

        for test in tests {
            ime.reset()
            capturedCommitText = ""

            for key in test.keys {
                _ = ime.input(key)
            }

            // Force commit to get final text
            _ = ime.forceCommit()

            let finalText = capturedCommitText
            XCTAssertEqual(finalText, test.expected, "Failed for \(test.description)")
        }
    }

    // MARK: - Compound Consonant Tests

    func testCompoundConsonants() {
        let tests: [(keys: [String], expected: String, description: String)] = [
            (["ㄱ", "ㅏ", "ㄱ", "ㅅ"], "갃", "갃"),
            (["ㄴ", "ㅐ", "ㄱ"], "낵", "낵"),
            (["ㄴ", "ㅐ", "ㄲ"], "낶", "낶"),
            (["ㄷ", "ㅏ", "ㄹ", "ㄱ"], "닭", "닭"),
            (["ㄷ", "ㅏ", "ㄹ", "ㅁ"], "닮", "닮"),
            (["ㄷ", "ㅏ", "ㄹ", "ㅂ"], "닯", "닯"),
            (["ㄷ", "ㅏ", "ㄹ", "ㅅ"], "닰", "닰"),
            (["ㄷ", "ㅏ", "ㄹ", "ㅌ"], "닱", "닱"),
            (["ㄷ", "ㅏ", "ㄹ", "ㅍ"], "닲", "닲"),
            (["ㄷ", "ㅏ", "ㄹ", "ㅎ"], "닳", "닳"),
            (["ㄱ", "ㅏ", "ㅂ", "ㅅ"], "값", "값"),
        ]

        for test in tests {
            ime.reset()
            capturedCommitText = ""

            for key in test.keys {
                _ = ime.input(key)
            }

            // Force commit to get final text
            _ = ime.forceCommit()

            let finalText = capturedCommitText
            XCTAssertEqual(finalText, test.expected, "Failed for \(test.description)")
        }
    }

    // MARK: - Dokkaebi Phenomenon Tests

    func testDokkaebiPhenomenon() {
        let tests: [(keys: [String], expected: String, description: String)] = [
            // Simple dokkaebi
            (["ㄱ", "ㅏ", "ㄱ", "ㅣ"], "가기", "가기 (ㄱ+ㅏ+ㄱ → ㄱ+ㅏ / ㄱ+ㅣ)"),
            (["ㄱ", "ㅏ", "ㄴ", "ㅣ"], "가니", "가니 (ㄱ+ㅏ+ㄴ → ㄱ+ㅏ / ㄴ+ㅣ)"),

            // Compound consonant dokkaebi
            (["ㄱ", "ㅏ", "ㄱ", "ㅅ", "ㅣ"], "각시", "각시 (ㄱ+ㅏ+ㄳ → ㄱ+ㅏ+ㄱ / ㅅ+ㅣ)"),
            (["ㄷ", "ㅏ", "ㄹ", "ㄱ", "ㅣ"], "달기", "달기 (ㄷ+ㅏ+ㄺ → ㄷ+ㅏ+ㄹ / ㄱ+ㅣ)"),
            (["ㄷ", "ㅏ", "ㄹ", "ㅁ", "ㅣ"], "달미", "달미 (ㄷ+ㅏ+ㄻ → ㄷ+ㅏ+ㄹ / ㅁ+ㅣ)"),

            // No dokkaebi when jongseong can combine
            (["ㄱ", "ㅏ", "ㄴ", "ㅈ"], "갅", "갅 (ㄱ+ㅏ+ㄴ+ㅈ → ㄱ+ㅏ+ㄵ)"),
        ]

        for test in tests {
            ime.reset()
            capturedCommitText = ""

            for key in test.keys {
                _ = ime.input(key)
            }

            // Force commit to get final text
            _ = ime.forceCommit()

            let finalText = capturedCommitText
            XCTAssertEqual(finalText, test.expected, "Failed for \(test.description)")
        }
    }

    // MARK: - Backspace Tests

    func testBackspace() {
        // Test 1: Simple backspace
        ime.reset()
        capturedCommitText = ""

        _ = ime.input("ㄱ")  // ㄱ
        _ = ime.input("ㅏ")  // 가
        _ = ime.input("ㄴ")  // 간
        var result = ime.backspace()  // Should be 가

        XCTAssertEqual(result, "가", "Simple backspace failed")

        // Test 2: Backspace after dokkaebi
        ime.reset()
        capturedCommitText = ""

        _ = ime.input("ㄱ")  // ㄱ
        _ = ime.input("ㅏ")  // 가
        _ = ime.input("ㄱ")  // 각
        _ = ime.input("ㅅ")  // 갃
        _ = ime.input("ㅣ")  // 각시 (dokkaebi)
        result = ime.backspace()  // Should backspace 시 -> 각ㅅ

        _ = ime.forceCommit()
        let finalText = capturedCommitText
        XCTAssertEqual(finalText, "각ㅅ", "Backspace after dokkaebi failed")

        // Test 3: Multiple backspaces
        ime.reset()
        capturedCommitText = ""

        _ = ime.input("ㅎ")  // ㅎ
        _ = ime.input("ㅏ")  // 하
        _ = ime.input("ㄴ")  // 한
        _ = ime.backspace()  // 하
        _ = ime.backspace()  // ㅎ
        result = ime.backspace()  // empty

        XCTAssertEqual(result, "", "Multiple backspaces failed")
    }

    // MARK: - Non-Hangul Input Tests

    func testNonHangulInput() {
        ime.reset()
        capturedCommitText = ""

        _ = ime.input("ㄱ")  // ㄱ
        _ = ime.input("ㅏ")  // 가
        _ = ime.input("1")  // Should commit 가 and then 1

        XCTAssertEqual(capturedCommitText, "가", "Non-Hangul input handling failed")
        _ = ime.forceCommit()
        XCTAssertEqual(capturedCommitText, "가1", "Non-Hangul input commit failed")
    }

    // MARK: - Sequential Input Tests

    func testSequentialSyllables() {
        ime.reset()
        capturedCommitText = ""

        // Type "한글" (한 + 글)
        _ = ime.input("ㅎ")  // ㅎ
        _ = ime.input("ㅏ")  // 하
        _ = ime.input("ㄴ")  // 한
        let result1 = ime.input("ㄱ")  // 한 committed, ㄱ

        XCTAssertEqual(capturedCommitText, "한", "First syllable not committed")
        XCTAssertEqual(result1, "ㄱ", "Second syllable initial not correct")

        _ = ime.input("ㅡ")  // 그
        _ = ime.input("ㄹ")  // 글

        _ = ime.forceCommit()
        let finalText = capturedCommitText
        XCTAssertEqual(finalText, "한글", "Sequential syllables failed")
    }

    // MARK: - Commit Tests

    func testCommit() {
        ime.reset()
        capturedCommitText = ""

        // Type "한글" (한 + 글)
        _ = ime.input("ㅎ")  // ㅎ
        _ = ime.input("ㅏ")  // 하
        _ = ime.input("ㄴ")  // 한
        _ = ime.input("ㄱ")  // ㄱ
        _ = ime.input("ㅡ")  // 그
        _ = ime.input("ㄹ")  // 글

        XCTAssertEqual(capturedCommitText, "한", "Commit failed")

        _ = ime.input("ㄱ") // ㄱ

        XCTAssertEqual(capturedCommitText, "한", "Commit failed")

        _ = ime.input("ㅗ") // 고

        XCTAssertEqual(capturedCommitText, "한글", "Commit failed")

        _ = ime.input("ㅏ") // 과

        XCTAssertEqual(capturedCommitText, "한글", "Commit failed")

        let commitString = ime.forceCommit()  // Should commit "글"
        XCTAssertEqual(commitString, "과", "Commit string not correct")
        XCTAssertEqual(capturedCommitText, "한글과", "Final commit text not correct")
    }
}

// MARK: - KoreanIMEDelegate

extension StandardDubeolsikTests: KoreanIMEDelegate {
    func koreanIME(_ ime: KoreanIME, didCommitText text: String, composingText: String) {
        capturedCommitText += text
    }

    func koreanIME(_ ime: KoreanIME, requestBackspace: Void) {
        // 테스트에서는 백스페이스 요청을 무시
        // 실제 애플리케이션에서는 여기서 OS 백스페이스를 호출해야 함
    }
}
