//
//  StandardDubeolsikTests.swift
//  MetaHangulIMETests
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
            (["r", "k", "s"], "간", "간"),
            (["g", "k", "s"], "한", "한"),
            (["r", "m", "f"], "글", "글"),
            (["d", "j"], "어", "어"),
            (["a", "o", "s"], "맨", "맨")
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
            (["r", "h", "k"], "과", "과"),
            (["r", "h", "o"], "괘", "괘"),
            (["r", "h", "l"], "괴", "괴"),
            (["r", "n", "j"], "궈", "궈"),
            (["r", "n", "p"], "궤", "궤"),
            (["r", "n", "l"], "귀", "귀"),
            (["r", "m", "l"], "긔", "긔")
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
            (["r", "k", "r", "t"], "갃", "갃"),
            (["s", "o", "r"], "낵", "낵"),
            (["s", "o", "R"], "낶", "낶"),
            (["e", "k", "f", "r"], "닭", "닭"),
            (["e", "k", "f", "a"], "닮", "닮"),
            (["e", "k", "f", "q"], "닯", "닯"),
            (["e", "k", "f", "t"], "닰", "닰"),
            (["e", "k", "f", "x"], "닱", "닱"),
            (["e", "k", "f", "v"], "닲", "닲"),
            (["e", "k", "f", "g"], "닳", "닳"),
            (["r", "k", "q", "t"], "값", "값")
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
            (["r", "k", "r", "l"], "가기", "가기 (ㄱ+ㅏ+ㄱ → ㄱ+ㅏ / ㄱ+ㅣ)"),
            (["r", "k", "s", "l"], "가니", "가니 (ㄱ+ㅏ+ㄴ → ㄱ+ㅏ / ㄴ+ㅣ)"),
            
            // Compound consonant dokkaebi
            (["r", "k", "r", "t", "l"], "각시", "각시 (ㄱ+ㅏ+ㄳ → ㄱ+ㅏ+ㄱ / ㅅ+ㅣ)"),
            (["e", "k", "f", "r", "l"], "달기", "달기 (ㄷ+ㅏ+ㄺ → ㄷ+ㅏ+ㄹ / ㄱ+ㅣ)"),
            (["e", "k", "f", "a", "l"], "달미", "달미 (ㄷ+ㅏ+ㄻ → ㄷ+ㅏ+ㄹ / ㅁ+ㅣ)"),
            
            // No dokkaebi when jongseong can combine
            (["r", "k", "s", "w"], "갅", "갅 (ㄱ+ㅏ+ㄴ+ㅈ → ㄱ+ㅏ+ㄵ)")
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
        
        _ = ime.input("r")  // ㄱ
        _ = ime.input("k")  // 가
        _ = ime.input("s")  // 간
        var result = ime.backspace()  // Should be 가
        
        XCTAssertEqual(result, "가", "Simple backspace failed")
        
        // Test 2: Backspace after dokkaebi
        ime.reset()
        capturedCommitText = ""
        
        _ = ime.input("r")  // ㄱ
        _ = ime.input("k")  // 가
        _ = ime.input("r")  // 각
        _ = ime.input("t")  // 갃
        _ = ime.input("l")  // 각시 (dokkaebi)
        result = ime.backspace()  // Should backspace 시 -> 각ㅅ
        
        _ = ime.forceCommit()
        let finalText = capturedCommitText
        XCTAssertEqual(finalText, "각ㅅ", "Backspace after dokkaebi failed")
        
        // Test 3: Multiple backspaces
        ime.reset()
        capturedCommitText = ""
        
        _ = ime.input("g")  // ㅎ
        _ = ime.input("k")  // 하
        _ = ime.input("s")  // 한
        _ = ime.backspace()  // 하
        _ = ime.backspace()  // ㅎ
        result = ime.backspace()  // empty
        
        XCTAssertEqual(result, "", "Multiple backspaces failed")
    }
    
    // MARK: - Non-Hangul Input Tests
    
    func testNonHangulInput() {
        ime.reset()
        capturedCommitText = ""
        
        _ = ime.input("r")  // ㄱ
        _ = ime.input("k")  // 가
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
        _ = ime.input("g")  // ㅎ
        _ = ime.input("k")  // 하
        _ = ime.input("s")  // 한
        let result1 = ime.input("r")  // 한 committed, ㄱ
        
        XCTAssertEqual(capturedCommitText, "한", "First syllable not committed")
        XCTAssertEqual(result1, "ㄱ", "Second syllable initial not correct")
        
        _ = ime.input("m")  // 그
        let result2 = ime.input("f")  // 글
        
        _ = ime.forceCommit()
        let finalText = capturedCommitText
        XCTAssertEqual(finalText, "한글", "Sequential syllables failed")
    }

    /// MARK: - Commit Tests

    func testCommit() {
        ime.reset()
        capturedCommitText = ""
        
        // Type "한글" (한 + 글)
        _ = ime.input("g")  // ㅎ
        _ = ime.input("k")  // 하
        _ = ime.input("s")  // 한
        _ = ime.input("r")  // ㄱ
        _ = ime.input("m")  // 그
        _ = ime.input("f")  // 글
        
        XCTAssertEqual(capturedCommitText, "한", "Commit failed")

        _ = ime.input("r") // ㄱ
        
        XCTAssertEqual(capturedCommitText, "한", "Commit failed")

        _ = ime.input("h") // 고
        
        XCTAssertEqual(capturedCommitText, "한글", "Commit failed")

        _ = ime.input("k") // 과
        
        XCTAssertEqual(capturedCommitText, "한글", "Commit failed")

        let commitString = ime.forceCommit()  // Should commit "글"
        XCTAssertEqual(commitString, "과", "Commit string not correct")
        XCTAssertEqual(capturedCommitText, "한글과", "Final commit text not correct")
    }
}

// MARK: - KoreanIMEDelegate

extension StandardDubeolsikTests: KoreanIMEDelegate {
    func koreanIME(_ ime: KoreanIME, didCommitText text: String) {
        capturedCommitText += text
    }
    
    func koreanIME(_ ime: KoreanIME, requestBackspace: Void) {
        // 테스트에서는 백스페이스 요청을 무시
        // 실제 애플리케이션에서는 여기서 OS 백스페이스를 호출해야 함
    }
}