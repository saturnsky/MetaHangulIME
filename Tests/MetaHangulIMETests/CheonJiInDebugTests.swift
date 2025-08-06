//
//  CheonJiInDebugTests.swift
//  MetaHangulIME
//
//  상태 추적을 포함한 천지인 디버그 테스트
//

import XCTest
@testable import MetaHangulIME

final class CheonJiInDebugTests: XCTestCase {
    var ime: CheonJiIn!
    var capturedCommitText: String = ""

    override func setUp() {
        super.setUp()
        ime = CheonJiIn()
        capturedCommitText = ""
        // ime.onCommit은 사용할 수 없으므로 다른 방식으로 커밋을 추적
    }

    override func tearDown() {
        ime = nil
        super.tearDown()
    }

    // MARK: - 헬퍼 메서드

    func stateDescription(_ state: SyllableState?) -> String {
        guard let state = state else { return "nil" }

        var parts: [String] = []
        if let cho = state.choseongState {
            parts.append("cho:'\(cho)'")
        }
        if let jung = state.jungseongState {
            parts.append("jung:'\(jung)'")
        }
        if let jong = state.jongseongState {
            parts.append("jong:'\(jong)'")
        }
        if let special = state.specialCharacterState {
            parts.append("special:'\(special)'")
        }
        if !state.compositionOrder.isEmpty {
            let order = state.compositionOrder.map { String($0.rawValue) }.joined(separator: ",")
            parts.append("order:[\(order)]")
        }

        return "State(\(parts.joined(separator: ", ")))"
    }

    func printStateTransition(key: String, result: String, expected: String? = nil) {
        print("\n=== Input: '\(key)' ===")
        if let expected = expected {
            print("Result: '\(result)' (expected: '\(expected)')")
        } else {
            print("Result: '\(result)'")
        }
        print("Previous: \(stateDescription(ime.previousState))")
        print("Current:  \(stateDescription(ime.currentState))")

        // 현재 상태의 표시도 출력
        let display = ime.processor.buildDisplay(ime.currentState)
        print("Display:  '\(display)'")

        if !capturedCommitText.isEmpty {
            print("Committed so far: '\(capturedCommitText)'")
        }
    }

    // MARK: - 디버그 테스트

    func testDebug_halD() {
        print("\n========== Testing '할ㄷ' sequence ==========")
        ime.reset()
        capturedCommitText = ""

        let steps: [(key: String, expected: String)] = [
            ("s", "ㅅ"),
            ("s", "ㅎ"),
            ("1", "히"),
            ("2", "하"),
            ("w", "한"),
            ("w", "할"),
            ("e", "할ㄷ"),  // 여기서 실패
            ("e", "핥"),
            ("e", "핥ㄷ"),
            ("1", "핥디"),
            ("2", "핥다"),
        ]

        for (key, expected) in steps {
            let result = ime.input(key)
            printStateTransition(key: key, result: result, expected: expected)

            if result != expected {
                print("❌ FAILED: Expected '\(expected)' but got '\(result)'")

                // 실패 케이스에 대한 추가 디버그
                if key == "e" && expected == "할ㄷ" {
                    print("\n--- 할ㄷ 실패 디버깅 ---")
                    print("'ㄷ'은 '할' 뒤에 새 음절을 만들어야 함")
                    print("이전 음절은 '할'이고 현재는 'ㄷ'을 초성으로 가져야 함")
                }
            } else {
                print("✅ PASS")
            }
        }
    }

    func testDebug_donghaemulgwa() {
        print("\n========== 'ㅅ' 전이에 특별히 초점을 맞춰 '동해물과' 테스트 ==========")
        ime.reset()
        capturedCommitText = ""

        // 문제가 되는 부분에 초점: 동ㅅ -> 동ㅎ
        let steps: [(key: String, expected: String, description: String)] = [
            ("e", "ㄷ", "초기 ㄷ"),
            ("2", "ㄷㆍ", "ㄷ + ㆍ"),
            ("3", "도", "도 완성"),
            ("x", "동", "동 완성"),
            ("s", "동ㅅ", "동 + ㅅ 새 음절로"),
            ("s", "동ㅎ", "ㅅ + ㅅ = ㅎ"),
            ("1", "동히", "ㅎ + ㅣ = 히"),
            ("2", "동하", "히 -> 하"),
            ("1", "동해", "하 -> 해"),
        ]

        for (key, expected, description) in steps {
            let result = ime.input(key)
            print("\n--- \(description) ---")
            printStateTransition(key: key, result: result, expected: expected)

            if result != expected {
                print("❌ FAILED: Expected '\(expected)' but got '\(result)'")

                // ㅅ + ㅅ = ㅎ 전이에 대한 특별 디버깅
                if key == "s" && expected == "동ㅎ" && result == "동ㅅㅅ" {
                    print("\n--- ㅅ + ㅅ = ㅎ 실패 디버깅 ---")
                    print("두 번째 ㅅ는 첫 번째 ㅅ과 결합하여 ㅎ을 만들어야 함")
                    print("이는 초성 오토마타 전이가 작동하지 않음을 시사")
                }
            } else {
                print("✅ PASS")
            }
        }
    }

    func testDebug_multipleCharacterStates() {
        print("\n========== 다중 문자 상태 (ㄴㅅ, ㄹㅇ, ㄹㄷ) 테스트 ==========")
        ime.reset()
        capturedCommitText = ""

        // ㄴㅅ -> ㄵ 테스트
        print("\n--- ㄴㅅ -> ㄵ 테스트 ---")
        _ = ime.input("w")  // ㄴ
        _ = ime.input("1")  // 니
        _ = ime.input("2")  // 나
        _ = ime.input("w")  // 난
        let result1 = ime.input("s")  // 난ㅅ (중간 상태)
        printStateTransition(key: "s", result: result1, expected: "난ㅅ")

        let result2 = ime.input("s")  // 낳이 되어야 함 (ㄴ + ㅅ + ㅅ = ㄵ)
        printStateTransition(key: "s", result: result2, expected: "낳")

        // ㄹㅇ -> ㄻ 테스트
        print("\n--- ㄹㅇ -> ㄻ 테스트 ---")
        ime.reset()
        _ = ime.input("w")  // ㄴ
        _ = ime.input("w")  // ㄹ
        _ = ime.input("1")  // 리
        _ = ime.input("2")  // 라
        _ = ime.input("w")  // 란
        _ = ime.input("w")  // 랄
        let result3 = ime.input("x")  // 랄ㅇ (중간 상태)
        printStateTransition(key: "x", result: result3, expected: "랄ㅇ")

        let result4 = ime.input("x")  // 랆이 되어야 함 (ㄹ + ㅇ + ㅇ = ㄻ)
        printStateTransition(key: "x", result: result4, expected: "랆")
    }

    func testBackspaceDebug() {
        print("\n=== 백스페이스 디버귲 테스트 ===")

        // 괴를 단계별로 구성
        ime.reset()
        let r1 = ime.input("q")  // ㄱ
        print("After 'q': '\(r1)'")
        print("State: \(stateDescription(ime.currentState))")

        let r2 = ime.input("2")  // ㄱㆍ
        print("\nAfter '2': '\(r2)'")
        print("State: \(stateDescription(ime.currentState))")

        let r3 = ime.input("3")  // 고 (ㆍ + ㅡ = ㅗ)
        print("\nAfter '3': '\(r3)'")
        print("State: \(stateDescription(ime.currentState))")

        let r4 = ime.input("1")  // 괴 (ㅗ + ㅣ = ㅚ)
        print("\nAfter '1': '\(r4)'")
        print("State: \(stateDescription(ime.currentState))")

        // 이제 ㆍ 추가
        let r5 = ime.input("2")  // 과가 되어야 함 (ㅒ + ㆍ = ㅘ)
        print("\n=== 괴에 ㆍ 추가 ===")
        print("결과: '\(r5)' (예상: '과')")
        print("Previous: \(stateDescription(ime.previousState))")
        print("Current: \(stateDescription(ime.currentState))")

        let bs = ime.backspace()
        print("\n=== 백스페이스 ===")
        print("결과: '\(bs)' (예상: '괴')")
        print("Previous: \(stateDescription(ime.previousState))")
        print("Current: \(stateDescription(ime.currentState))")
    }

    func testDongHaeMulGwaSequence() {
        print("\n=== 동해물과 시퀀스 디버그 ===")
        ime.reset()

        // 동해물 구성
        _ = ime.input("e")  // ㄷ
        _ = ime.input("2")  // ㄷㆍ
        _ = ime.input("3")  // 도
        _ = ime.input("x")  // 동
        print("동 후:")
        print("  이전: \(stateDescription(ime.previousState))")
        print("  현재: \(stateDescription(ime.currentState))")

        _ = ime.input("s")  // 동ㅅ
        _ = ime.input("s")  // 동ㅎ
        _ = ime.input("1")  // 동히
        _ = ime.input("2")  // 동하
        _ = ime.input("1")  // 동해
        print("\n동해 후:")
        print("  이전: \(stateDescription(ime.previousState))")
        print("  현재: \(stateDescription(ime.currentState))")

        _ = ime.input("x")  // 동행
        _ = ime.input("x")  // 동햄
        _ = ime.input("3")  // 동해므
        _ = ime.input("2")  // 동해무
        _ = ime.input("w")  // 동해문
        let mul = ime.input("w")  // 동해물
        print("\n동해물 후: '\(mul)'")
        print("  이전: \(stateDescription(ime.previousState))")
        print("  현재: \(stateDescription(ime.currentState))")

        // 이제 과 추가
        _ = ime.input("q")  // 동해묽
        _ = ime.input("2")  // 동해물ㄱㆍ
        _ = ime.input("3")  // 동해물고
        _ = ime.input("1")  // 동해물괴
        let gwa = ime.input("2")  // 동해물과
        print("\n동해물과 후: '\(gwa)'")
        print("  이전: \(stateDescription(ime.previousState))")
        print("  현재: \(stateDescription(ime.currentState))")
        print("  조합 중인 텍스트: '\(ime.getComposingText())'")

        // 백스페이스
        let bs1 = ime.backspace()
        print("\n백스페이스 1: '\(bs1)' (예상: '동해물괴')")
        print("  이전: \(stateDescription(ime.previousState))")
        print("  현재: \(stateDescription(ime.currentState))")
    }
}
