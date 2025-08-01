//
//  CheonJiIn.swift
//  MetaHangulIME
//
//  천지인 구현
//

import Foundation

/// 천지인 IME 구현
/// 천지인은 최소한의 키를 사용하는 모바일 한국어 입력 방식
public final class CheonJiIn: KoreanIME {
    
    public init() {
        let processor = CheonJiIn.createProcessor()
        let layout = CheonJiIn.createLayout()
        super.init(processor: processor, layout: layout)
    }
    
    // MARK: - 레이아웃 생성
    
    public static func createLayout() -> [String: VirtualKey] {
        return [
            // 자음
            "q": VirtualKey(keyIdentifier: "ㄱ", label: "ㄱ"),
            "w": VirtualKey(keyIdentifier: "ㄴ", label: "ㄴ"),
            "e": VirtualKey(keyIdentifier: "ㄷ", label: "ㄷ"),
            "a": VirtualKey(keyIdentifier: "ㅂ", label: "ㅂ"),
            "s": VirtualKey(keyIdentifier: "ㅅ", label: "ㅅ"),
            "d": VirtualKey(keyIdentifier: "ㅈ", label: "ㅈ"),
            "x": VirtualKey(keyIdentifier: "ㅇ", label: "ㅇ"),
            
            // 모음
            "1": VirtualKey(keyIdentifier: "ㅣ", label: "ㅣ"),
            "2": VirtualKey(keyIdentifier: "ㆍ", label: "ㆍ"),
            "3": VirtualKey(keyIdentifier: "ㅡ", label: "ㅡ"),
            
            // 특수문자
            "c": VirtualKey(keyIdentifier: ".", label: ".", isNonKorean: true)  // Python 구현과 일치
        ]
    }
    
    // MARK: - 프로세서 생성
    
    private static func createProcessor() -> InputProcessor {
        let choseongAutomaton = createChoseongAutomaton()
        let jungseongAutomaton = createJungseongAutomaton()
        let jongseongAutomaton = createJongseongAutomaton()
        let dokkaebiAutomaton = createDokkaebiAutomaton()
        let backspaceAutomaton = createBackspaceAutomaton()
        let specialCharacterAutomaton = createSpecialCharacterAutomaton()
        
        let config = InputProcessorConfig(
            orderMode: .sequential,
            commitUnit: .explicitCommit,  // 천지인은 명시적 커밋 사용
            displayMode: .modernMultiple,
            supportStandaloneCluster: true  // 천지인은 종성부용초성 지원
        )
        
        return InputProcessor(
            choseongAutomaton: choseongAutomaton,
            jungseongAutomaton: jungseongAutomaton,
            jongseongAutomaton: jongseongAutomaton,
            specialCharacterAutomaton: specialCharacterAutomaton,
            dokkaebiAutomaton: dokkaebiAutomaton,
            backspaceAutomaton: backspaceAutomaton,
            config: config
        )
    }
    
    // MARK: - 오토마타 생성
    
    private static func createChoseongAutomaton() -> ChoseongAutomaton {
        let automaton = ChoseongAutomaton()
        
        // 기본 자음
        let baseConsonants = ["ㄱ", "ㄴ", "ㄷ", "ㅂ", "ㅅ", "ㅈ", "ㅇ"]
        for consonant in baseConsonants {
            automaton.addTransition(from: "", input: consonant, to: consonant)
        }
        
        // cheonjiin.md에 따른 조합
        // ㄱ + ㄱ = ㅋ
        automaton.addTransition(from: "ㄱ", input: "ㄱ", to: "ㅋ")
        // ㅋ + ㄱ = ㄲ
        automaton.addTransition(from: "ㅋ", input: "ㄱ", to: "ㄲ")
        
        // ㄴ + ㄴ = ㄹ
        automaton.addTransition(from: "ㄴ", input: "ㄴ", to: "ㄹ")
        
        // ㄷ + ㄷ = ㅌ
        automaton.addTransition(from: "ㄷ", input: "ㄷ", to: "ㅌ")
        // ㅌ + ㄷ = ㄸ
        automaton.addTransition(from: "ㅌ", input: "ㄷ", to: "ㄸ")
        
        // ㅂ + ㅂ = ㅍ
        automaton.addTransition(from: "ㅂ", input: "ㅂ", to: "ㅍ")
        // ㅍ + ㅂ = ㅃ
        automaton.addTransition(from: "ㅍ", input: "ㅂ", to: "ㅃ")
        
        // ㅅ + ㅅ = ㅎ
        automaton.addTransition(from: "ㅅ", input: "ㅅ", to: "ㅎ")
        // ㅎ + ㅅ = ㅆ
        automaton.addTransition(from: "ㅎ", input: "ㅅ", to: "ㅆ")
        
        // ㅈ + ㅈ = ㅊ
        automaton.addTransition(from: "ㅈ", input: "ㅈ", to: "ㅊ")
        // ㅊ + ㅈ = ㅉ
        automaton.addTransition(from: "ㅊ", input: "ㅈ", to: "ㅉ")
        
        // ㅇ + ㅇ = ㅁ
        automaton.addTransition(from: "ㅇ", input: "ㅇ", to: "ㅁ")
        
        // 표시 매핑
        let displayMappings: [(state: String, display: String)] = [
            ("ㄱ", "\u{1100}"),  // ᄀ
            ("ㄲ", "\u{1101}"),  // ᄁ
            ("ㄴ", "\u{1102}"),  // ᄂ
            ("ㄷ", "\u{1103}"),  // ᄃ
            ("ㄸ", "\u{1104}"),  // ᄄ
            ("ㄹ", "\u{1105}"),  // ᄅ
            ("ㅁ", "\u{1106}"),  // ᄆ
            ("ㅂ", "\u{1107}"),  // ᄇ
            ("ㅃ", "\u{1108}"),  // ᄈ
            ("ㅅ", "\u{1109}"),  // ᄉ
            ("ㅆ", "\u{110A}"),  // ᄊ
            ("ㅇ", "\u{110B}"),  // ᄋ
            ("ㅈ", "\u{110C}"),  // ᄌ
            ("ㅉ", "\u{110D}"),  // ᄍ
            ("ㅊ", "\u{110E}"),  // ᄎ
            ("ㅋ", "\u{110F}"),  // ᄏ
            ("ㅌ", "\u{1110}"),  // ᄐ
            ("ㅍ", "\u{1111}"),  // ᄑ
            ("ㅎ", "\u{1112}")   // ᄒ
        ]
        
        for (state, display) in displayMappings {
            automaton.addDisplay(state: state, display: display)
        }
        
        return automaton
    }
    
    private static func createJungseongAutomaton() -> JungseongAutomaton {
        let automaton = JungseongAutomaton()
        // 기본 모음
        let baseVowels = ["ㆍ", "ㅡ", "ㅣ"]
        for vowel in baseVowels {
            automaton.addTransition(from: "", input: vowel, to: vowel)
        }

        // 표시 테이블 (내부 상태를 표시 문자로 매핑)
        automaton.addDisplay(state: "ㅣ", display: "\u{1175}")  // ᅵ
        automaton.addDisplay(state: "ㆍ", display: "\u{119E}")  // ᆞ
        automaton.addDisplay(state: "ᆢ", display: "\u{11A2}")  // ᆢ
        automaton.addDisplay(state: "ㅡ", display: "\u{1173}")  // ᅳ
        automaton.addDisplay(state: "ㅏ", display: "\u{1161}")  // ᅡ
        automaton.addDisplay(state: "ㅑ", display: "\u{1163}")  // ᅣ
        automaton.addDisplay(state: "ㅓ", display: "\u{1165}")  // ᅥ
        automaton.addDisplay(state: "ㅕ", display: "\u{1167}")  // ᅧ
        automaton.addDisplay(state: "ㅗ", display: "\u{1169}")  // ᅩ
        automaton.addDisplay(state: "ㅛ", display: "\u{116D}")  // ᅭ
        automaton.addDisplay(state: "ㅜ", display: "\u{116E}")  // ᅮ
        automaton.addDisplay(state: "ㅠ", display: "\u{1172}")  // ᅲ
        automaton.addDisplay(state: "ㅐ", display: "\u{1162}")  // ᅢ
        automaton.addDisplay(state: "ㅒ", display: "\u{1164}")  // ᅤ
        automaton.addDisplay(state: "ㅔ", display: "\u{1166}")  // ᅦ
        automaton.addDisplay(state: "ㅖ", display: "\u{1168}")  // ᅨ
        automaton.addDisplay(state: "ㅚ", display: "\u{116C}")  // ᅬ
        automaton.addDisplay(state: "ㅘ", display: "\u{116A}")  // ᅪ
        automaton.addDisplay(state: "ㅙ", display: "\u{116B}")  // ᅫ
        automaton.addDisplay(state: "ㅝ", display: "\u{116F}")  // ᅯ
        automaton.addDisplay(state: "ㅞ", display: "\u{1170}")  // ᅰ
        automaton.addDisplay(state: "ㅟ", display: "\u{1171}")  // ᅱ
        automaton.addDisplay(state: "ㅢ", display: "\u{1174}")  // ᅴ

        // 기본 모음
        automaton.addTransition(from: "", input: "ㅣ", to: "ㅣ")
        automaton.addTransition(from: "", input: "ㆍ", to: "ㆍ")
        automaton.addTransition(from: "", input: "ㅡ", to: "ㅡ")

        // cheonjiin.md에 따른 조합
        // ㆍ + ㆍ = ᆢ (이중 점)
        automaton.addTransition(from: "ㆍ", input: "ㆍ", to: "ᆢ")

        // ㅣ + ㆍ = ㅏ
        automaton.addTransition(from: "ㅣ", input: "ㆍ", to: "ㅏ")
        // ㅏ + ㆍ = ㅑ
        automaton.addTransition(from: "ㅏ", input: "ㆍ", to: "ㅑ")

        // ㆍ + ㅣ = ㅓ
        automaton.addTransition(from: "ㆍ", input: "ㅣ", to: "ㅓ")
        // ᆢ + ㅣ = ㅕ
        automaton.addTransition(from: "ᆢ", input: "ㅣ", to: "ㅕ")

        // ㆍ + ㅡ = ㅗ
        automaton.addTransition(from: "ㆍ", input: "ㅡ", to: "ㅗ")
        // ᆢ + ㅡ = ㅛ
        automaton.addTransition(from: "ᆢ", input: "ㅡ", to: "ㅛ")

        // ㅡ + ㆍ = ㅜ
        automaton.addTransition(from: "ㅡ", input: "ㆍ", to: "ㅜ")
        // ㅜ + ㆍ = ㅠ
        automaton.addTransition(from: "ㅜ", input: "ㆍ", to: "ㅠ")

        // 복합 모음
        // ㅏ + ㅣ = ㅐ
        automaton.addTransition(from: "ㅏ", input: "ㅣ", to: "ㅐ")
        // ㅑ + ㅣ = ㅒ
        automaton.addTransition(from: "ㅑ", input: "ㅣ", to: "ㅒ")
        // ㅓ + ㅣ = ㅔ
        automaton.addTransition(from: "ㅓ", input: "ㅣ", to: "ㅔ")
        // ㅕ + ㅣ = ㅖ
        automaton.addTransition(from: "ㅕ", input: "ㅣ", to: "ㅖ")

        // ㅒ + ㆍ = ㅘ (먼저 ㅗ + ㅣ = ㅒ 필요)
        automaton.addTransition(from: "ㅗ", input: "ㅣ", to: "ㅚ")
        automaton.addTransition(from: "ㅚ", input: "ㆍ", to: "ㅘ")
        // ㅘ + ㅣ = ㅙ
        automaton.addTransition(from: "ㅘ", input: "ㅣ", to: "ㅙ")

        // ㅠ + ㅣ = ㅝ
        automaton.addTransition(from: "ㅠ", input: "ㅣ", to: "ㅝ")
        // ㅝ + ㅣ = ㅞ
        automaton.addTransition(from: "ㅝ", input: "ㅣ", to: "ㅞ")
        // ㅜ + ㅣ = ㅟ
        automaton.addTransition(from: "ㅜ", input: "ㅣ", to: "ㅟ")
        // ㅡ + ㅣ = ㅢ
        automaton.addTransition(from: "ㅡ", input: "ㅣ", to: "ㅢ")
        
        return automaton
    }
    
    private static func createJongseongAutomaton() -> JongseongAutomaton {
        let automaton = JongseongAutomaton()
        
        // 기본 자음
        let baseConsonants = ["ㄱ", "ㄴ", "ㄷ", "ㅂ", "ㅅ", "ㅈ", "ㅇ"]
        for consonant in baseConsonants {
            automaton.addTransition(from: "", input: consonant, to: consonant)
        }

        // 단일 자음 조합 (초성과 동일)
        // ㄱ + ㄱ = ㅋ
        automaton.addTransition(from: "ㄱ", input: "ㄱ", to: "ㅋ")
        // ㅋ + ㄱ = ㄲ
        automaton.addTransition(from: "ㅋ", input: "ㄱ", to: "ㄲ")

        // ㄴ + ㄴ = ㄹ
        automaton.addTransition(from: "ㄴ", input: "ㄴ", to: "ㄹ")

        // ㄷ + ㄷ = ㅌ
        automaton.addTransition(from: "ㄷ", input: "ㄷ", to: "ㅌ")
        // ㅅ + ㄷ = ㄸ (표준 종성이 아니지만 일관성을 위해)
        automaton.addTransition(from: "ㅌ", input: "ㄷ", to: "ㄸ")

        // ㅂ + ㅂ = ㅍ
        automaton.addTransition(from: "ㅂ", input: "ㅂ", to: "ㅍ")
        // ㅆ + ㅂ = ㅃ (표준 종성이 아니지만 일관성을 위해)
        automaton.addTransition(from: "ㅍ", input: "ㅂ", to: "ㅃ")

        // ㅅ + ㅅ = ㅎ
        automaton.addTransition(from: "ㅅ", input: "ㅅ", to: "ㅎ")
        // ㅎ + ㅅ = ㅆ
        automaton.addTransition(from: "ㅎ", input: "ㅅ", to: "ㅆ")

        // ㅈ + ㅈ = ㅊ
        automaton.addTransition(from: "ㅈ", input: "ㅈ", to: "ㅊ")
        // ㅊ + ㅈ = ㅉ (표준 종성이 아니지만 일관성을 위해)
        automaton.addTransition(from: "ㅊ", input: "ㅈ", to: "ㅉ")

        // ㅇ + ㅇ = ㅁ
        automaton.addTransition(from: "ㅇ", input: "ㅇ", to: "ㅁ")

        // 겹자음
        // ㄱ + ㅅ = ㄳ
        automaton.addTransition(from: "ㄱ", input: "ㅅ", to: "ㄳ")
        // ㄴ + ㅈ = ㄵ
        automaton.addTransition(from: "ㄴ", input: "ㅈ", to: "ㄵ")
        // ㄴ + ㅎ = ㄵ (먼저 ㄴ + ㅅ 필요)
        automaton.addTransition(from: "ㄴ", input: "ㅅ", to: "ㄴㅅ") // 중간 상태
        automaton.addTransition(from: "ㄴㅅ", input: "ㅅ", to: "ㅀ")

        // ㄹ + ㄱ = ㄺ
        automaton.addTransition(from: "ㄹ", input: "ㄱ", to: "ㄺ")
        // ㄹ + ㅁ = ㄻ (먼저 ㄹ + ㅇ 필요)
        automaton.addTransition(from: "ㄹ", input: "ㅇ", to: "ㄹㅇ") // intermediate state
        automaton.addTransition(from: "ㄹㅇ", input: "ㅇ", to: "ㄻ")
        // ㄹ + ㅂ = ㄼ
        automaton.addTransition(from: "ㄹ", input: "ㅂ", to: "ㄼ")
        // ㄹ + ㅅ = ㄽ
        automaton.addTransition(from: "ㄹ", input: "ㅅ", to: "ㄽ")
        // ㄹ + ㅅ = ㄾ (먼저 ㄹ + ㄷ 필요)
        automaton.addTransition(from: "ㄹ", input: "ㄷ", to: "ㄹㄷ") // intermediate state
        automaton.addTransition(from: "ㄹㄷ", input: "ㄷ", to: "ㄾ")

        // ㄼ + ㅂ = ㄿ
        automaton.addTransition(from: "ㄼ", input: "ㅂ", to: "ㄿ")
        // ㄽ + ㅅ = ㅀ
        automaton.addTransition(from: "ㄽ", input: "ㅅ", to: "ㅀ")
        // ㅂ + ㅅ = ㅄ
        automaton.addTransition(from: "ㅂ", input: "ㅅ", to: "ㅄ")

        // 표시 매핑
        automaton.addDisplay(state: "ㄱ", display: "\u{11A8}") // ᆨ
        automaton.addDisplay(state: "ㄲ", display: "\u{11A9}") // ᆩ
        automaton.addDisplay(state: "ㄳ", display: "\u{11AA}") // ᆪ
        automaton.addDisplay(state: "ㄴ", display: "\u{11AB}") // ᆫ
        automaton.addDisplay(state: "ㄵ", display: "\u{11AC}") // ᆬ
        automaton.addDisplay(state: "ㅀ", display: "\u{11AD}") // ᆭ
        automaton.addDisplay(state: "ㄷ", display: "\u{11AE}") // ᆮ
        automaton.addDisplay(state: "ㄹ", display: "\u{11AF}") // ᆯ
        automaton.addDisplay(state: "ㄺ", display: "\u{11B0}") // ᆰ
        automaton.addDisplay(state: "ㄻ", display: "\u{11B1}") // ᆱ
        automaton.addDisplay(state: "ㄼ", display: "\u{11B2}") // ᆲ
        automaton.addDisplay(state: "ㄽ", display: "\u{11B3}") // ᆳ
        automaton.addDisplay(state: "ㄾ", display: "\u{11B4}") // ᆴ
        automaton.addDisplay(state: "ㄿ", display: "\u{11B5}") // ᆵ
        automaton.addDisplay(state: "ㅁ", display: "\u{11B7}") // ᆷ
        automaton.addDisplay(state: "ㅂ", display: "\u{11B8}") // ᆸ
        automaton.addDisplay(state: "ㅄ", display: "\u{11B9}") // ᆹ
        automaton.addDisplay(state: "ㅅ", display: "\u{11BA}") // ᆺ
        automaton.addDisplay(state: "ㅆ", display: "\u{11BB}") // ᆻ
        automaton.addDisplay(state: "ㅇ", display: "\u{11BC}") // ᆼ
        automaton.addDisplay(state: "ㅈ", display: "\u{11BD}") // ᆽ
        automaton.addDisplay(state: "ㅊ", display: "\u{11BE}") // ᆾ
        automaton.addDisplay(state: "ㅋ", display: "\u{11BF}") // ᆿ
        automaton.addDisplay(state: "ㅌ", display: "\u{11C0}") // ᇀ
        automaton.addDisplay(state: "ㅍ", display: "\u{11C1}") // ᇁ
        automaton.addDisplay(state: "ㅎ", display: "\u{11C2}") // ᇂ

        // 표준 종성이 아님
        automaton.addDisplay(state: "ㄸ", display: "\u{11AE}\u{11AE}") // ᆮᆮ
        automaton.addDisplay(state: "ㅃ", display: "\u{11B8}\u{11B8}") // ᆸᆸ
        automaton.addDisplay(state: "ㅉ", display: "\u{11BD}\u{11BD}") // ᆽᆽ

        // 표시를 위한 중간 상태 - 호환성을 위해 단일 문자 사용
        automaton.addDisplay(state: "ㄴㅅ", display: "\u{11AB}\u{11BA}") // ᆫᆺ (중간 상태로 처리됨)
        automaton.addDisplay(state: "ㄹㅇ", display: "\u{11AF}\u{11BC}") // ᆯᆼ (중간 상태로 처리됨)
        automaton.addDisplay(state: "ㄹㄷ", display: "\u{11AF}\u{11AE}") // ᆯᆮ (중간 상태로 처리됨)
        
        return automaton
    }
    
    private static func createDokkaebiAutomaton() -> DokkaebiAutomaton {
        let automaton = DokkaebiAutomaton()

        // 표준 도깨비불 분리
        automaton.addTransition(jongseongState: "ㄳ", remainingJong: "ㄱ", movedCho: "ㅅ")
        automaton.addTransition(jongseongState: "ㄵ", remainingJong: "ㄴ", movedCho: "ㅈ")
        automaton.addTransition(jongseongState: "ㅀ", remainingJong: "ㄴ", movedCho: "ㅎ")
        automaton.addTransition(jongseongState: "ㄺ", remainingJong: "ㄹ", movedCho: "ㄱ")
        automaton.addTransition(jongseongState: "ㄻ", remainingJong: "ㄹ", movedCho: "ㅁ")
        automaton.addTransition(jongseongState: "ㄼ", remainingJong: "ㄹ", movedCho: "ㅂ")
        automaton.addTransition(jongseongState: "ㄽ", remainingJong: "ㄹ", movedCho: "ㅅ")
        automaton.addTransition(jongseongState: "ㄾ", remainingJong: "ㄹ", movedCho: "ㅌ")
        automaton.addTransition(jongseongState: "ㄿ", remainingJong: "ㄹ", movedCho: "ㅍ")
        automaton.addTransition(jongseongState: "ㅄ", remainingJong: "ㅂ", movedCho: "ㅅ")

        // 천지인을 위한 중간 상태
        automaton.addTransition(jongseongState: "ㄴㅅ", remainingJong: "ㄴ", movedCho: "ㅅ")
        automaton.addTransition(jongseongState: "ㄹㅇ", remainingJong: "ㄹ", movedCho: "ㅇ")
        automaton.addTransition(jongseongState: "ㄹㄷ", remainingJong: "ㄹ", movedCho: "ㄷ")
        automaton.addTransition(jongseongState: "ㄸ", remainingJong: "ㄷ", movedCho: "ㄷ")
        automaton.addTransition(jongseongState: "ㅃ", remainingJong: "ㅂ", movedCho: "ㅂ")
        automaton.addTransition(jongseongState: "ㅉ", remainingJong: "ㅈ", movedCho: "ㅈ")

        // 분리할 수 있는 단일 자음
        automaton.addTransition(jongseongState: "ㄱ", remainingJong: nil, movedCho: "ㄱ")
        automaton.addTransition(jongseongState: "ㄴ", remainingJong: nil, movedCho: "ㄴ")
        automaton.addTransition(jongseongState: "ㄷ", remainingJong: nil, movedCho: "ㄷ")
        automaton.addTransition(jongseongState: "ㄹ", remainingJong: nil, movedCho: "ㄹ")
        automaton.addTransition(jongseongState: "ㅁ", remainingJong: nil, movedCho: "ㅁ")
        automaton.addTransition(jongseongState: "ㅂ", remainingJong: nil, movedCho: "ㅂ")
        automaton.addTransition(jongseongState: "ㅅ", remainingJong: nil, movedCho: "ㅅ")
        automaton.addTransition(jongseongState: "ㅇ", remainingJong: nil, movedCho: "ㅇ")
        automaton.addTransition(jongseongState: "ㅈ", remainingJong: nil, movedCho: "ㅈ")
        automaton.addTransition(jongseongState: "ㅊ", remainingJong: nil, movedCho: "ㅊ")
        automaton.addTransition(jongseongState: "ㅋ", remainingJong: nil, movedCho: "ㅋ")
        automaton.addTransition(jongseongState: "ㅌ", remainingJong: nil, movedCho: "ㅌ")
        automaton.addTransition(jongseongState: "ㅍ", remainingJong: nil, movedCho: "ㅍ")
        automaton.addTransition(jongseongState: "ㅎ", remainingJong: nil, movedCho: "ㅎ")
        automaton.addTransition(jongseongState: "ㄲ", remainingJong: nil, movedCho: "ㄲ")
        automaton.addTransition(jongseongState: "ㅆ", remainingJong: nil, movedCho: "ㅆ")
        
        return automaton
    }
    
    private static func createBackspaceAutomaton() -> BackspaceAutomaton {
        let automaton = BackspaceAutomaton()

        // 중성 백스페이스
        automaton.addTransition(from: "ᆢ", to: "ㆍ")
        automaton.addTransition(from: "ㅏ", to: "ㅣ")
        automaton.addTransition(from: "ㅑ", to: "ㅏ")
        automaton.addTransition(from: "ㅓ", to: "ㆍ")
        automaton.addTransition(from: "ㅕ", to: "ᆢ")
        automaton.addTransition(from: "ㅗ", to: "ㆍ")
        automaton.addTransition(from: "ㅛ", to: "ᆢ")
        automaton.addTransition(from: "ㅜ", to: "ㅡ")
        automaton.addTransition(from: "ㅠ", to: "ㅜ")
        automaton.addTransition(from: "ㅐ", to: "ㅏ")
        automaton.addTransition(from: "ㅒ", to: "ㅑ")
        automaton.addTransition(from: "ㅔ", to: "ㅓ")
        automaton.addTransition(from: "ㅖ", to: "ㅕ")
        automaton.addTransition(from: "ㅚ", to: "ㅗ")
        automaton.addTransition(from: "ㅘ", to: "ㅚ")
        automaton.addTransition(from: "ㅙ", to: "ㅘ")
        automaton.addTransition(from: "ㅝ", to: "ㅠ")
        automaton.addTransition(from: "ㅞ", to: "ㅝ")
        automaton.addTransition(from: "ㅟ", to: "ㅜ")
        automaton.addTransition(from: "ㅢ", to: "ㅡ")

        // 종성 백스페이스
        automaton.addTransition(from: "ㄳ", to: "ㄱ")
        automaton.addTransition(from: "ㄵ", to: "ㄴ")
        automaton.addTransition(from: "ㄶ", to: "ㄴㅅ")
        automaton.addTransition(from: "ㄴㅅ", to: "ㄴ")
        automaton.addTransition(from: "ㄺ", to: "ㄹ")
        automaton.addTransition(from: "ㄻ", to: "ㄹㅇ")
        automaton.addTransition(from: "ㄹㅇ", to: "ㄹ")
        automaton.addTransition(from: "ㄼ", to: "ㄹ")
        automaton.addTransition(from: "ㄽ", to: "ㄹ")
        automaton.addTransition(from: "ㄾ", to: "ㄹㄷ")
        automaton.addTransition(from: "ㄹㄷ", to: "ㄹ")
        automaton.addTransition(from: "ㅀ", to: "ㄽ")
        automaton.addTransition(from: "ㄿ", to: "ㄼ")
        automaton.addTransition(from: "ㅄ", to: "ㅂ")
        
        return automaton
    }
    
    private static func createSpecialCharacterAutomaton() -> SpecialCharacterAutomaton {
        let automaton = SpecialCharacterAutomaton()
        
        // Python 구현과 일치하는 기본 전이
        automaton.addTransition(from: "", input: ".", to: ".")
        
        // . + . = ,
        automaton.addTransition(from: ".", input: ".", to: ",")
        // , + . = ?
        automaton.addTransition(from: ",", input: ".", to: "?")
        // ? + . = !
        automaton.addTransition(from: "?", input: ".", to: "!")
        
        // 표시 매핑
        automaton.addDisplay(state: ".", display: ".")
        automaton.addDisplay(state: ",", display: ",")
        automaton.addDisplay(state: "?", display: "?")
        automaton.addDisplay(state: "!", display: "!")
        
        return automaton
    }
}