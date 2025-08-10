//
//  YAMLLoadedIMETests.swift
//  MetaHangulIME
//
//  YAML로 로드한 IME들의 정상 동작 확인 테스트
//

import XCTest
@testable import MetaHangulIME

final class YAMLLoadedIMETests: XCTestCase {
    var capturedCommitText: String = ""

    // MARK: - CheonJiIn Tests

    func testYAMLCheonJiInBasicInput() throws {
        let ime = try IMEFactory.createFromPreset(.cheonJiIn)
        ime.delegate = self

        // 기본 음절: 긱
        capturedCommitText = ""
        _ = ime.input("ㄱ")  // ㄱ
        _ = ime.input("ㅣ")  // ㅣ
        _ = ime.input("ㄱ")  // ㄱ
        _ = ime.forceCommit()
        XCTAssertEqual(capturedCommitText, "긱")

        // 단어 테스트: 한글
        ime.reset()
        capturedCommitText = ""
        // 한
        _ = ime.input("ㅅ")  // ㅅ
        _ = ime.input("ㅅ")  // ㅎ
        _ = ime.input("ㅣ")  // ㅣ
        _ = ime.input("ㆍ")  // ㅏ
        _ = ime.input("ㄴ")  // ㄴ
        // 글
        _ = ime.input("ㄱ")  // ㄱ
        _ = ime.input("ㅡ")  // ㅡ
        _ = ime.input("ㄴ")  // ㄴ
        _ = ime.input("ㄴ")  // ㄹ
        _ = ime.forceCommit()
        XCTAssertEqual(capturedCommitText, "한글")
    }

    func testYAMLCheonJiInConsonantCombinations() throws {
        let ime = try IMEFactory.createFromPreset(.cheonJiIn)
        ime.delegate = self

        let tests: [(keys: [String], expected: String, desc: String)] = [
            // ㄱ + ㄱ = ㅋ
            (["ㄱ", "ㄱ", "ㅣ"], "키", "ㅋ"),
            // ㅋ + ㄱ = ㄲ
            (["ㄱ", "ㄱ", "ㄱ", "ㅣ"], "끼", "ㄲ"),
            // ㄴ + ㄴ = ㄹ
            (["ㄴ", "ㄴ", "ㅣ"], "리", "ㄹ"),
            // ㅅ + ㅅ = ㅎ, ㅎ + ㅅ = ㅆ
            (["ㅅ", "ㅅ", "ㅅ", "ㅣ"], "씨", "ㅆ"),
            // ㅇ + ㅇ = ㅁ
            (["ㅇ", "ㅇ", "ㅣ"], "미", "ㅁ"),
        ]

        for test in tests {
            ime.reset()
            capturedCommitText = ""

            for key in test.keys {
                _ = ime.input(key)
            }
            _ = ime.forceCommit()

            XCTAssertEqual(capturedCommitText, test.expected, "Failed for \(test.desc)")
        }
    }

    func testYAMLCheonJiInVowelCombinations() throws {
        let ime = try IMEFactory.createFromPreset(.cheonJiIn)
        ime.delegate = self

        let tests: [(keys: [String], expected: String, desc: String)] = [
            // ㅣ + ㆍ = ㅏ
            (["ㄱ", "ㅣ", "ㆍ"], "가", "ㅏ"),
            // ㅏ + ㆍ = ㅑ
            (["ㄱ", "ㅣ", "ㆍ", "ㆍ"], "갸", "ㅑ"),
            // ㆍ + ㅣ = ㅓ
            (["ㄱ", "ㆍ", "ㅣ"], "거", "ㅓ"),
            // ㅡ + ㅣ = ㅢ
            (["ㄱ", "ㅡ", "ㅣ"], "긔", "ㅢ"),
            // ㅜ + ㆍ = ㅠ
            (["ㄱ", "ㅡ", "ㆍ", "ㆍ"], "규", "ㅠ"),
            // 합성 모음
            (["ㄱ", "ㆍ", "ㅡ"], "고", "ㅗ"),
            (["ㄱ", "ㆍ", "ㅡ", "ㅣ"], "괴", "ㅚ"),
        ]

        for test in tests {
            ime.reset()
            capturedCommitText = ""

            for key in test.keys {
                _ = ime.input(key)
            }
            _ = ime.forceCommit()

            XCTAssertEqual(capturedCommitText, test.expected, "Failed for \(test.desc)")
        }
    }

    // MARK: - StandardDubeolsik Tests

    func testYAMLStandardDubeolsikBasicInput() throws {
        let ime = try IMEFactory.createFromPreset(.standardDubeolsik)
        ime.delegate = self

        // 한글 입력: 안녕하세요
        capturedCommitText = ""
        _ = ime.input("ㅇ")  // ㅇ
        _ = ime.input("ㅏ")  // ㅏ
        _ = ime.input("ㄴ")  // ㄴ
        _ = ime.input("ㄴ")  // ㄴ (새 음절)
        _ = ime.input("ㅕ")  // ㅕ
        _ = ime.input("ㅇ")  // ㅇ
        _ = ime.input("ㅎ")  // ㅎ
        _ = ime.input("ㅏ")  // ㅏ
        _ = ime.input("ㅅ")  // ㅅ
        _ = ime.input("ㅔ")  // ㅔ
        _ = ime.input("ㅇ")  // ㅇ
        _ = ime.input("ㅛ")  // ㅛ
        _ = ime.forceCommit()
        XCTAssertEqual(capturedCommitText, "안녕하세요")
    }

    func testYAMLStandardDubeolsikComplexVowels() throws {
        let ime = try IMEFactory.createFromPreset(.standardDubeolsik)
        ime.delegate = self

        let tests: [(keys: [String], expected: String, desc: String)] = [
            // 과 (ㅗ + ㅏ = ㅘ)
            (["ㄱ", "ㅗ", "ㅏ"], "과", "ㅘ"),
            // 웨 (ㅜ + ㅔ = ㅞ)
            (["ㅇ", "ㅜ", "ㅔ"], "웨", "ㅞ"),
            // 의 (ㅡ + ㅣ = ㅢ)
            (["ㅇ", "ㅡ", "ㅣ"], "의", "ㅢ"),
            // 외 (ㅗ + ㅣ = ㅚ)
            (["ㅇ", "ㅗ", "ㅣ"], "외", "ㅚ"),
            // 워 (ㅜ + ㅓ = ㅝ)
            (["ㅇ", "ㅜ", "ㅓ"], "워", "ㅝ"),
        ]

        for test in tests {
            ime.reset()
            capturedCommitText = ""

            for key in test.keys {
                _ = ime.input(key)
            }
            _ = ime.forceCommit()

            XCTAssertEqual(capturedCommitText, test.expected, "Failed for \(test.desc)")
        }
    }

    // MARK: - Comparison Tests

    func testYAMLCheonJiInMatchesHardcoded() throws {
        let yamlIME = try IMEFactory.createFromPreset(.cheonJiIn)
        let hardcodedIME = CheonJiIn()
        yamlIME.delegate = self
        hardcodedIME.delegate = self

        // 동일한 입력 시퀀스로 테스트
        let testSequences: [[String]] = [
            ["ㄱ", "ㅣ", "ㆍ", "ㄱ"],  // 각
            ["ㄴ", "ㄴ", "ㅡ", "ㅣ"],  // 릴
            ["ㅅ", "ㅅ", "ㅣ", "ㆍ", "ㄴ"],  // 한
            ["ㄱ", "ㅡ", "ㄴ", "ㄴ"],  // 글
        ]

        for sequence in testSequences {
            // YAML IME 테스트
            yamlIME.reset()
            capturedCommitText = ""
            for input in sequence {
                _ = yamlIME.input(input)
            }
            _ = yamlIME.forceCommit()
            let yamlResult = capturedCommitText

            // Hardcoded IME 테스트
            hardcodedIME.reset()
            capturedCommitText = ""
            for input in sequence {
                _ = hardcodedIME.input(input)
            }
            _ = hardcodedIME.forceCommit()
            let hardcodedResult = capturedCommitText

            XCTAssertEqual(
                yamlResult,
                hardcodedResult,
                "Mismatch for sequence \(sequence)"
            )
        }
    }

    func testYAMLStandardDubeolsikMatchesHardcoded() throws {
        let yamlIME = try IMEFactory.createFromPreset(.standardDubeolsik)
        let hardcodedIME = StandardDubeolsik()
        yamlIME.delegate = self
        hardcodedIME.delegate = self

        // 동일한 입력 시퀀스로 테스트
        let testSequences: [[String]] = [
            ["ㅇ", "ㅏ", "ㅅ", "ㅅ", "ㅕ", "ㅇ"],  // 안녕
            ["ㅎ", "ㅏ", "ㅅ", "ㅡ", "ㄹ"],  // 하십
            ["ㄱ", "ㅗ", "ㅏ"],  // 과
            ["ㄷ", "ㅏ", "ㄹ", "ㄱ"],  // 닭
        ]

        for sequence in testSequences {
            // YAML IME 테스트
            yamlIME.reset()
            capturedCommitText = ""
            for input in sequence {
                _ = yamlIME.input(input)
            }
            _ = yamlIME.forceCommit()
            let yamlResult = capturedCommitText

            // Hardcoded IME 테스트
            hardcodedIME.reset()
            capturedCommitText = ""
            for input in sequence {
                _ = hardcodedIME.input(input)
            }
            _ = hardcodedIME.forceCommit()
            let hardcodedResult = capturedCommitText

            XCTAssertEqual(
                yamlResult,
                hardcodedResult,
                "Mismatch for sequence \(sequence)"
            )
        }
    }
}

// MARK: - KoreanIMEDelegate

extension YAMLLoadedIMETests: KoreanIMEDelegate {
    func koreanIME(_ ime: KoreanIME, didCommitText text: String) {
        capturedCommitText += text
    }

    func koreanIME(_ ime: KoreanIME, requestBackspace: Void) {
        // Do nothing for tests
    }
}
