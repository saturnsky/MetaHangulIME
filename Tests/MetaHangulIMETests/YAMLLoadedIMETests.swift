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
        _ = ime.input("q")  // ㄱ
        _ = ime.input("1")  // ㅣ
        _ = ime.input("q")  // ㄱ
        _ = ime.forceCommit()
        XCTAssertEqual(capturedCommitText, "긱")

        // 단어 테스트: 한글
        ime.reset()
        capturedCommitText = ""
        // 한
        _ = ime.input("s")  // ㅅ
        _ = ime.input("s")  // ㅎ
        _ = ime.input("1")  // ㅣ
        _ = ime.input("2")  // ㅏ
        _ = ime.input("w")  // ㄴ
        // 글
        _ = ime.input("q")  // ㄱ
        _ = ime.input("3")  // ㅡ
        _ = ime.input("w")  // ㄴ
        _ = ime.input("w")  // ㄹ
        _ = ime.forceCommit()
        XCTAssertEqual(capturedCommitText, "한글")
    }

    func testYAMLCheonJiInConsonantCombinations() throws {
        let ime = try IMEFactory.createFromPreset(.cheonJiIn)
        ime.delegate = self

        let tests: [(keys: [String], expected: String, desc: String)] = [
            // ㄱ + ㄱ = ㅋ
            (["q", "q", "1"], "키", "ㅋ"),
            // ㅋ + ㄱ = ㄲ
            (["q", "q", "q", "1"], "끼", "ㄲ"),
            // ㄴ + ㄴ = ㄹ
            (["w", "w", "1"], "리", "ㄹ"),
            // ㅅ + ㅅ = ㅎ, ㅎ + ㅅ = ㅆ
            (["s", "s", "s", "1"], "씨", "ㅆ"),
            // ㅇ + ㅇ = ㅁ
            (["x", "x", "1"], "미", "ㅁ"),
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
            (["q", "1", "2"], "가", "ㅏ"),
            // ㅏ + ㆍ = ㅑ
            (["q", "1", "2", "2"], "갸", "ㅑ"),
            // ㆍ + ㅣ = ㅓ
            (["q", "2", "1"], "거", "ㅓ"),
            // ㅡ + ㅣ = ㅢ
            (["q", "3", "1"], "긔", "ㅢ"),
            // ㅜ + ㆍ = ㅠ
            (["q", "3", "2", "2"], "규", "ㅠ"),
            // 합성 모음
            (["q", "2", "3"], "고", "ㅗ"),
            (["q", "2", "3", "1"], "괴", "ㅚ"),
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
        _ = ime.input("d")  // ㅇ
        _ = ime.input("k")  // ㅏ
        _ = ime.input("s")  // ㄴ
        _ = ime.input("s")  // ㄴ (새 음절)
        _ = ime.input("u")  // ㅕ
        _ = ime.input("d")  // ㅇ
        _ = ime.input("g")  // ㅎ
        _ = ime.input("k")  // ㅏ
        _ = ime.input("t")  // ㅅ
        _ = ime.input("p")  // ㅔ
        _ = ime.input("d")  // ㅇ
        _ = ime.input("y")  // ㅛ
        _ = ime.forceCommit()
        XCTAssertEqual(capturedCommitText, "안녕하세요")
    }

    func testYAMLStandardDubeolsikComplexVowels() throws {
        let ime = try IMEFactory.createFromPreset(.standardDubeolsik)
        ime.delegate = self

        let tests: [(keys: [String], expected: String, desc: String)] = [
            // 과 (ㅗ + ㅏ = ㅘ)
            (["r", "h", "k"], "과", "ㅘ"),
            // 웨 (ㅜ + ㅔ = ㅞ)
            (["d", "n", "p"], "웨", "ㅞ"),
            // 의 (ㅡ + ㅣ = ㅢ)
            (["d", "m", "l"], "의", "ㅢ"),
            // 외 (ㅗ + ㅣ = ㅚ)
            (["d", "h", "l"], "외", "ㅚ"),
            // 워 (ㅜ + ㅓ = ㅝ)
            (["d", "n", "j"], "워", "ㅝ"),
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
            ["q", "1", "2", "q"],  // 각
            ["w", "w", "3", "1"],  // 릴
            ["s", "s", "1", "2", "w"],  // 한
            ["q", "3", "w", "w"],  // 글
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
            ["d", "k", "s", "s", "u", "d"],  // 안녕
            ["g", "k", "t", "m", "f"],  // 하십
            ["r", "h", "k"],  // 과
            ["e", "k", "f", "r"],  // 닭
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
