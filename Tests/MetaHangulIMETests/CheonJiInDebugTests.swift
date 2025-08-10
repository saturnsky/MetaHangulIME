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
        if let nonJamo = state.nonJamoState {
            parts.append("nonJamo:'\(nonJamo)'")
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
            ("ㅅ", "ㅅ"),
            ("ㅅ", "ㅎ"),
            ("ㅣ", "히"),
            ("ㆍ", "하"),
            ("ㄴ", "한"),
            ("ㄴ", "할"),
            ("ㄷ", "할ㄷ"),  // 여기서 실패
            ("ㄷ", "핥"),
            ("ㄷ", "핥ㄷ"),
            ("ㅣ", "핥디"),
            ("ㆍ", "핥다"),
        ]

        for (key, expected) in steps {
            let result = ime.input(key)
            printStateTransition(key: key, result: result, expected: expected)

            if result != expected {
                print("❌ FAILED: Expected '\(expected)' but got '\(result)'")

                // 실패 케이스에 대한 추가 디버그
                if key == "ㄷ" && expected == "할ㄷ" {
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
            ("ㄷ", "ㄷ", "초기 ㄷ"),
            ("ㆍ", "ㄷㆍ", "ㄷ + ㆍ"),
            ("ㅡ", "도", "도 완성"),
            ("ㅇ", "동", "동 완성"),
            ("ㅅ", "동ㅅ", "동 + ㅅ 새 음절로"),
            ("ㅅ", "동ㅎ", "ㅅ + ㅅ = ㅎ"),
            ("ㅣ", "동히", "ㅎ + ㅣ = 히"),
            ("ㆍ", "동하", "히 -> 하"),
            ("ㅣ", "동해", "하 -> 해"),
        ]

        for (key, expected, description) in steps {
            let result = ime.input(key)
            print("\n--- \(description) ---")
            printStateTransition(key: key, result: result, expected: expected)

            if result != expected {
                print("❌ FAILED: Expected '\(expected)' but got '\(result)'")

                // ㅅ + ㅅ = ㅎ 전이에 대한 특별 디버깅
                if key == "ㅅ" && expected == "동ㅎ" && result == "동ㅅㅅ" {
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
        _ = ime.input("ㄴ")  // ㄴ
        _ = ime.input("ㅣ")  // 니
        _ = ime.input("ㆍ")  // 나
        _ = ime.input("ㄴ")  // 난
        let result1 = ime.input("ㅅ")  // 난ㅅ (중간 상태)
        printStateTransition(key: "ㅅ", result: result1, expected: "난ㅅ")

        let result2 = ime.input("ㅅ")  // 낳이 되어야 함 (ㄴ + ㅅ + ㅅ = ㄵ)
        printStateTransition(key: "ㅅ", result: result2, expected: "낳")

        // ㄹㅇ -> ㄻ 테스트
        print("\n--- ㄹㅇ -> ㄻ 테스트 ---")
        ime.reset()
        _ = ime.input("ㄴ")  // ㄴ
        _ = ime.input("ㄴ")  // ㄹ
        _ = ime.input("ㅣ")  // 리
        _ = ime.input("ㆍ")  // 라
        _ = ime.input("ㄴ")  // 란
        _ = ime.input("ㄴ")  // 랄
        let result3 = ime.input("ㅇ")  // 랄ㅇ (중간 상태)
        printStateTransition(key: "ㅇ", result: result3, expected: "랄ㅇ")

        let result4 = ime.input("ㅇ")  // 랆이 되어야 함 (ㄹ + ㅇ + ㅇ = ㄻ)
        printStateTransition(key: "ㅇ", result: result4, expected: "랆")
    }

    func testBackspaceDebug() {
        print("\n=== 백스페이스 디버귲 테스트 ===")

        // 괴를 단계별로 구성
        ime.reset()
        let r1 = ime.input("ㄱ")  // ㄱ
        print("After 'q': '\(r1)'")
        print("State: \(stateDescription(ime.currentState))")

        let r2 = ime.input("ㆍ")  // ㄱㆍ
        print("\nAfter '2': '\(r2)'")
        print("State: \(stateDescription(ime.currentState))")

        let r3 = ime.input("ㅡ")  // 고 (ㆍ + ㅡ = ㅗ)
        print("\nAfter '3': '\(r3)'")
        print("State: \(stateDescription(ime.currentState))")

        let r4 = ime.input("ㅣ")  // 괴 (ㅗ + ㅣ = ㅚ)
        print("\nAfter '1': '\(r4)'")
        print("State: \(stateDescription(ime.currentState))")

        // 이제 ㆍ 추가
        let r5 = ime.input("ㆍ")  // 과가 되어야 함 (ㅒ + ㆍ = ㅘ)
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
        _ = ime.input("ㄷ")  // ㄷ
        _ = ime.input("ㆍ")  // ㄷㆍ
        _ = ime.input("ㅡ")  // 도
        _ = ime.input("ㅇ")  // 동
        print("동 후:")
        print("  이전: \(stateDescription(ime.previousState))")
        print("  현재: \(stateDescription(ime.currentState))")

        _ = ime.input("ㅅ")  // 동ㅅ
        _ = ime.input("ㅅ")  // 동ㅎ
        _ = ime.input("ㅣ")  // 동히
        _ = ime.input("ㆍ")  // 동하
        _ = ime.input("ㅣ")  // 동해
        print("\n동해 후:")
        print("  이전: \(stateDescription(ime.previousState))")
        print("  현재: \(stateDescription(ime.currentState))")

        _ = ime.input("ㅇ")  // 동행
        _ = ime.input("ㅇ")  // 동햄
        _ = ime.input("ㅡ")  // 동해므
        _ = ime.input("ㆍ")  // 동해무
        _ = ime.input("ㄴ")  // 동해문
        let mul = ime.input("ㄴ")  // 동해물
        print("\n동해물 후: '\(mul)'")
        print("  이전: \(stateDescription(ime.previousState))")
        print("  현재: \(stateDescription(ime.currentState))")

        // 이제 과 추가
        _ = ime.input("ㄱ")  // 동해묽
        _ = ime.input("ㆍ")  // 동해물ㄱㆍ
        _ = ime.input("ㅡ")  // 동해물고
        _ = ime.input("ㅣ")  // 동해물괴
        let gwa = ime.input("ㆍ")  // 동해물과
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
