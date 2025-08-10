//
//  StandardDubeolsik.swift
//  MetaHangulIME
//
//  표준 두벌식 구현
//

import Foundation

/// 표준 두벌식 IME 구현
public final class StandardDubeolsik: KoreanIME {
    public init() {
        let processor = StandardDubeolsik.createProcessor()
        let layout = StandardDubeolsik.createLayout()
        super.init(processor: processor, layout: layout)
    }

    // MARK: - 레이아웃 생성

    private static func createLayout() -> [String: VirtualKey] {
        [
            // 일반 키
            "1": VirtualKey(keyIdentifier: "1", label: "1", isNonJamo: true),
            "2": VirtualKey(keyIdentifier: "2", label: "2", isNonJamo: true),
            "3": VirtualKey(keyIdentifier: "3", label: "3", isNonJamo: true),
            "4": VirtualKey(keyIdentifier: "4", label: "4", isNonJamo: true),
            "5": VirtualKey(keyIdentifier: "5", label: "5", isNonJamo: true),
            "6": VirtualKey(keyIdentifier: "6", label: "6", isNonJamo: true),
            "7": VirtualKey(keyIdentifier: "7", label: "7", isNonJamo: true),
            "8": VirtualKey(keyIdentifier: "8", label: "8", isNonJamo: true),
            "9": VirtualKey(keyIdentifier: "9", label: "9", isNonJamo: true),
            "0": VirtualKey(keyIdentifier: "0", label: "0", isNonJamo: true),

            // 특수 문자
            "`": VirtualKey(keyIdentifier: "`", label: "`", isNonJamo: true),
            "-": VirtualKey(keyIdentifier: "-", label: "-", isNonJamo: true),
            "=": VirtualKey(keyIdentifier: "=", label: "=", isNonJamo: true),
            "[": VirtualKey(keyIdentifier: "[", label: "[", isNonJamo: true),
            "]": VirtualKey(keyIdentifier: "]", label: "]", isNonJamo: true),
            "\\": VirtualKey(keyIdentifier: "\\", label: "\\", isNonJamo: true),
            ";": VirtualKey(keyIdentifier: ";", label: ";", isNonJamo: true),
            "'": VirtualKey(keyIdentifier: "'", label: "'", isNonJamo: true),
            ",": VirtualKey(keyIdentifier: ",", label: ",", isNonJamo: true),
            ".": VirtualKey(keyIdentifier: ".", label: ".", isNonJamo: true),
            "/": VirtualKey(keyIdentifier: "/", label: "/", isNonJamo: true),
            " ": VirtualKey(keyIdentifier: " ", label: " ", isNonJamo: true), // 스페이스
            "~": VirtualKey(keyIdentifier: "~", label: "~", isNonJamo: true),
            "!": VirtualKey(keyIdentifier: "!", label: "!", isNonJamo: true),
            "@": VirtualKey(keyIdentifier: "@", label: "@", isNonJamo: true),
            "#": VirtualKey(keyIdentifier: "#", label: "#", isNonJamo: true),
            "$": VirtualKey(keyIdentifier: "$", label: "$", isNonJamo: true),
            "%": VirtualKey(keyIdentifier: "%", label: "%", isNonJamo: true),
            "^": VirtualKey(keyIdentifier: "^", label: "^", isNonJamo: true),
            "&": VirtualKey(keyIdentifier: "&", label: "&", isNonJamo: true),
            "*": VirtualKey(keyIdentifier: "*", label: "*", isNonJamo: true),
            "(": VirtualKey(keyIdentifier: "(", label: "(", isNonJamo: true),
            ")": VirtualKey(keyIdentifier: ")", label: ")", isNonJamo: true),
            "_": VirtualKey(keyIdentifier: "_", label: "_", isNonJamo: true),
            "+": VirtualKey(keyIdentifier: "+", label: "+", isNonJamo: true),
            "{": VirtualKey(keyIdentifier: "{", label: "{", isNonJamo: true),
            "}": VirtualKey(keyIdentifier: "}", label: "}", isNonJamo: true),
            "|": VirtualKey(keyIdentifier: "|", label: "|", isNonJamo: true),
            ":": VirtualKey(keyIdentifier: ":", label: ":", isNonJamo: true),
            "\"": VirtualKey(keyIdentifier: "\"", label: "\"", isNonJamo: true),
            "<": VirtualKey(keyIdentifier: "<", label: "<", isNonJamo: true),
            ">": VirtualKey(keyIdentifier: ">", label: ">", isNonJamo: true),
            "?": VirtualKey(keyIdentifier: "?", label: "?", isNonJamo: true),

            // 자음
            "ㄱ": VirtualKey(keyIdentifier: "ㄱ", label: "ㄱ"),
            "ㄲ": VirtualKey(keyIdentifier: "ㄲ", label: "ㄲ"),
            "ㄴ": VirtualKey(keyIdentifier: "ㄴ", label: "ㄴ"),
            "ㄷ": VirtualKey(keyIdentifier: "ㄷ", label: "ㄷ"),
            "ㄸ": VirtualKey(keyIdentifier: "ㄸ", label: "ㄸ"),
            "ㄹ": VirtualKey(keyIdentifier: "ㄹ", label: "ㄹ"),
            "ㅁ": VirtualKey(keyIdentifier: "ㅁ", label: "ㅁ"),
            "ㅂ": VirtualKey(keyIdentifier: "ㅂ", label: "ㅂ"),
            "ㅃ": VirtualKey(keyIdentifier: "ㅃ", label: "ㅃ"),
            "ㅅ": VirtualKey(keyIdentifier: "ㅅ", label: "ㅅ"),
            "ㅆ": VirtualKey(keyIdentifier: "ㅆ", label: "ㅆ"),
            "ㅇ": VirtualKey(keyIdentifier: "ㅇ", label: "ㅇ"),
            "ㅈ": VirtualKey(keyIdentifier: "ㅈ", label: "ㅈ"),
            "ㅉ": VirtualKey(keyIdentifier: "ㅉ", label: "ㅉ"),
            "ㅊ": VirtualKey(keyIdentifier: "ㅊ", label: "ㅊ"),
            "ㅋ": VirtualKey(keyIdentifier: "ㅋ", label: "ㅋ"),
            "ㅌ": VirtualKey(keyIdentifier: "ㅌ", label: "ㅌ"),
            "ㅍ": VirtualKey(keyIdentifier: "ㅍ", label: "ㅍ"),
            "ㅎ": VirtualKey(keyIdentifier: "ㅎ", label: "ㅎ"),

            // 모음
            "ㅏ": VirtualKey(keyIdentifier: "ㅏ", label: "ㅏ"),
            "ㅐ": VirtualKey(keyIdentifier: "ㅐ", label: "ㅐ"),
            "ㅑ": VirtualKey(keyIdentifier: "ㅑ", label: "ㅑ"),
            "ㅒ": VirtualKey(keyIdentifier: "ㅒ", label: "ㅒ"),
            "ㅓ": VirtualKey(keyIdentifier: "ㅓ", label: "ㅓ"),
            "ㅔ": VirtualKey(keyIdentifier: "ㅔ", label: "ㅔ"),
            "ㅕ": VirtualKey(keyIdentifier: "ㅕ", label: "ㅕ"),
            "ㅖ": VirtualKey(keyIdentifier: "ㅖ", label: "ㅖ"),
            "ㅗ": VirtualKey(keyIdentifier: "ㅗ", label: "ㅗ"),
            "ㅛ": VirtualKey(keyIdentifier: "ㅛ", label: "ㅛ"),
            "ㅜ": VirtualKey(keyIdentifier: "ㅜ", label: "ㅜ"),
            "ㅠ": VirtualKey(keyIdentifier: "ㅠ", label: "ㅠ"),
            "ㅡ": VirtualKey(keyIdentifier: "ㅡ", label: "ㅡ"),
            "ㅣ": VirtualKey(keyIdentifier: "ㅣ", label: "ㅣ"),
        ]
    }

    // MARK: - 프로세서 생성

    private static func createProcessor() -> InputProcessor {
        let choseongAutomaton = createChoseongAutomaton()
        let jungseongAutomaton = createJungseongAutomaton()
        let jongseongAutomaton = createJongseongAutomaton()
        let nonJamoAutomaton = createNonJamoAutomaton()
        let dokkaebiAutomaton = createDokkaebiAutomaton()
        let backspaceAutomaton = createBackspaceAutomaton()

        let config = InputProcessorConfig(
            orderMode: .sequential,
            jamoCommitPolicy: .syllable,
            nonJamoCommitPolicy: .onComplete,
            transitionCommitPolicy: .always,
            displayMode: .modernMultiple,
            supportStandaloneCluster: false
        )

        return InputProcessor(
            choseongAutomaton: choseongAutomaton,
            jungseongAutomaton: jungseongAutomaton,
            jongseongAutomaton: jongseongAutomaton,
            nonJamoAutomaton: nonJamoAutomaton,
            dokkaebiAutomaton: dokkaebiAutomaton,
            backspaceAutomaton: backspaceAutomaton,
            config: config
        )
    }

    private static func createNonJamoAutomaton() -> NonJamoAutomaton {
        let automaton = NonJamoAutomaton()

        // createLayout에서 정의된 일반키와 특수문자들을 추출하여 오토마타에 추가
        let layout = createLayout()

        // 일반키와 특수문자 (한글 자모가 아닌 것들)
        let nonHangulKeys = layout.filter { _, virtualKey in
            // 한글 자모가 아닌 키들만 필터링
            !isHangulJamo(virtualKey.keyIdentifier)
        }

        for (inputKey, virtualKey) in nonHangulKeys {
            let identifier = virtualKey.keyIdentifier
            let display = virtualKey.label

            // 입력키 -> 식별자로의 전이 추가
            automaton.addTransition(from: "", input: inputKey, to: identifier)
            // 식별자에 대한 표시 문자 추가
            automaton.addDisplay(state: identifier, display: display)
        }

        return automaton
    }

    /// 한글 자모인지 확인하는 헬퍼 함수
    private static func isHangulJamo(_ character: String) -> Bool {
        guard let scalar = character.unicodeScalars.first else { return false }
        let value = scalar.value

        // 한글 호환 자모 (ㄱ-ㅎ, ㅏ-ㅣ)
        return (0x3131...0x318E).contains(value)
    }

    // MARK: - Private Types

    private struct CompoundTransition {
        let from: String
        let input: String
        let to: String
        let jamo: String

        init(_ from: String, _ input: String, _ to: String, _ jamo: String) {
            self.from = from
            self.input = input
            self.to = to
            self.jamo = jamo
        }
    }

    // MARK: - 오토마타 생성

    private static func createChoseongAutomaton() -> ChoseongAutomaton {
        let automaton = ChoseongAutomaton()

        let consonants: [(key: String, jamo: String)] = [
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
            ("ㅎ", "\u{1112}"),  // ᄒ
        ]

        for (key, jamo) in consonants {
            automaton.addTransition(from: "", input: key, to: key)
            automaton.addDisplay(state: key, display: jamo)
        }

        return automaton
    }

    private static func createJungseongAutomaton() -> JungseongAutomaton {
        let automaton = JungseongAutomaton()

        // 단일 모음
        let singleVowels: [(key: String, jamo: String)] = [
            ("ㅏ", "\u{1161}"),  // ᅡ
            ("ㅐ", "\u{1162}"),  // ᅢ
            ("ㅑ", "\u{1163}"),  // ᅣ
            ("ㅒ", "\u{1164}"),  // ᅤ
            ("ㅓ", "\u{1165}"),  // ᅥ
            ("ㅔ", "\u{1166}"),  // ᅦ
            ("ㅕ", "\u{1167}"),  // ᅧ
            ("ㅖ", "\u{1168}"),  // ᅨ
            ("ㅗ", "\u{1169}"),  // ᅩ
            ("ㅛ", "\u{116D}"),  // ᅭ
            ("ㅜ", "\u{116E}"),  // ᅮ
            ("ㅠ", "\u{1172}"),  // ᅲ
            ("ㅡ", "\u{1173}"),  // ᅳ
            ("ㅣ", "\u{1175}"),  // ᅵ
        ]

        for (key, jamo) in singleVowels {
            automaton.addTransition(from: "", input: key, to: key)
            automaton.addDisplay(state: key, display: jamo)
        }

        // 복합 모음
        let compoundVowels: [CompoundTransition] = [
            CompoundTransition("ㅗ", "ㅏ", "ㅘ", "\u{116A}"),  // ᅪ
            CompoundTransition("ㅗ", "ㅐ", "ㅙ", "\u{116B}"),  // ᅫ
            CompoundTransition("ㅗ", "ㅣ", "ㅚ", "\u{116C}"),  // ᅬ
            CompoundTransition("ㅜ", "ㅓ", "ㅝ", "\u{116F}"),  // ᅯ
            CompoundTransition("ㅜ", "ㅔ", "ㅞ", "\u{1170}"),  // ᅰ
            CompoundTransition("ㅜ", "ㅣ", "ㅟ", "\u{1171}"),  // ᅱ
            CompoundTransition("ㅡ", "ㅣ", "ㅢ", "\u{1174}"),  // ᅴ
        ]

        for compound in compoundVowels {
            automaton.addTransition(from: compound.from, input: compound.input, to: compound.to)
            automaton.addDisplay(state: compound.to, display: compound.jamo)
        }

        return automaton
    }

    private static func createJongseongAutomaton() -> JongseongAutomaton {
        let automaton = JongseongAutomaton()

        // 단일 자음
        let singleConsonants: [(key: String, jamo: String)] = [
            ("ㄱ", "\u{11A8}"),  // ᆨ
            ("ㄲ", "\u{11A9}"),  // ᆩ
            ("ㄴ", "\u{11AB}"),  // ᆫ
            ("ㄷ", "\u{11AE}"),  // ᆮ
            ("ㄹ", "\u{11AF}"),  // ᆯ
            ("ㅁ", "\u{11B7}"),  // ᆷ
            ("ㅂ", "\u{11B8}"),  // ᆸ
            ("ㅅ", "\u{11BA}"),  // ᆺ
            ("ㅆ", "\u{11BB}"),  // ᆻ
            ("ㅇ", "\u{11BC}"),  // ᆼ
            ("ㅈ", "\u{11BD}"),  // ᆽ
            ("ㅊ", "\u{11BE}"),  // ᆾ
            ("ㅋ", "\u{11BF}"),  // ᆿ
            ("ㅌ", "\u{11C0}"),  // ᇀ
            ("ㅍ", "\u{11C1}"),  // ᇁ
            ("ㅎ", "\u{11C2}"),  // ᇂ
        ]

        for (key, jamo) in singleConsonants {
            automaton.addTransition(from: "", input: key, to: key)
            automaton.addDisplay(state: key, display: jamo)
        }

        // 복합 자음
        let compoundConsonants: [CompoundTransition] = [
            CompoundTransition("ㄱ", "ㅅ", "ㄳ", "\u{11AA}"),  // ᆪ
            CompoundTransition("ㄴ", "ㅈ", "ㄵ", "\u{11AC}"),  // ᆬ
            CompoundTransition("ㄴ", "ㅎ", "ㄶ", "\u{11AD}"),  // ᆭ
            CompoundTransition("ㄹ", "ㄱ", "ㄺ", "\u{11B0}"),  // ᆰ
            CompoundTransition("ㄹ", "ㅁ", "ㄻ", "\u{11B1}"),  // ᆱ
            CompoundTransition("ㄹ", "ㅂ", "ㄼ", "\u{11B2}"),  // ᆲ
            CompoundTransition("ㄹ", "ㅅ", "ㄽ", "\u{11B3}"),  // ᆳ
            CompoundTransition("ㄹ", "ㅌ", "ㄾ", "\u{11B4}"),  // ᆴ
            CompoundTransition("ㄹ", "ㅍ", "ㄿ", "\u{11B5}"),  // ᆵ
            CompoundTransition("ㄹ", "ㅎ", "ㅀ", "\u{11B6}"),  // ᆶ
            CompoundTransition("ㅂ", "ㅅ", "ㅄ", "\u{11B9}"),  // ᆹ
        ]

        for compound in compoundConsonants {
            automaton.addTransition(from: compound.from, input: compound.input, to: compound.to)
            automaton.addDisplay(state: compound.to, display: compound.jamo)
        }

        return automaton
    }

    private static func createDokkaebiAutomaton() -> DokkaebiAutomaton {
        let automaton = DokkaebiAutomaton()

        // 전체가 이동하는 단일 자음
        let singleConsonants = [
            "ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄹ", "ㅁ", "ㅂ", "ㅅ", "ㅆ",
            "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ",
        ]

        for consonant in singleConsonants {
            automaton.addTransition(jongseongState: consonant, remainingJong: nil, movedCho: consonant)
        }

        // 분할되는 복합 자음
        let compoundConsonants: [(jongseong: String, remaining: String?, moved: String)] = [
            (jongseong: "ㄳ", remaining: "ㄱ", moved: "ㅅ"),
            (jongseong: "ㄵ", remaining: "ㄴ", moved: "ㅈ"),
            (jongseong: "ㄶ", remaining: "ㄴ", moved: "ㅎ"),
            (jongseong: "ㄺ", remaining: "ㄹ", moved: "ㄱ"),
            (jongseong: "ㄻ", remaining: "ㄹ", moved: "ㅁ"),
            (jongseong: "ㄼ", remaining: "ㄹ", moved: "ㅂ"),
            (jongseong: "ㄽ", remaining: "ㄹ", moved: "ㅅ"),
            (jongseong: "ㄾ", remaining: "ㄹ", moved: "ㅌ"),
            (jongseong: "ㄿ", remaining: "ㄹ", moved: "ㅍ"),
            (jongseong: "ㅀ", remaining: "ㄹ", moved: "ㅎ"),
            (jongseong: "ㅄ", remaining: "ㅂ", moved: "ㅅ"),
        ]

        automaton.addTransitions(compoundConsonants)

        return automaton
    }

    private static func createBackspaceAutomaton() -> BackspaceAutomaton {
        let automaton = BackspaceAutomaton()

        // 종성 복합 분해 규칙
        let jongseongBackspaceRules: [(compound: String, decomposed: String)] = [
            ("ㄳ", "ㄱ"),
            ("ㄵ", "ㄴ"),
            ("ㄶ", "ㄴ"),
            ("ㄺ", "ㄹ"),
            ("ㄻ", "ㄹ"),
            ("ㄼ", "ㄹ"),
            ("ㄽ", "ㄹ"),
            ("ㄾ", "ㄹ"),
            ("ㄿ", "ㄹ"),
            ("ㅀ", "ㄹ"),
            ("ㅄ", "ㅂ"),
        ]

        for (compound, decomposed) in jongseongBackspaceRules {
            automaton.addTransition(from: compound, to: decomposed)
        }

        return automaton
    }
}
