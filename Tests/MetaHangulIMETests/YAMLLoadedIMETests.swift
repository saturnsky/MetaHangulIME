//
//  YAMLLoadedIMETests.swift
//  MetaHangulIMETests
//
//  YAML로 로드한 IME들의 정상 동작 확인 테스트
//

import XCTest
@testable import MetaHangulIME

final class YAMLLoadedIMETests: XCTestCase {
    
    var capturedCommitText: String = ""
    
    // MARK: - CheonJiIn Tests
    
    func testYAMLCheonJiInBasicInput() throws {
        let ime = try createCheonJiInFromYAML()
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
        let ime = try createCheonJiInFromYAML()
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
          (["x", "x", "1"], "미", "ㅁ")
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
        let ime = try createCheonJiInFromYAML()
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
          (["q", "2", "3", "1"], "괴", "ㅚ")
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
    
    func testYAMLCheonJiInDokkaebi() throws {
        let ime = try createCheonJiInFromYAML()
        ime.delegate = self
        capturedCommitText = ""
        
        // 긱 + ㅏ = 기가
        ime.reset()
        _ = ime.input("q")  // ㄱ
        _ = ime.input("1")  // ㅣ
        _ = ime.input("q")  // ㄱ (종성)
        _ = ime.input("2")  // ㆍ (도깨비불 발생)
        _ = ime.input("1")  // ㅣ -> ㅓ
        _ = ime.forceCommit()
        XCTAssertEqual(capturedCommitText, "기거")
    }
    
    func testYAMLCheonJiInSpecialCharacter() throws {
        let ime = try createCheonJiInFromYAML()
        ime.delegate = self
        capturedCommitText = ""
        
        // 특수문자 전환 테스트
        _ = ime.input("c")  // .
        _ = ime.input("c")  // ,
        _ = ime.input("c")  // ?
        _ = ime.input("c")  // !
        _ = ime.forceCommit()
        XCTAssertEqual(capturedCommitText, "!")
        
        // 특수문자와 한글 혼합
        ime.reset()
        capturedCommitText = ""
        _ = ime.input("q")
        _ = ime.input("1")
        _ = ime.input("c")  // 특수문자로 한글 커밋
        _ = ime.forceCommit()
        XCTAssertEqual(capturedCommitText, "기.")
    }
    
    func testYAMLCheonJiInBackspace() throws {
        let ime = try createCheonJiInFromYAML()
        ime.delegate = self
        
        // 복합 모음 백스페이스 테스트: 갸 -> 가 -> 기 -> ㄱ -> ""
        capturedCommitText = ""
        _ = ime.input("q")  // ㄱ
        _ = ime.input("1")  // ㅣ
        _ = ime.input("2")  // ㆍ -> ㅏ
        _ = ime.input("2")  // ㆍ -> ㅑ
        
        // 현재 상태: 갸
        _ = ime.backspace()  // ㅑ -> ㅏ
        _ = ime.forceCommit()
        XCTAssertEqual(capturedCommitText, "가")
        
        ime.reset()
        capturedCommitText = ""
        _ = ime.input("q")
        _ = ime.input("1")
        _ = ime.input("2")
        _ = ime.backspace()  // ㅏ -> ㅣ
        _ = ime.forceCommit()
        XCTAssertEqual(capturedCommitText, "기")
        
        ime.reset()
        capturedCommitText = ""
        _ = ime.input("q")
        _ = ime.input("1")
        _ = ime.backspace()  // 중성 삭제
        _ = ime.input("3")  // 다른 모음 추가
        _ = ime.forceCommit()
        XCTAssertEqual(capturedCommitText, "그")
    }
    
    // MARK: - StandardDubeolsik Tests
    
    func testYAMLStandardDubeolsikBasicInput() throws {
        let ime = try createStandardDubeolsikFromYAML()
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
        let ime = try createStandardDubeolsikFromYAML()
        ime.delegate = self
        
        let tests: [(keys: [String], expected: String, desc: String)] = [
          // 과 (ㅗ + ㅏ = ㅘ)
          (["r", "h", "k"], "과", "ㅘ"),
          // 웨 (ㅜ + ㅔ = ㅞ)
          (["d", "n", "p"], "웨", "ㅞ"),
          // 의 (ㅡ + ㅣ = ㅢ)
          (["d", "m", "l"], "의", "ㅢ"),
          // 왓 (ㅗ + ㅣ = ㅚ)
          (["d", "h", "l"], "외", "ㅚ"),
          // 워 (ㅜ + ㅓ = ㅝ)
          (["d", "n", "j"], "워", "ㅝ")
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
    
    func testYAMLStandardDubeolsikComplexConsonants() throws {
        let ime = try createStandardDubeolsikFromYAML()
        ime.delegate = self
        
        let tests: [(keys: [String], expected: String, desc: String)] = [
          // 닭 (ㄷ + ㅏ + ㄹ + ㄱ = ㄺ)
          (["e", "k", "f", "r"], "닭", "ㄺ"),
          // 값 (ㄱ + ㅏ + ㅂ + ㅅ = ㅄ)
          (["r", "k", "q", "t"], "값", "ㅄ"),
          // 읽 (ㅇ + ㅣ + ㄹ + ㄱ)
          (["d", "l", "f", "r"], "읽", "ㄹㄱ"),
          // 흛 (ㅎ + ㅡ + ㄹ + ㅌ)
          (["g", "m", "f", "x"], "흝", "ㄹㅌ")
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
    
    func testYAMLStandardDubeolsikDokkaebi() throws {
        let ime = try createStandardDubeolsikFromYAML()
        ime.delegate = self
        
        // 밟 + ㅏ = 발바
        capturedCommitText = ""
        _ = ime.input("q")  // ㅂ
        _ = ime.input("k")  // ㅏ
        _ = ime.input("f")  // ㄹ
        _ = ime.input("q")  // ㅂ
        _ = ime.input("k")  // ㅏ (도깨비불)
        _ = ime.forceCommit()
        XCTAssertEqual(capturedCommitText, "발바")
        
        // 닭 + ㅗ = 달고
        ime.reset()
        capturedCommitText = ""
        _ = ime.input("e")  // ㄷ
        _ = ime.input("k")  // ㅏ
        _ = ime.input("f")  // ㄹ
        _ = ime.input("r")  // ㄱ (ㄺ)
        _ = ime.input("h")  // ㅗ (도깨비불)
        _ = ime.forceCommit()
        XCTAssertEqual(capturedCommitText, "달고")
    }
    
    // MARK: - Comparison Tests
    
    func testYAMLCheonJiInMatchesHardcoded() throws {
        let yamlIME = try createCheonJiInFromYAML()
        let hardcodedIME = CheonJiIn()
        yamlIME.delegate = self
        hardcodedIME.delegate = self
        
        // 동일한 입력 시퀀스로 테스트
        let testSequences: [[String]] = [
          ["q", "1", "2", "q"],  // 각
          ["w", "w", "3", "1"],  // 릴
          ["s", "s", "1", "2", "w"],  // 한
          ["q", "3", "w", "w"]   // 글
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
          
          XCTAssertEqual(yamlResult, hardcodedResult,
                        "Mismatch for sequence \(sequence)")
        }
    }
    
    func testYAMLStandardDubeolsikMatchesHardcoded() throws {
        let yamlIME = try createStandardDubeolsikFromYAML()
        let hardcodedIME = StandardDubeolsik()
        yamlIME.delegate = self
        hardcodedIME.delegate = self
        
        // 동일한 입력 시퀀스로 테스트
        let testSequences: [[String]] = [
          ["d", "k", "s", "s", "u", "d"],  // 안녕
          ["g", "k", "t", "m", "f"],  // 하십
          ["r", "h", "k"],  // 과
          ["e", "k", "f", "r"]  // 닭
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
          
          XCTAssertEqual(yamlResult, hardcodedResult,
                        "Mismatch for sequence \(sequence)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createCheonJiInFromYAML() throws -> KoreanIME {
        let yamlPath = Bundle.module.url(forResource: "cheonjiin-test", withExtension: "yaml",
                                      subdirectory: "TestResources")
        
        if let path = yamlPath {
          return try IMEFactory.createFromFile(at: path)
        } else {
          // Fallback: Create from embedded YAML string
          return try IMEFactory.create(from: try IMEConfigurationLoader.load(from: cheonJiInTestYAML))
        }
    }
    
    private func createStandardDubeolsikFromYAML() throws -> KoreanIME {
        let yamlPath = Bundle.module.url(forResource: "standard-dubeolsik-test", withExtension: "yaml",
                                      subdirectory: "TestResources")
        
        if let path = yamlPath {
          return try IMEFactory.createFromFile(at: path)
        } else {
          // Fallback: Create from embedded YAML string
          return try IMEFactory.create(from: try IMEConfigurationLoader.load(from: standardDubeolsikTestYAML))
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

// MARK: - Embedded Test YAML

extension YAMLLoadedIMETests {
    
    private var cheonJiInTestYAML: String {
        """
        name: "천지인"
        identifier: "cheonjiin"
        config:
          orderMode: "sequential"
          commitUnit: "explicitCommit"
          displayMode: "modernMultiple"
          supportStandaloneCluster: true
        layout:
          q: { identifier: "ㄱ", label: "ㄱ" }
          w: { identifier: "ㄴ", label: "ㄴ" }
          e: { identifier: "ㄷ", label: "ㄷ" }
          a: { identifier: "ㅂ", label: "ㅂ" }
          s: { identifier: "ㅅ", label: "ㅅ" }
          d: { identifier: "ㅈ", label: "ㅈ" }
          x: { identifier: "ㅇ", label: "ㅇ" }
          "1": { identifier: "ㅣ", label: "ㅣ" }
          "2": { identifier: "ㆍ", label: "ㆍ" }
          "3": { identifier: "ㅡ", label: "ㅡ" }
          c: { identifier: ".", label: ".", isNonJamo: true }
        automata:
          choseong:
            transitions:
              - { from: "", input: "ㄱ", to: "ㄱ" }
              - { from: "", input: "ㄴ", to: "ㄴ" }
              - { from: "", input: "ㄷ", to: "ㄷ" }
              - { from: "", input: "ㅂ", to: "ㅂ" }
              - { from: "", input: "ㅅ", to: "ㅅ" }
              - { from: "", input: "ㅈ", to: "ㅈ" }
              - { from: "", input: "ㅇ", to: "ㅇ" }
              - { from: "ㄱ", input: "ㄱ", to: "ㅋ" }
              - { from: "ㅋ", input: "ㄱ", to: "ㄲ" }
              - { from: "ㄴ", input: "ㄴ", to: "ㄹ" }
              - { from: "ㄷ", input: "ㄷ", to: "ㅌ" }
              - { from: "ㅌ", input: "ㄷ", to: "ㄸ" }
              - { from: "ㅂ", input: "ㅂ", to: "ㅍ" }
              - { from: "ㅍ", input: "ㅂ", to: "ㅃ" }
              - { from: "ㅅ", input: "ㅅ", to: "ㅎ" }
              - { from: "ㅎ", input: "ㅅ", to: "ㅆ" }
              - { from: "ㅈ", input: "ㅈ", to: "ㅊ" }
              - { from: "ㅊ", input: "ㅈ", to: "ㅉ" }
              - { from: "ㅇ", input: "ㅇ", to: "ㅁ" }
            display:
              "ㄱ": "\\u1100"
              "ㄲ": "\\u1101"
              "ㄴ": "\\u1102"
              "ㄷ": "\\u1103"
              "ㄸ": "\\u1104"
              "ㄹ": "\\u1105"
              "ㅁ": "\\u1106"
              "ㅂ": "\\u1107"
              "ㅃ": "\\u1108"
              "ㅅ": "\\u1109"
              "ㅆ": "\\u110A"
              "ㅇ": "\\u110B"
              "ㅈ": "\\u110C"
              "ㅉ": "\\u110D"
              "ㅊ": "\\u110E"
              "ㅋ": "\\u110F"
              "ㅌ": "\\u1110"
              "ㅍ": "\\u1111"
              "ㅎ": "\\u1112"
          jungseong:
            transitions:
              - { from: "", input: "ㅣ", to: "ㅣ" }
              - { from: "", input: "ㆍ", to: "ㆍ" }
              - { from: "", input: "ㅡ", to: "ㅡ" }
              - { from: "ㆍ", input: "ㆍ", to: "ᆢ" }
              - { from: "ㅣ", input: "ㆍ", to: "ㅏ" }
              - { from: "ㅏ", input: "ㆍ", to: "ㅑ" }
              - { from: "ㆍ", input: "ㅣ", to: "ㅓ" }
              - { from: "ᆢ", input: "ㅣ", to: "ㅕ" }
              - { from: "ㆍ", input: "ㅡ", to: "ㅗ" }
              - { from: "ᆢ", input: "ㅡ", to: "ㅛ" }
              - { from: "ㅡ", input: "ㆍ", to: "ㅜ" }
              - { from: "ㅜ", input: "ㆍ", to: "ㅠ" }
              - { from: "ㅏ", input: "ㅣ", to: "ㅐ" }
              - { from: "ㅑ", input: "ㅣ", to: "ㅒ" }
              - { from: "ㅓ", input: "ㅣ", to: "ㅔ" }
              - { from: "ㅕ", input: "ㅣ", to: "ㅖ" }
              - { from: "ㅗ", input: "ㅣ", to: "ㅚ" }
              - { from: "ㅚ", input: "ㆍ", to: "ㅘ" }
              - { from: "ㅘ", input: "ㅣ", to: "ㅙ" }
              - { from: "ㅠ", input: "ㅣ", to: "ㅝ" }
              - { from: "ㅝ", input: "ㅣ", to: "ㅞ" }
              - { from: "ㅜ", input: "ㅣ", to: "ㅟ" }
              - { from: "ㅡ", input: "ㅣ", to: "ㅢ" }
            display:
              "ㅣ": "\\u1175"
              "ㆍ": "\\u119E"
              "ᆢ": "\\u11A2"
              "ㅡ": "\\u1173"
              "ㅏ": "\\u1161"
              "ㅑ": "\\u1163"
              "ㅓ": "\\u1165"
              "ㅕ": "\\u1167"
              "ㅗ": "\\u1169"
              "ㅛ": "\\u116D"
              "ㅜ": "\\u116E"
              "ㅠ": "\\u1172"
              "ㅐ": "\\u1162"
              "ㅒ": "\\u1164"
              "ㅔ": "\\u1166"
              "ㅖ": "\\u1168"
              "ㅚ": "\\u116C"
              "ㅘ": "\\u116A"
              "ㅙ": "\\u116B"
              "ㅝ": "\\u116F"
              "ㅞ": "\\u1170"
              "ㅟ": "\\u1171"
              "ㅢ": "\\u1174"
          jongseong:
            transitions:
              - { from: "", input: "ㄱ", to: "ㄱ" }
              - { from: "", input: "ㄴ", to: "ㄴ" }
              - { from: "", input: "ㄷ", to: "ㄷ" }
              - { from: "", input: "ㅂ", to: "ㅂ" }
              - { from: "", input: "ㅅ", to: "ㅅ" }
              - { from: "", input: "ㅈ", to: "ㅈ" }
              - { from: "", input: "ㅇ", to: "ㅇ" }
              - { from: "ㄱ", input: "ㄱ", to: "ㅋ" }
              - { from: "ㅋ", input: "ㄱ", to: "ㄲ" }
              - { from: "ㄴ", input: "ㄴ", to: "ㄹ" }
              - { from: "ㄷ", input: "ㄷ", to: "ㅌ" }
              - { from: "ㅌ", input: "ㄷ", to: "ㄸ" }
              - { from: "ㅂ", input: "ㅂ", to: "ㅍ" }
              - { from: "ㅍ", input: "ㅂ", to: "ㅃ" }
              - { from: "ㅅ", input: "ㅅ", to: "ㅎ" }
              - { from: "ㅎ", input: "ㅅ", to: "ㅆ" }
              - { from: "ㅈ", input: "ㅈ", to: "ㅊ" }
              - { from: "ㅊ", input: "ㅈ", to: "ㅉ" }
              - { from: "ㅇ", input: "ㅇ", to: "ㅁ" }
              - { from: "ㄱ", input: "ㅅ", to: "ㄳ" }
              - { from: "ㄴ", input: "ㅈ", to: "ㄵ" }
              - { from: "ㄴ", input: "ㅅ", to: "ㄴㅅ" }
              - { from: "ㄴㅅ", input: "ㅅ", to: "ㅀ" }
              - { from: "ㄹ", input: "ㄱ", to: "ㄺ" }
              - { from: "ㄹ", input: "ㅇ", to: "ㄹㅇ" }
              - { from: "ㄹㅇ", input: "ㅇ", to: "ㄻ" }
              - { from: "ㄹ", input: "ㅂ", to: "ㄼ" }
              - { from: "ㄹ", input: "ㅅ", to: "ㄽ" }
              - { from: "ㄹ", input: "ㄷ", to: "ㄹㄷ" }
              - { from: "ㄹㄷ", input: "ㄷ", to: "ㄾ" }
              - { from: "ㄼ", input: "ㅂ", to: "ㄿ" }
              - { from: "ㄽ", input: "ㅅ", to: "ㅀ" }
              - { from: "ㅂ", input: "ㅅ", to: "ㅄ" }
            display:
              "ㄱ": "\\u11A8"
              "ㄲ": "\\u11A9"
              "ㄳ": "\\u11AA"
              "ㄴ": "\\u11AB"
              "ㄵ": "\\u11AC"
              "ㅀ": "\\u11AD"
              "ㄷ": "\\u11AE"
              "ㄹ": "\\u11AF"
              "ㄺ": "\\u11B0"
              "ㄻ": "\\u11B1"
              "ㄼ": "\\u11B2"
              "ㄽ": "\\u11B3"
              "ㄾ": "\\u11B4"
              "ㄿ": "\\u11B5"
              "ㅁ": "\\u11B7"
              "ㅂ": "\\u11B8"
              "ㅄ": "\\u11B9"
              "ㅅ": "\\u11BA"
              "ㅆ": "\\u11BB"
              "ㅇ": "\\u11BC"
              "ㅈ": "\\u11BD"
              "ㅊ": "\\u11BE"
              "ㅋ": "\\u11BF"
              "ㅌ": "\\u11C0"
              "ㅍ": "\\u11C1"
              "ㅎ": "\\u11C2"
              "ㄸ": "\\u11AE\\u11AE"
              "ㅃ": "\\u11B8\\u11B8"
              "ㅉ": "\\u11BD\\u11BD"
              "ㄴㅅ": "\\u11AB\\u11BA"
              "ㄹㅇ": "\\u11AF\\u11BC"
              "ㄹㄷ": "\\u11AF\\u11AE"
          dokkaebibul:
            transitions:
              - { jongseong: "ㄳ", remaining: "ㄱ", moved: "ㅅ" }
              - { jongseong: "ㄵ", remaining: "ㄴ", moved: "ㅈ" }
              - { jongseong: "ㅀ", remaining: "ㄴ", moved: "ㅎ" }
              - { jongseong: "ㄺ", remaining: "ㄹ", moved: "ㄱ" }
              - { jongseong: "ㄻ", remaining: "ㄹ", moved: "ㅁ" }
              - { jongseong: "ㄼ", remaining: "ㄹ", moved: "ㅂ" }
              - { jongseong: "ㄽ", remaining: "ㄹ", moved: "ㅅ" }
              - { jongseong: "ㄾ", remaining: "ㄹ", moved: "ㅌ" }
              - { jongseong: "ㄿ", remaining: "ㄹ", moved: "ㅍ" }
              - { jongseong: "ㅄ", remaining: "ㅂ", moved: "ㅅ" }
              - { jongseong: "ㄴㅅ", remaining: "ㄴ", moved: "ㅅ" }
              - { jongseong: "ㄹㅇ", remaining: "ㄹ", moved: "ㅇ" }
              - { jongseong: "ㄹㄷ", remaining: "ㄹ", moved: "ㄷ" }
              - { jongseong: "ㄸ", remaining: "ㄷ", moved: "ㄷ" }
              - { jongseong: "ㅃ", remaining: "ㅂ", moved: "ㅂ" }
              - { jongseong: "ㅉ", remaining: "ㅈ", moved: "ㅈ" }
              - { jongseong: "ㄱ", remaining: null, moved: "ㄱ" }
              - { jongseong: "ㄴ", remaining: null, moved: "ㄴ" }
              - { jongseong: "ㄷ", remaining: null, moved: "ㄷ" }
              - { jongseong: "ㄹ", remaining: null, moved: "ㄹ" }
              - { jongseong: "ㅁ", remaining: null, moved: "ㅁ" }
              - { jongseong: "ㅂ", remaining: null, moved: "ㅂ" }
              - { jongseong: "ㅅ", remaining: null, moved: "ㅅ" }
              - { jongseong: "ㅇ", remaining: null, moved: "ㅇ" }
              - { jongseong: "ㅈ", remaining: null, moved: "ㅈ" }
              - { jongseong: "ㅊ", remaining: null, moved: "ㅊ" }
              - { jongseong: "ㅋ", remaining: null, moved: "ㅋ" }
              - { jongseong: "ㅌ", remaining: null, moved: "ㅌ" }
              - { jongseong: "ㅍ", remaining: null, moved: "ㅍ" }
              - { jongseong: "ㅎ", remaining: null, moved: "ㅎ" }
              - { jongseong: "ㄲ", remaining: null, moved: "ㄲ" }
              - { jongseong: "ㅆ", remaining: null, moved: "ㅆ" }
          backspace:
            transitions:
              - { from: "ᆢ", to: "ㆍ" }
              - { from: "ㅏ", to: "ㅣ" }
              - { from: "ㅑ", to: "ㅏ" }
              - { from: "ㅓ", to: "ㆍ" }
              - { from: "ㅕ", to: "ᆢ" }
              - { from: "ㅗ", to: "ㆍ" }
              - { from: "ㅛ", to: "ᆢ" }
              - { from: "ㅜ", to: "ㅡ" }
              - { from: "ㅠ", to: "ㅜ" }
              - { from: "ㅐ", to: "ㅏ" }
              - { from: "ㅒ", to: "ㅑ" }
              - { from: "ㅔ", to: "ㅓ" }
              - { from: "ㅖ", to: "ㅕ" }
              - { from: "ㅚ", to: "ㅗ" }
              - { from: "ㅘ", to: "ㅚ" }
              - { from: "ㅙ", to: "ㅘ" }
              - { from: "ㅝ", to: "ㅠ" }
              - { from: "ㅞ", to: "ㅝ" }
              - { from: "ㅟ", to: "ㅜ" }
              - { from: "ㅢ", to: "ㅡ" }
              - { from: "ㄳ", to: "ㄱ" }
              - { from: "ㄵ", to: "ㄴ" }
              - { from: "ㅀ", to: "ㄴㅅ" }
              - { from: "ㄴㅅ", to: "ㄴ" }
              - { from: "ㄺ", to: "ㄹ" }
              - { from: "ㄻ", to: "ㄹㅇ" }
              - { from: "ㄹㅇ", to: "ㄹ" }
              - { from: "ㄼ", to: "ㄹ" }
              - { from: "ㄽ", to: "ㄹ" }
              - { from: "ㄾ", to: "ㄹㄷ" }
              - { from: "ㄹㄷ", to: "ㄹ" }
              - { from: "ㄿ", to: "ㄼ" }
              - { from: "ㅄ", to: "ㅂ" }
          specialCharacter:
            transitions:
              - { from: "", input: ".", to: "." }
              - { from: ".", input: ".", to: "," }
              - { from: ",", input: ".", to: "?" }
              - { from: "?", input: ".", to: "!" }
            display:
              ".": "."
              ",": ","
              "?": "?"
              "!": "!"
        """
    }
    
    private var standardDubeolsikTestYAML: String {
        """
        name: "표준 두벌식"
        identifier: "standard-dubeolsik"
        config:
          orderMode: "sequential"
          commitUnit: "syllable"
          displayMode: "modernMultiple"
          supportStandaloneCluster: false
        layout:
          r: { identifier: "ㄱ", label: "ㄱ" }
          R: { identifier: "ㄲ", label: "ㄲ" }
          s: { identifier: "ㄴ", label: "ㄴ" }
          e: { identifier: "ㄷ", label: "ㄷ" }
          E: { identifier: "ㄸ", label: "ㄸ" }
          f: { identifier: "ㄹ", label: "ㄹ" }
          a: { identifier: "ㅁ", label: "ㅁ" }
          q: { identifier: "ㅂ", label: "ㅂ" }
          Q: { identifier: "ㅃ", label: "ㅃ" }
          t: { identifier: "ㅅ", label: "ㅅ" }
          T: { identifier: "ㅆ", label: "ㅆ" }
          d: { identifier: "ㅇ", label: "ㅇ" }
          w: { identifier: "ㅈ", label: "ㅈ" }
          W: { identifier: "ㅉ", label: "ㅉ" }
          c: { identifier: "ㅊ", label: "ㅊ" }
          z: { identifier: "ㅋ", label: "ㅋ" }
          x: { identifier: "ㅌ", label: "ㅌ" }
          v: { identifier: "ㅍ", label: "ㅍ" }
          g: { identifier: "ㅎ", label: "ㅎ" }
          k: { identifier: "ㅏ", label: "ㅏ" }
          o: { identifier: "ㅐ", label: "ㅐ" }
          i: { identifier: "ㅑ", label: "ㅑ" }
          O: { identifier: "ㅒ", label: "ㅒ" }
          j: { identifier: "ㅓ", label: "ㅓ" }
          p: { identifier: "ㅔ", label: "ㅔ" }
          u: { identifier: "ㅕ", label: "ㅕ" }
          P: { identifier: "ㅖ", label: "ㅖ" }
          h: { identifier: "ㅗ", label: "ㅗ" }
          y: { identifier: "ㅛ", label: "ㅛ" }
          n: { identifier: "ㅜ", label: "ㅜ" }
          b: { identifier: "ㅠ", label: "ㅠ" }
          m: { identifier: "ㅡ", label: "ㅡ" }
          l: { identifier: "ㅣ", label: "ㅣ" }
        automata:
          choseong:
            transitions:
              - { from: "", input: "ㄱ", to: "ㄱ" }
              - { from: "", input: "ㄲ", to: "ㄲ" }
              - { from: "", input: "ㄴ", to: "ㄴ" }
              - { from: "", input: "ㄷ", to: "ㄷ" }
              - { from: "", input: "ㄸ", to: "ㄸ" }
              - { from: "", input: "ㄹ", to: "ㄹ" }
              - { from: "", input: "ㅁ", to: "ㅁ" }
              - { from: "", input: "ㅂ", to: "ㅂ" }
              - { from: "", input: "ㅃ", to: "ㅃ" }
              - { from: "", input: "ㅅ", to: "ㅅ" }
              - { from: "", input: "ㅆ", to: "ㅆ" }
              - { from: "", input: "ㅇ", to: "ㅇ" }
              - { from: "", input: "ㅈ", to: "ㅈ" }
              - { from: "", input: "ㅉ", to: "ㅉ" }
              - { from: "", input: "ㅊ", to: "ㅊ" }
              - { from: "", input: "ㅋ", to: "ㅋ" }
              - { from: "", input: "ㅌ", to: "ㅌ" }
              - { from: "", input: "ㅍ", to: "ㅍ" }
              - { from: "", input: "ㅎ", to: "ㅎ" }
            display:
              "ㄱ": "\\u1100"
              "ㄲ": "\\u1101"
              "ㄴ": "\\u1102"
              "ㄷ": "\\u1103"
              "ㄸ": "\\u1104"
              "ㄹ": "\\u1105"
              "ㅁ": "\\u1106"
              "ㅂ": "\\u1107"
              "ㅃ": "\\u1108"
              "ㅅ": "\\u1109"
              "ㅆ": "\\u110A"
              "ㅇ": "\\u110B"
              "ㅈ": "\\u110C"
              "ㅉ": "\\u110D"
              "ㅊ": "\\u110E"
              "ㅋ": "\\u110F"
              "ㅌ": "\\u1110"
              "ㅍ": "\\u1111"
              "ㅎ": "\\u1112"
          jungseong:
            transitions:
              - { from: "", input: "ㅏ", to: "ㅏ" }
              - { from: "", input: "ㅐ", to: "ㅐ" }
              - { from: "", input: "ㅑ", to: "ㅑ" }
              - { from: "", input: "ㅒ", to: "ㅒ" }
              - { from: "", input: "ㅓ", to: "ㅓ" }
              - { from: "", input: "ㅔ", to: "ㅔ" }
              - { from: "", input: "ㅕ", to: "ㅕ" }
              - { from: "", input: "ㅖ", to: "ㅖ" }
              - { from: "", input: "ㅗ", to: "ㅗ" }
              - { from: "", input: "ㅛ", to: "ㅛ" }
              - { from: "", input: "ㅜ", to: "ㅜ" }
              - { from: "", input: "ㅠ", to: "ㅠ" }
              - { from: "", input: "ㅡ", to: "ㅡ" }
              - { from: "", input: "ㅣ", to: "ㅣ" }
              - { from: "ㅗ", input: "ㅏ", to: "ㅘ" }
              - { from: "ㅗ", input: "ㅐ", to: "ㅙ" }
              - { from: "ㅗ", input: "ㅣ", to: "ㅚ" }
              - { from: "ㅜ", input: "ㅓ", to: "ㅝ" }
              - { from: "ㅜ", input: "ㅔ", to: "ㅞ" }
              - { from: "ㅜ", input: "ㅣ", to: "ㅟ" }
              - { from: "ㅡ", input: "ㅣ", to: "ㅢ" }
            display:
              "ㅏ": "\\u1161"
              "ㅐ": "\\u1162"
              "ㅑ": "\\u1163"
              "ㅒ": "\\u1164"
              "ㅓ": "\\u1165"
              "ㅔ": "\\u1166"
              "ㅕ": "\\u1167"
              "ㅖ": "\\u1168"
              "ㅗ": "\\u1169"
              "ㅘ": "\\u116A"
              "ㅙ": "\\u116B"
              "ㅚ": "\\u116C"
              "ㅛ": "\\u116D"
              "ㅜ": "\\u116E"
              "ㅝ": "\\u116F"
              "ㅞ": "\\u1170"
              "ㅟ": "\\u1171"
              "ㅠ": "\\u1172"
              "ㅡ": "\\u1173"
              "ㅢ": "\\u1174"
              "ㅣ": "\\u1175"
          jongseong:
            transitions:
              - { from: "", input: "ㄱ", to: "ㄱ" }
              - { from: "", input: "ㄲ", to: "ㄲ" }
              - { from: "", input: "ㄴ", to: "ㄴ" }
              - { from: "", input: "ㄷ", to: "ㄷ" }
              - { from: "", input: "ㄹ", to: "ㄹ" }
              - { from: "", input: "ㅁ", to: "ㅁ" }
              - { from: "", input: "ㅂ", to: "ㅂ" }
              - { from: "", input: "ㅅ", to: "ㅅ" }
              - { from: "", input: "ㅆ", to: "ㅆ" }
              - { from: "", input: "ㅇ", to: "ㅇ" }
              - { from: "", input: "ㅈ", to: "ㅈ" }
              - { from: "", input: "ㅊ", to: "ㅊ" }
              - { from: "", input: "ㅋ", to: "ㅋ" }
              - { from: "", input: "ㅌ", to: "ㅌ" }
              - { from: "", input: "ㅍ", to: "ㅍ" }
              - { from: "", input: "ㅎ", to: "ㅎ" }
              - { from: "ㄱ", input: "ㅅ", to: "ㄳ" }
              - { from: "ㄴ", input: "ㅈ", to: "ㄵ" }
              - { from: "ㄴ", input: "ㅎ", to: "ㄶ" }
              - { from: "ㄹ", input: "ㄱ", to: "ㄺ" }
              - { from: "ㄹ", input: "ㅁ", to: "ㄻ" }
              - { from: "ㄹ", input: "ㅂ", to: "ㄼ" }
              - { from: "ㄹ", input: "ㅅ", to: "ㄽ" }
              - { from: "ㄹ", input: "ㅌ", to: "ㄾ" }
              - { from: "ㄹ", input: "ㅍ", to: "ㄿ" }
              - { from: "ㄹ", input: "ㅎ", to: "ㅀ" }
              - { from: "ㅂ", input: "ㅅ", to: "ㅄ" }
            display:
              "ㄱ": "\\u11A8"
              "ㄲ": "\\u11A9"
              "ㄳ": "\\u11AA"
              "ㄴ": "\\u11AB"
              "ㄵ": "\\u11AC"
              "ㄶ": "\\u11AD"
              "ㄷ": "\\u11AE"
              "ㄹ": "\\u11AF"
              "ㄺ": "\\u11B0"
              "ㄻ": "\\u11B1"
              "ㄼ": "\\u11B2"
              "ㄽ": "\\u11B3"
              "ㄾ": "\\u11B4"
              "ㄿ": "\\u11B5"
              "ㅀ": "\\u11B6"
              "ㅁ": "\\u11B7"
              "ㅂ": "\\u11B8"
              "ㅄ": "\\u11B9"
              "ㅅ": "\\u11BA"
              "ㅆ": "\\u11BB"
              "ㅇ": "\\u11BC"
              "ㅈ": "\\u11BD"
              "ㅊ": "\\u11BE"
              "ㅋ": "\\u11BF"
              "ㅌ": "\\u11C0"
              "ㅍ": "\\u11C1"
              "ㅎ": "\\u11C2"
          dokkaebibul:
            transitions:
              - { jongseong: "ㄱ", remaining: null, moved: "ㄱ" }
              - { jongseong: "ㄲ", remaining: null, moved: "ㄲ" }
              - { jongseong: "ㄴ", remaining: null, moved: "ㄴ" }
              - { jongseong: "ㄷ", remaining: null, moved: "ㄷ" }
              - { jongseong: "ㄹ", remaining: null, moved: "ㄹ" }
              - { jongseong: "ㅁ", remaining: null, moved: "ㅁ" }
              - { jongseong: "ㅂ", remaining: null, moved: "ㅂ" }
              - { jongseong: "ㅅ", remaining: null, moved: "ㅅ" }
              - { jongseong: "ㅆ", remaining: null, moved: "ㅆ" }
              - { jongseong: "ㅇ", remaining: null, moved: "ㅇ" }
              - { jongseong: "ㅈ", remaining: null, moved: "ㅈ" }
              - { jongseong: "ㅊ", remaining: null, moved: "ㅊ" }
              - { jongseong: "ㅋ", remaining: null, moved: "ㅋ" }
              - { jongseong: "ㅌ", remaining: null, moved: "ㅌ" }
              - { jongseong: "ㅍ", remaining: null, moved: "ㅍ" }
              - { jongseong: "ㅎ", remaining: null, moved: "ㅎ" }
              - { jongseong: "ㄳ", remaining: "ㄱ", moved: "ㅅ" }
              - { jongseong: "ㄵ", remaining: "ㄴ", moved: "ㅈ" }
              - { jongseong: "ㄶ", remaining: "ㄴ", moved: "ㅎ" }
              - { jongseong: "ㄺ", remaining: "ㄹ", moved: "ㄱ" }
              - { jongseong: "ㄻ", remaining: "ㄹ", moved: "ㅁ" }
              - { jongseong: "ㄼ", remaining: "ㄹ", moved: "ㅂ" }
              - { jongseong: "ㄽ", remaining: "ㄹ", moved: "ㅅ" }
              - { jongseong: "ㄾ", remaining: "ㄹ", moved: "ㅌ" }
              - { jongseong: "ㄿ", remaining: "ㄹ", moved: "ㅍ" }
              - { jongseong: "ㅀ", remaining: "ㄹ", moved: "ㅎ" }
              - { jongseong: "ㅄ", remaining: "ㅂ", moved: "ㅅ" }
        """
    }
}