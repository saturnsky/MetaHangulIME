//
//  CheonJiInPlusTests.swift
//  MetaHangulIME
//
//  Tests for CheonJiIn Plus IME
//

import XCTest
@testable import MetaHangulIME

final class CheonJiInPlusTests: XCTestCase {
    var ime: KoreanIME?
    var capturedCommitText: String = ""

    override func setUp() {
        super.setUp()
        capturedCommitText = ""
        ime = nil
    }

    override func tearDown() {
        ime = nil
        super.tearDown()
    }

    // MARK: - Basic Tests

    func testLoadCheonJiInPlus() throws {
        // Load CheonJiIn Plus from YAML configuration
        ime = try IMEFactory.createFromPreset(.cheonJiInPlus)
        ime?.delegate = self

        XCTAssertNotNil(ime, "IME should be loaded")

        if let configurableIME = ime as? ConfigurableKoreanIME {
            XCTAssertEqual(configurableIME.name, "천지인 플러스")
            XCTAssertEqual(configurableIME.identifier, "cheonjiin-plus")
        }
    }

    func testBasicInput() throws {
        let testIME = try IMEFactory.createFromPreset(.cheonJiInPlus)
        testIME.delegate = self
        ime = testIME

        // Test "간" = ㄱ + ㅏ + ㄴ
        _ = testIME.input("ㄱ")  // ㄱ
        _ = testIME.input("ㅣ")  // ㄱ + ㅣ
        _ = testIME.input("ㆍ")  // 가
        _ = testIME.input("ㄴ")  // 간

        _ = testIME.forceCommit()
        XCTAssertEqual(capturedCommitText, "간", "Should produce 간")
    }

    func testDoubleConsonants() throws {
        let testIME = try IMEFactory.createFromPreset(.cheonJiInPlus)
        testIME.delegate = self
        ime = testIME

        // Test "깐" = ㄲ + ㅏ + ㄴ (ㅋ + ㅋ = ㄲ)
        _ = testIME.input("ㅋ")  // ㅋ
        _ = testIME.input("ㅋ")  // ㄲ
        _ = testIME.input("ㅣ")  // ㄲ + ㅣ
        _ = testIME.input("ㆍ")  // 까
        _ = testIME.input("ㄴ")  // 깐

        _ = testIME.forceCommit()
        XCTAssertEqual(capturedCommitText, "깐", "Should produce 깐")
    }

    func testDokkaebi() throws {
        let testIME = try IMEFactory.createFromPreset(.cheonJiInPlus)
        testIME.delegate = self
        ime = testIME

        // Test "삐따뗀" = ㅍ+ㅍ+ㅣ+ㅌ+ㅌ+ㅣ+ㆍ+ㅌ+ㅌ+ㆍ+ㅣ+ㅣ+ㄴ
        let steps = [
            ("ㅍ", "ㅍ"),  // ㅍ
            ("ㅍ", "ㅃ"),  // ㅍ + ㅍ = ㅃ
            ("ㅣ", "삐"),  // 삐
            ("ㅌ", "삩"),  // 삐 + ㅌ = 삩
            ("ㅌ", "삐ㄸ"),  // 삩 + ㅌ = 삐ㄸ
            ("ㅣ", "삐띠"), // 삐ㄸ + ㅣ = 삐띠
            ("ㆍ", "삐따"), // 삐띠 + ㆍ = 삐따
            ("ㅌ", "삐땉"), // 삐따 + ㅌ = 삐땉
            ("ㅌ", "삐따ㄸ"), // 삐따 + ㅌ = 삐따ㄸ
            ("ㆍ", "삐따ㄸㆍ"), // 삐따ㄸ + ㆍ = 삐따ㄸㆍ
            ("ㅣ", "삐따떠"), // 삐따ㄸㆍ + ㅣ = 삐따떠
            ("ㅣ", "삐따떼"), // 삐따떠 + ㅣ = 삐따떼
            ("ㄴ", "삐따뗀"), // 삐따떼 + ㄴ = 삐따뗀
        ]
        for (key, expected) in steps {
            _ = testIME.input(key)
            let result = testIME.getComposingText()
            XCTAssertEqual(result, expected, "Failed for input \(key): expected \(expected), got \(result)")
        }
        _ = testIME.forceCommit()
        XCTAssertEqual(capturedCommitText, "삐따뗀", "Should produce 삐따뗀")
    }

    // Test many different commit sequences
    func testCommit() throws {
        let testIME = try IMEFactory.createFromPreset(.cheonJiInPlus)
        testIME.delegate = self
        ime = testIME

        // Test 1
        _ = testIME.input("ㅋ")  // ㅋ
        _ = testIME.input("ㅋ")  // ㄲ
        _ = testIME.input("ㅣ")  // 끼
        _ = testIME.input("ㆍ")  // 까
        _ = testIME.input("ㄴ")  // 깐
        _ = testIME.input(".,")  // 깐. 깐은 commit, .은 조합 중
        XCTAssertEqual(capturedCommitText, "깐", "Should produce 깐 after commit")
        var currentText = testIME.getComposingText()
        XCTAssertEqual(currentText, ".", "Should have composing text '.'")
        _ = testIME.input("?!")  // 깐.? 깐은 commit, .?은 조합 중
        currentText = testIME.getComposingText()
        XCTAssertEqual(capturedCommitText, "깐.", "Should produce 깐. after commit")
        XCTAssertEqual(currentText, "?", "Should have composing text '.?'")
        _ = testIME.forceCommit()
        XCTAssertEqual(capturedCommitText, "깐.?", "Should produce .?")
    }
}

// MARK: - KoreanIMEDelegate

extension CheonJiInPlusTests: KoreanIMEDelegate {
    func koreanIME(_ ime: KoreanIME, didCommitText text: String, composingText: String) {
        capturedCommitText += text
    }

    func koreanIME(_ ime: KoreanIME, requestBackspace: Void) {
        // Test에서는 백스페이스 요청을 무시
    }
}
