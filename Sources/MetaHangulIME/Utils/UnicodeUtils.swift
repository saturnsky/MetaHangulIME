//
//  UnicodeUtils.swift
//  MetaHangulIME
//
//  한국어 문자 조합을 위한 유니코드 유틸리티
//

import Foundation

/// 한국어 문자 처리를 위한 유니코드 상수와 유틸리티
public enum UnicodeConstants {
    // 한글 자모 (U+1100-U+11FF) - NFD에 사용
    public static let choseongBase: UInt32 = 0x1100
    public static let jungseongBase: UInt32 = 0x1161
    public static let jongseongBase: UInt32 = 0x11A7

    // 한글 음절 (U+AC00-U+D7AF)
    public static let syllableBase: UInt32 = 0xAC00

    // 개수
    public static let choseongCount: UInt32 = 19
    public static let jungseongCount: UInt32 = 21
    public static let jongseongCount: UInt32 = 28  // 종성 없음 포함

    // 성능을 위해 파생된 상수
    public static let syllablesPerChoseong: UInt32 = jungseongCount * jongseongCount // 588
}

/// 한국어 유니코드 연산을 위한 유틸리티
public enum UnicodeUtils {
    /// 두 자모를 단일 호환 자모로 변환하는 테이블 (위치별 구분)
    private static let doubleJamoCompositionMap: (
        choseong: [String: Character],
        jungseong: [String: Character],
        jongseong: [String: Character]
    ) = (
        choseong: [
            // 초성 쌍자음
            "\u{1100}\u{1100}": "\u{3132}",  // ᄀᄀ → ㄲ
            "\u{1103}\u{1103}": "\u{3138}",  // ᄃᄃ → ㄸ
            "\u{1107}\u{1107}": "\u{3143}",  // ᄇᄇ → ㅃ
            "\u{1109}\u{1109}": "\u{3146}",  // ᄉᄉ → ㅆ
            "\u{110C}\u{110C}": "\u{3149}",  // ᄌᄌ → ㅉ
        ],

        jungseong: [
            // 중성 조합
            "\u{1169}\u{1161}": "\u{3158}",  // ㅗㅏ → ㅘ
            "\u{1169}\u{1162}": "\u{3159}",  // ㅗㅐ → ㅙ
            "\u{1169}\u{1175}": "\u{315A}",  // ㅗㅣ → ㅚ
            "\u{116E}\u{1165}": "\u{315D}",  // ㅜㅓ → ㅝ
            "\u{116E}\u{1166}": "\u{315E}",  // ㅜㅔ → ㅞ
            "\u{116E}\u{1175}": "\u{315F}",  // ㅜㅣ → ㅟ
            "\u{1173}\u{1175}": "\u{3162}",  // ㅡㅣ → ㅢ
        ],

        jongseong: [
            // 종성 쌍자음
            "\u{11A8}\u{11A8}": "\u{3132}",  // ᆨᆨ → ㄲ
            "\u{11AE}\u{11AE}": "\u{3138}",  // ᆮᆮ → ㄸ
            "\u{11B8}\u{11B8}": "\u{3143}",  // ᆸᆸ → ㅃ
            "\u{11BA}\u{11BA}": "\u{3146}",  // ᆺᆺ → ㅆ
            "\u{11BD}\u{11BD}": "\u{3149}",  // ᆽᆽ → ㅉ

            // 종성 복합 자음
            "\u{11A8}\u{11BA}": "\u{3133}",  // ᆨᆺ → ㄳ
            "\u{11AB}\u{11BD}": "\u{3135}",  // ᆫᆽ → ㄵ
            "\u{11AB}\u{11C2}": "\u{3136}",  // ᆫᇂ → ㄶ
            "\u{11AF}\u{11A8}": "\u{313A}",  // ᆯᆨ → ㄺ
            "\u{11AF}\u{11B7}": "\u{313B}",  // ᆯᆷ → ㄻ
            "\u{11AF}\u{11B8}": "\u{313C}",  // ᆯᆸ → ㄼ
            "\u{11AF}\u{11BA}": "\u{313D}",  // ᆯᆺ → ㄽ
            "\u{11AF}\u{11C0}": "\u{313E}",  // ᆯᇀ → ㄾ
            "\u{11AF}\u{11C1}": "\u{313F}",  // ᆯᇁ → ㄿ
            "\u{11AF}\u{11C2}": "\u{3140}",  // ᆯᇂ → ㅀ
            "\u{11B8}\u{11BA}": "\u{3144}",  // ᆸᆺ → ㅄ
        ]
    )

    /// 자모에서 호환 자모로의 매핑 테이블
    /// O(1) 조회 성능을 위해 정적 배열로 최적화
    private static let jamoToCompatibilityMap: [Character: Character] = {
        var map: [Character: Character] = [:]

        // 초성 매핑
        map["\u{1100}"] = "\u{3131}" // ㄱ
        map["\u{1101}"] = "\u{3132}" // ㄲ
        map["\u{1102}"] = "\u{3134}" // ㄴ
        map["\u{1103}"] = "\u{3137}" // ㄷ
        map["\u{1104}"] = "\u{3138}" // ㄸ
        map["\u{1105}"] = "\u{3139}" // ㄹ
        map["\u{1106}"] = "\u{3141}" // ㅁ
        map["\u{1107}"] = "\u{3142}" // ㅂ
        map["\u{1108}"] = "\u{3143}" // ㅃ
        map["\u{1109}"] = "\u{3145}" // ㅅ
        map["\u{110A}"] = "\u{3146}" // ㅆ
        map["\u{110B}"] = "\u{3147}" // ㅇ
        map["\u{110C}"] = "\u{3148}" // ㅈ
        map["\u{110D}"] = "\u{3149}" // ㅉ
        map["\u{110E}"] = "\u{314A}" // ㅊ
        map["\u{110F}"] = "\u{314B}" // ㅋ
        map["\u{1110}"] = "\u{314C}" // ㅌ
        map["\u{1111}"] = "\u{314D}" // ㅍ
        map["\u{1112}"] = "\u{314E}" // ㅎ

        // 중성 매핑
        map["\u{1161}"] = "\u{314F}" // ㅏ
        map["\u{1162}"] = "\u{3150}" // ㅐ
        map["\u{1163}"] = "\u{3151}" // ㅑ
        map["\u{1164}"] = "\u{3152}" // ㅒ
        map["\u{1165}"] = "\u{3153}" // ㅓ
        map["\u{1166}"] = "\u{3154}" // ㅔ
        map["\u{1167}"] = "\u{3155}" // ㅕ
        map["\u{1168}"] = "\u{3156}" // ㅖ
        map["\u{1169}"] = "\u{3157}" // ㅗ
        map["\u{116A}"] = "\u{3158}" // ㅘ
        map["\u{116B}"] = "\u{3159}" // ㅙ
        map["\u{116C}"] = "\u{315A}" // ㅚ
        map["\u{116D}"] = "\u{315B}" // ㅛ
        map["\u{116E}"] = "\u{315C}" // ㅜ
        map["\u{116F}"] = "\u{315D}" // ㅝ
        map["\u{1170}"] = "\u{315E}" // ㅞ
        map["\u{1171}"] = "\u{315F}" // ㅟ
        map["\u{1172}"] = "\u{3160}" // ㅠ
        map["\u{1173}"] = "\u{3161}" // ㅡ
        map["\u{1174}"] = "\u{3162}" // ㅢ
        map["\u{1175}"] = "\u{3163}" // ㅣ
        map["\u{119E}"] = "\u{318D}" // ㆍ (아래아)

        // 종성 매핑
        map["\u{11A8}"] = "\u{3131}" // ㄱ
        map["\u{11A9}"] = "\u{3132}" // ㄲ
        map["\u{11AA}"] = "\u{3133}" // ㄳ
        map["\u{11AB}"] = "\u{3134}" // ㄴ
        map["\u{11AC}"] = "\u{3135}" // ㄵ
        map["\u{11AD}"] = "\u{3136}" // ㄶ
        map["\u{11AE}"] = "\u{3137}" // ㄷ
        map["\u{11AF}"] = "\u{3139}" // ㄹ
        map["\u{11B0}"] = "\u{313A}" // ㄺ
        map["\u{11B1}"] = "\u{313B}" // ㄻ
        map["\u{11B2}"] = "\u{313C}" // ㄼ
        map["\u{11B3}"] = "\u{313D}" // ㄽ
        map["\u{11B4}"] = "\u{313E}" // ㄾ
        map["\u{11B5}"] = "\u{313F}" // ㄿ
        map["\u{11B6}"] = "\u{3140}" // ㅀ
        map["\u{11B7}"] = "\u{3141}" // ㅁ
        map["\u{11B8}"] = "\u{3142}" // ㅂ
        map["\u{11B9}"] = "\u{3144}" // ㅄ
        map["\u{11BA}"] = "\u{3145}" // ㅅ
        map["\u{11BB}"] = "\u{3146}" // ㅆ
        map["\u{11BC}"] = "\u{3147}" // ㅇ
        map["\u{11BD}"] = "\u{3148}" // ㅈ
        map["\u{11BE}"] = "\u{314A}" // ㅊ
        map["\u{11BF}"] = "\u{314B}" // ㅋ
        map["\u{11C0}"] = "\u{314C}" // ㅌ
        map["\u{11C1}"] = "\u{314D}" // ㅍ
        map["\u{11C2}"] = "\u{314E}" // ㅎ

        return map
    }()

    /// 한글 자모 (U+1100-U+11FF)를 호환 자모 (U+3130-U+318F)로 변환
    /// - Parameter jamo: 변환할 자모 문자열
    /// - Returns: 변환된 호환 자모 문자열
    @inline(__always)
    public static func jamoToCompatibility(_ jamo: String) -> String {
        // 각 유니코드 스칼라를 변환하여 다중 스칼라 문자열 처리
        String(jamo.unicodeScalars.compactMap { scalar in
            let char = Character(scalar)
            return jamoToCompatibilityMap[char] ?? char
        })
    }

    /// 한글 자모를 호환 자모로 변환 (2자 조합 우선 처리)
    /// - Parameters:
    ///   - jamo: 변환할 자모 문자열
    ///   - position: 자모의 위치 (초성/중성/종성)
    /// - Returns: 변환된 호환 자모 문자열
    public static func jamoToCompatibilityWithComposition(_ jamo: String, position: JamoPosition) -> String {
        var result = ""
        let scalars = jamo.unicodeScalars
        var i = scalars.startIndex

        // position에 따라 적절한 테이블 선택
        let compositionMap: [String: Character]
        switch position {
        case .choseong:
            compositionMap = doubleJamoCompositionMap.choseong
        case .jungseong:
            compositionMap = doubleJamoCompositionMap.jungseong
        case .jongseong:
            compositionMap = doubleJamoCompositionMap.jongseong
        }

        while i < scalars.endIndex {
            // 다음 스칼라가 있으면 2스칼라 조합 시도
            let nextIndex = scalars.index(after: i)
            if nextIndex < scalars.endIndex {
                let twoScalars = String(scalars[i...nextIndex])

                if let composed = compositionMap[twoScalars] {
                    result.append(composed)
                    i = scalars.index(i, offsetBy: 2)
                    continue
                }
            }

            // 2스칼라 조합 실패시 단일 스칼라 변환
            let singleScalar = String(scalars[i])
            let char = Character(singleScalar)
            result.append(jamoToCompatibilityMap[char] ?? char)
            i = scalars.index(after: i)
        }

        return result
    }

    /// 문자가 한글 자모 범위에 있는지 확인
    @inline(__always)
    public static func isHangulJamo(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        let value = scalar.value
        return (0x1100...0x11FF).contains(value)
    }

    /// 문자가 한글 호환 자모 범위에 있는지 확인
    @inline(__always)
    public static func isCompatibilityJamo(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        let value = scalar.value
        return (0x3130...0x318F).contains(value)
    }

    /// 문자가 조합된 한글 음절인지 확인
    @inline(__always)
    public static func isHangulSyllable(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        let value = scalar.value
        return (0xAC00...0xD7AF).contains(value)
    }
}
