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
            (["ㄱ", "ㅣ", "ㆍ", "ㄴ"], "간", "간 (ㄱ+ㅏ+ㄴ)"),
            // 한 = ㅎ + ㅏ + ㄴ
            (["ㅅ", "ㅅ", "ㅣ", "ㆍ", "ㄴ"], "한", "한 (ㅎ+ㅏ+ㄴ)"),
            // 글 = ㄱ + ㅡ + ㄹ
            (["ㄱ", "ㅡ", "ㄴ", "ㄴ"], "글", "글 (ㄱ+ㅡ+ㄹ)"),
            // 어 = ㅇ + ㅓ
            (["ㅇ", "ㆍ", "ㅣ"], "어", "어 (ㅇ+ㅓ)"),
            // 맨 = ㅁ + ㅐ + ㄴ
            (["ㅇ", "ㅇ", "ㅣ", "ㆍ", "ㅣ", "ㄴ"], "맨", "맨 (ㅁ+ㅐ+ㄴ)"),
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
            (["ㄱ", "ㆍ", "ㅡ"], "고", "고 (ㄱ+ㅗ)"),
            (["ㄱ", "ㆍ", "ㅡ", "ㅣ", "ㆍ"], "과", "과 (ㄱ+ㅘ)"),
            (["ㄱ", "ㆍ", "ㅡ", "ㅣ"], "괴", "괴 (ㄱ+ㅚ)"),
            (["ㄱ", "ㅡ", "ㆍ", "ㆍ", "ㅣ"], "궈", "궈 (ㄱ+ㅝ)"),
            (["ㄱ", "ㅡ", "ㆍ", "ㅣ"], "귀", "귀 (ㄱ+ㅟ)"),
            (["ㄱ", "ㅡ", "ㅣ"], "긔", "긔 (ㄱ+ㅢ)"),
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
            (["ㄱ", "ㄱ", "ㄱ", "ㅣ", "ㆍ", "ㄴ"], "깐", "깐 (ㄲ+ㅏ+ㄴ)"),
            // 싼 = ㅆ + ㅏ + ㄴ (ㅅ + ㅅ + ㅅ = ㅆ)
            (["ㅅ", "ㅅ", "ㅅ", "ㅣ", "ㆍ", "ㄴ"], "싼", "싼 (ㅆ+ㅏ+ㄴ)"),
            // 란 = ㄹ + ㅏ + ㄴ (ㄴ + ㄴ = ㄹ)
            (["ㄴ", "ㄴ", "ㅣ", "ㆍ", "ㄴ"], "란", "란 (ㄹ+ㅏ+ㄴ)"),
            // 만 = ㅁ + ㅏ + ㄴ (ㅇ + ㅇ = ㅁ)
            (["ㅇ", "ㅇ", "ㅣ", "ㆍ", "ㄴ"], "만", "만 (ㅁ+ㅏ+ㄴ)"),
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
            (["ㄱ", "ㅣ", "ㆍ", "ㄱ", "ㅅ"], "갃", "갃 (ㄱ+ㅏ+ㄳ)"),
            // 닭 = ㄷ + ㅏ + ㄺ
            (["ㄷ", "ㅣ", "ㆍ", "ㄴ", "ㄴ", "ㄱ"], "닭", "닭 (ㄷ+ㅏ+ㄺ)"),
            // 없 = ㅇ + ㅓ + ㅄ
            (["ㅇ", "ㆍ", "ㅣ", "ㅂ", "ㅅ"], "없", "없 (ㅇ+ㅓ+ㅄ)"),
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
            (["ㄱ", "ㅣ", "ㆍ", "ㄱ", "ㅣ"], "가기", "가기 (dokkaebi)"),
            // 각시 = ㄱ + ㅏ + ㄳ → ㄱ + ㅏ + ㄱ / ㅅ + ㅣ
            (["ㄱ", "ㅣ", "ㆍ", "ㄱ", "ㅅ", "ㅣ"], "각시", "각시 (compound dokkaebi)"),
            // 달기 = ㄷ + ㅏ + ㄺ → ㄷ + ㅏ + ㄹ / ㄱ + ㅣ
            (["ㄷ", "ㅣ", "ㆍ", "ㄴ", "ㄴ", "ㄱ", "ㅣ"], "달기", "달기 (ㄺ dokkaebi)"),
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

        _ = ime.input("ㅅ")
        _ = ime.input("ㅅ")
        _ = ime.input("ㅣ")
        _ = ime.input("ㆍ")
        _ = ime.input("ㄴ")
        let result1 = ime.backspace()
        XCTAssertEqual(result1, "하", "한 → 하: Failed")

        // Test 2: 괘 → 과 → 괴 → 고
        ime.reset()
        capturedCommitText = ""

        _ = ime.input("ㄱ")
        _ = ime.input("ㆍ")
        _ = ime.input("ㅡ")
        _ = ime.input("ㅣ")
        _ = ime.input("ㆍ")
        _ = ime.input("ㅣ")  // 괘
        let result2 = ime.backspace()  // 과
        XCTAssertEqual(result2, "과", "괘 → 과: Failed")
        let result3 = ime.backspace()  // 괴
        XCTAssertEqual(result3, "괴", "과 → 괴: Failed")
        let result4 = ime.backspace()  // 고
        XCTAssertEqual(result4, "고", "괴 → 고: Failed")

        // Test 3: 갃 → 각
        ime.reset()
        capturedCommitText = ""

        _ = ime.input("ㄱ")
        _ = ime.input("ㅣ")
        _ = ime.input("ㆍ")
        _ = ime.input("ㄱ")
        _ = ime.input("ㅅ")
        let result5 = ime.backspace()
        XCTAssertEqual(result5, "각", "갃 → 각: Failed")
    }

    // MARK: - Non-Jamo Character Tests

    func testNonJamoCharacters() {
        // Test period cycling using 'c' key
        ime.reset()
        capturedCommitText = ""

        var result = ime.input(".")  // .
        print("First c result: '\(result)'")
        XCTAssertEqual(result, ".", "First period failed")

        result = ime.input(".")  // ,
        print("Second c result: '\(result)'")
        print("Has composing text: \(ime.hasComposingText)")
        print("Composing text: '\(ime.getComposingText())'")
        XCTAssertEqual(result, ",", "Period to comma failed")

        result = ime.input(".")  // ?
        XCTAssertEqual(result, "?", "Comma to question failed")

        result = ime.input(".")  // !
        XCTAssertEqual(result, "", "! should auto-commit since there is no next automata transition")

        // Test special character doesn't interfere with Hangul
        ime.reset()
        capturedCommitText = ""

        _ = ime.input("ㄱ")  // ㄱ
        _ = ime.input("ㅣ")  // ㄱ + ㅣ
        _ = ime.input("ㆍ")  // 가
        _ = ime.input(".")  // Commits 가 and starts .

        XCTAssertEqual(capturedCommitText, "가", "Special character should commit Hangul")
    }

    // MARK: - Edge Case Tests

    func testEdgeCase_Halda() {
        // Test: 핥다
        ime.reset()
        capturedCommitText = ""

        let steps: [(key: String, expected: String)] = [
            ("ㅅ", "ㅅ"),
            ("ㅅ", "ㅎ"),
            ("ㅣ", "히"),
            ("ㆍ", "하"),
            ("ㄴ", "한"),
            ("ㄴ", "할"),
            ("ㄷ", "할ㄷ"),
            ("ㄷ", "핥"),
            ("ㄷ", "핥ㄷ"),
            ("ㅣ", "핥디"),
            ("ㆍ", "핥다"),
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
            ("ㅅ", "ㅅ"),
            ("ㅅ", "ㅎ"),
            ("ㆍ", "ㅎㆍ"),
            ("ㅣ", "허"),
            ("ㄴ", "헌"),
            ("ㄴ", "헐"),
            ("ㄷ", "헐ㄷ"),
            ("ㄷ", "헕"),
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
            ("ㄷ", "ㄷ"),
            ("ㆍ", "ㄷㆍ"),
            ("ㅡ", "도"),
            ("ㄷ", "돋"),
            ("ㄷ", "돝"),
            ("ㄷ", "돋ㄷ"),
            ("ㅣ", "돋디"),
            ("ㆍ", "돋다"),
            ("ㅣ", "돋대"),
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
            ("ㄷ", false, "ㄷ"),
            ("ㆍ", false, "ㄷㆍ"),
            ("ㅡ", false, "도"),
            ("ㅇ", false, "동"),
            ("ㅅ", false, "동ㅅ"),
            ("ㅅ", false, "동ㅎ"),
            ("ㅣ", false, "동히"),
            ("ㆍ", false, "동하"),
            ("ㅣ", false, "동해"),
            ("ㅇ", false, "동행"),
            ("ㅇ", false, "동햄"),
            ("ㅡ", false, "동해므"),
            ("ㆍ", false, "동해무"),
            ("ㄴ", false, "동해문"),
            ("ㄴ", false, "동해물"),
            ("ㄱ", false, "동해묽"),
            ("ㆍ", false, "동해물ㄱㆍ"),
            ("ㅡ", false, "동해물고"),
            ("ㅣ", false, "동해물괴"),
            ("ㆍ", false, "동해물과"),
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

        let keys = ["ㅇ", "ㅣ", "ㆍ", "ㄴ", "ㄴ", "ㆍ", "ㆍ", "ㅣ", "ㅇ"]

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
