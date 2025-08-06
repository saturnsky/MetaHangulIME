//
//  CheonJiInTests.swift
//  MetaHangulIME
//
//  Tests for CheonJiIn IME
//

import XCTest
@testable import MetaHangulIME

final class CheonJiInTests: XCTestCase {
    var ime: CheonJiIn!
    var capturedCommitText: String = ""

    override func setUp() {
        super.setUp()
        ime = CheonJiIn()
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
            // 간 = ㄱ + ㅏ + ㄴ
            (["q", "1", "2", "w"], "간", "간 (ㄱ+ㅏ+ㄴ)"),
            // 한 = ㅎ + ㅏ + ㄴ
            (["s", "s", "1", "2", "w"], "한", "한 (ㅎ+ㅏ+ㄴ)"),
            // 글 = ㄱ + ㅡ + ㄹ
            (["q", "3", "w", "w"], "글", "글 (ㄱ+ㅡ+ㄹ)"),
            // 어 = ㅇ + ㅓ
            (["x", "2", "1"], "어", "어 (ㅇ+ㅓ)"),
            // 맨 = ㅁ + ㅐ + ㄴ
            (["x", "x", "1", "2", "1", "w"], "맨", "맨 (ㅁ+ㅐ+ㄴ)"),
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

    // MARK: - Compound Vowel Tests (from Python)

    func testCompoundVowels() {
        // Test cases based on python_mockup/test_cheonjiin.py
        // Using a simplified input method for direct testing of the automaton logic.
        let testCases: [(keys: [String], expected: String, description: String)] = [
            (["q", "2", "3"], "고", "고 (ㄱ+ㅗ)"),
            (["q", "2", "3", "1", "2"], "과", "과 (ㄱ+ㅘ)"),
            (["q", "2", "3", "1"], "괴", "괴 (ㄱ+ㅚ)"),
            (["q", "3", "2", "2", "1"], "궈", "궈 (ㄱ+ㅝ)"),
            (["q", "3", "2", "1"], "귀", "귀 (ㄱ+ㅟ)"),
            (["q", "3", "1"], "긔", "긔 (ㄱ+ㅢ)"),
        ]

        for test in testCases {
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

    // MARK: - CheonJiIn Specific Consonant Tests

    func testCheonJiInConsonants() {
        let tests: [(keys: [String], expected: String, description: String)] = [
            // 깐 = ㄲ + ㅏ + ㄴ (ㄱ + ㄱ + ㄱ = ㄲ)
            (["q", "q", "q", "1", "2", "w"], "깐", "깐 (ㄲ+ㅏ+ㄴ)"),
            // 싼 = ㅆ + ㅏ + ㄴ (ㅅ + ㅅ + ㅅ = ㅆ)
            (["s", "s", "s", "1", "2", "w"], "싼", "싼 (ㅆ+ㅏ+ㄴ)"),
            // 란 = ㄹ + ㅏ + ㄴ (ㄴ + ㄴ = ㄹ)
            (["w", "w", "1", "2", "w"], "란", "란 (ㄹ+ㅏ+ㄴ)"),
            // 만 = ㅁ + ㅏ + ㄴ (ㅇ + ㅇ = ㅁ)
            (["x", "x", "1", "2", "w"], "만", "만 (ㅁ+ㅏ+ㄴ)"),
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

    // MARK: - Compound Jongseong Tests

    func testCompoundJongseong() {
        let tests: [(keys: [String], expected: String, description: String)] = [
            // 갃 = ㄱ + ㅏ + ㄳ
            (["q", "1", "2", "q", "s"], "갃", "갃 (ㄱ+ㅏ+ㄳ)"),
            // 닭 = ㄷ + ㅏ + ㄺ
            (["e", "1", "2", "w", "w", "q"], "닭", "닭 (ㄷ+ㅏ+ㄺ)"),
            // 없 = ㅇ + ㅓ + ㅄ
            (["x", "2", "1", "a", "s"], "없", "없 (ㅇ+ㅓ+ㅄ)"),
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
        // Dokkaebi cases from Python tests
        let tests: [(keys: [String], expected: String, description: String)] = [
            // 가기 = ㄱ + ㅏ + ㄱ → ㄱ + ㅏ / ㄱ + ㅣ
            (["q", "1", "2", "q", "1"], "가기", "가기 (dokkaebi)"),
            // 각시 = ㄱ + ㅏ + ㄳ → ㄱ + ㅏ + ㄱ / ㅅ + ㅣ
            (["q", "1", "2", "q", "s", "1"], "각시", "각시 (compound dokkaebi)"),
            // 달기 = ㄷ + ㅏ + ㄺ → ㄷ + ㅏ + ㄹ / ㄱ + ㅣ
            (["e", "1", "2", "w", "w", "q", "1"], "달기", "달기 (ㄺ dokkaebi)"),
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
        // Test 1: 한 → 하
        ime.reset()
        capturedCommitText = ""

        _ = ime.input("s")
        _ = ime.input("s")
        _ = ime.input("1")
        _ = ime.input("2")
        _ = ime.input("w")
        let result1 = ime.backspace()
        XCTAssertEqual(result1, "하", "한 → 하: Failed")

        // Test 2: 괘 → 과 → 괴 → 고
        ime.reset()
        capturedCommitText = ""

        _ = ime.input("q")
        _ = ime.input("2")
        _ = ime.input("3")
        _ = ime.input("1")
        _ = ime.input("2")
        _ = ime.input("1")  // 괘
        let result2 = ime.backspace()  // 과
        XCTAssertEqual(result2, "과", "괘 → 과: Failed")
        let result3 = ime.backspace()  // 괴
        XCTAssertEqual(result3, "괴", "과 → 괴: Failed")
        let result4 = ime.backspace()  // 고
        XCTAssertEqual(result4, "고", "괴 → 고: Failed")

        // Test 3: 갃 → 각
        ime.reset()
        capturedCommitText = ""

        _ = ime.input("q")
        _ = ime.input("1")
        _ = ime.input("2")
        _ = ime.input("q")
        _ = ime.input("s")
        let result5 = ime.backspace()
        XCTAssertEqual(result5, "각", "갃 → 각: Failed")
    }

    // MARK: - Special Character Tests

    func testSpecialCharacters() {
        // Test period cycling using 'c' key
        ime.reset()
        capturedCommitText = ""

        var result = ime.input("c")  // .
        print("First c result: '\(result)'")
        XCTAssertEqual(result, ".", "First period failed")

        result = ime.input("c")  // ,
        print("Second c result: '\(result)'")
        print("Has composing text: \(ime.hasComposingText)")
        print("Composing text: '\(ime.getComposingText())'")
        XCTAssertEqual(result, ",", "Period to comma failed")

        result = ime.input("c")  // ?
        XCTAssertEqual(result, "?", "Comma to question failed")

        result = ime.input("c")  // !
        XCTAssertEqual(result, "!", "Question to exclamation failed")

        // Test special character doesn't interfere with Hangul
        ime.reset()
        capturedCommitText = ""

        _ = ime.input("q")  // ㄱ
        _ = ime.input("1")  // ㄱ + ㅣ
        _ = ime.input("2")  // 가
        _ = ime.input("c")  // Commits 가 and starts .

        XCTAssertEqual(capturedCommitText, "가", "Special character should commit Hangul")
    }

    // MARK: - Edge Case Tests

    func testEdgeCase_Halda() {
        // Test: 핥다
        ime.reset()
        capturedCommitText = ""

        let steps: [(key: String, expected: String)] = [
            ("s", "ㅅ"),
            ("s", "ㅎ"),
            ("1", "히"),
            ("2", "하"),
            ("w", "한"),
            ("w", "할"),
            ("e", "할ㄷ"),
            ("e", "핥"),
            ("e", "핥ㄷ"),
            ("1", "핥디"),
            ("2", "핥다"),
        ]

        for (idx, (key, expected)) in steps.enumerated() {
            let result = ime.input(key)
            if idx == 6 && result != expected {
                // Debug 할ㄷ case
                print("DEBUG 할ㄷ: result=\(result), expected=\(expected)")
                print("  Current text: \(ime.getComposingText())")
                print("  Has composing: \(ime.hasComposingText)")
            }
            XCTAssertEqual(result, expected, "핥다 test failed at key: \(key)")
        }
    }

    func testEdgeCase_Heok() {
        // Test: 헕
        ime.reset()
        capturedCommitText = ""

        let steps: [(key: String, expected: String)] = [
            ("s", "ㅅ"),
            ("s", "ㅎ"),
            ("2", "ㅎㆍ"),
            ("1", "허"),
            ("w", "헌"),
            ("w", "헐"),
            ("e", "헐ㄷ"),
            ("e", "헕"),
        ]

        for (key, expected) in steps {
            let result = ime.input(key)
            XCTAssertEqual(result, expected, "헕 test failed at key: \(key)")
        }
    }

    func testEdgeCase_Dotdae() {
        // Test: 돋대
        ime.reset()
        capturedCommitText = ""

        let steps: [(key: String, expected: String)] = [
            ("e", "ㄷ"),
            ("2", "ㄷㆍ"),
            ("3", "도"),
            ("e", "돋"),
            ("e", "돝"),
            ("e", "돋ㄷ"),
            ("1", "돋디"),
            ("2", "돋다"),
            ("1", "돋대"),
        ]

        for (key, expected) in steps {
            let result = ime.input(key)
            XCTAssertEqual(result, expected, "돋대 test failed at key: \(key)")
        }
    }

    func testEdgeCase_DonghaemulgwaWithBackspace() {
        // Test: 동해물과 with backspace
        ime.reset()
        capturedCommitText = ""

        let steps: [(key: String, isBackspace: Bool, expected: String)] = [
            ("e", false, "ㄷ"),
            ("2", false, "ㄷㆍ"),
            ("3", false, "도"),
            ("x", false, "동"),
            ("s", false, "동ㅅ"),
            ("s", false, "동ㅎ"),
            ("1", false, "동히"),
            ("2", false, "동하"),
            ("1", false, "동해"),
            ("x", false, "동행"),
            ("x", false, "동햄"),
            ("3", false, "동해므"),
            ("2", false, "동해무"),
            ("w", false, "동해문"),
            ("w", false, "동해물"),
            ("q", false, "동해묽"),
            ("2", false, "동해물ㄱㆍ"),
            ("3", false, "동해물고"),
            ("1", false, "동해물괴"),
            ("2", false, "동해물과"),
            ("", true, "동해물괴"),
            ("", true, "동해물고"),
            ("", true, "동해물ㄱㆍ"),
            ("", true, "동해묽"),
            ("", true, "동해물"),
            ("", true, "동해무"),
            ("", true, "동해므"),
            ("", true, "동햄"),
            ("", true, "동해"),
            ("", true, "동하"),
            ("", true, "동히"),
            ("", true, "동ㅎ"),
            ("", true, "동"),
            ("", true, "도"),
            ("", true, "ㄷㆍ"),
            ("", true, "ㄷ"),
        ]

        for (key, isBackspace, expected) in steps {
            let result = isBackspace ? ime.backspace() : ime.input(key)
            XCTAssertEqual(result, expected, "동해물과 test failed at step expecting: \(expected)")
        }
    }

    // MARK: - Continuous Input Tests

    func testContinuousInput() {
        // "안녕" = ㅇ + ㅏ + ㄴ / ㄴ + ㅕ + ㅇ
        // ㅇ = x, ㅏ = ㅣ + ㆍ = 1 + 2, ㄴ = w
        // ㄴ = w, ㅕ = ᆢ + ㅣ = ㆍ + ㆍ + ㅣ = 2 + 2 + 1, ㅇ = x
        ime.reset()
        capturedCommitText = ""

        let keys = ["x", "1", "2", "w", "w", "2", "2", "1", "x"]

        for (idx, key) in keys.enumerated() {
            if idx == 4 {
                _ = ime.forceCommit()
            }
            _ = ime.input(key)
        }

        let finalText = ime.getComposingText()
        XCTAssertEqual(finalText, "녕", "안녕 continuous input failed - composing text")
        XCTAssertEqual(capturedCommitText, "안", "안녕 continuous input failed - committed text")
    }
}

// MARK: - KoreanIMEDelegate

extension CheonJiInTests: KoreanIMEDelegate {
    func koreanIME(_ ime: KoreanIME, didCommitText text: String) {
        capturedCommitText += text
    }

    func koreanIME(_ ime: KoreanIME, requestBackspace: Void) {
        // 테스트에서는 백스페이스 요청을 무시
        // 실제 애플리케이션에서는 여기서 OS 백스페이스를 호출해야 함
    }
}
