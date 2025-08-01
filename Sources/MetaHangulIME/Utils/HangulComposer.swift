//
//  HangulComposer.swift
//  MetaHangulIME
//
//  한글 음절 조합을 위한 유틸리티
//

import Foundation

/// 음절 조합 시도의 결과
public struct CompositionResult {
    /// 조합된 문자 (조합할 수 없으면 nil)
    public let composed: String?
    
    /// 조합 후 남은 음절 상태
    public let remaining: SyllableDisplayState?
}

/// 한글 음절 조합을 위한 유틸리티
public struct HangulComposer {
    
    /// 자모로부터 한글 음절 조합 시도
    /// - Parameters:
    ///   - cho: 초성 자모 문자열
    ///   - jung: 중성 자모 문자열  
    ///   - jong: 종성 자모 문자열
    /// - Returns: 조합된 문자와 남은 상태를 포함한 조합 결과
    public static func tryComposeSyllable(cho: String, jung: String, jong: String) -> CompositionResult {
        // 빈 입력
        if cho.isEmpty && jung.isEmpty && jong.isEmpty {
            return CompositionResult(composed: nil, remaining: nil)
        }
        
        var composeIndex: (cho: Int?, jung: Int?, jong: Int?) = (nil, nil, nil)
        var remainingCho = cho
        var remainingJung = jung
        var remainingJong = jong
        
        // 초성 처리
        if !remainingCho.isEmpty {
            // 다중 스칼라 문자열을 처리하기 위해 유니코드 스칼라를 직접 사용
            let choScalars = remainingCho.unicodeScalars
            if let firstScalar = choScalars.first {
                let choIdx = Int(firstScalar.value - UnicodeConstants.choseongBase)
                if choIdx >= 0 && choIdx < Int(UnicodeConstants.choseongCount) {
                    composeIndex.cho = choIdx
                    // 첫 번째 유니코드 스칼라 제거
                    let index = remainingCho.unicodeScalars.index(after: remainingCho.unicodeScalars.startIndex)
                    remainingCho = String(remainingCho.unicodeScalars[index...])
                    // Python 버전 호환성: 남은 초성이 있으면 중단하고 반환
                    if !remainingCho.isEmpty {
                        return buildResult(
                            composeIndex: composeIndex,
                            remainingCho: remainingCho,
                            remainingJung: remainingJung,
                            remainingJong: remainingJong
                        )
                    }
                } else {
                    // 유효하지 않은 초성, 호환 자모로 반환
                    return buildCompatibilityResult(cho: remainingCho, jung: remainingJung, jong: remainingJong)
                }
            }
        }
        
        // 중성 처리
        if !remainingJung.isEmpty {
            // 다중 스칼라 문자열을 처리하기 위해 유니코드 스칼라를 직접 사용
            let jungScalars = remainingJung.unicodeScalars
            if let firstScalar = jungScalars.first {
                let jungIdx = Int(firstScalar.value - UnicodeConstants.jungseongBase)
                
                if composeIndex.cho != nil {
                    // 초성이 있음 - 조합 가능한지 확인
                    if jungIdx >= 0 && jungIdx < Int(UnicodeConstants.jungseongCount) {
                        composeIndex.jung = jungIdx
                        // 첫 번째 유니코드 스칼라 제거
                        let index = remainingJung.unicodeScalars.index(after: remainingJung.unicodeScalars.startIndex)
                        remainingJung = String(remainingJung.unicodeScalars[index...])
                        // Python 버전 호환성: 남은 중성이 있으면 중단하고 반환
                        if !remainingJung.isEmpty {
                            return buildResult(
                                composeIndex: composeIndex,
                                remainingCho: remainingCho,
                                remainingJung: remainingJung,
                                remainingJong: remainingJong
                            )
                        }
                    } else {
                        // 유효하지 않은 중성
                        return buildResult(composeIndex: composeIndex,
                                         remainingCho: remainingCho,
                                         remainingJung: remainingJung,
                                         remainingJong: remainingJong)
                    }
                } else {
                    // 초성 없음 - 있는 그대로 저장
                    composeIndex.jung = jungIdx
                    // 첫 번째 유니코드 스칼라 제거
                    let index = remainingJung.unicodeScalars.index(after: remainingJung.unicodeScalars.startIndex)
                    remainingJung = String(remainingJung.unicodeScalars[index...])
                    return buildResult(composeIndex: composeIndex,
                                     remainingCho: remainingCho,
                                     remainingJung: remainingJung,
                                     remainingJong: remainingJong)
                }
            }
        }
        
        // 종성 처리
        if !remainingJong.isEmpty {
            // 다중 스칼라 문자열을 처리하기 위해 유니코드 스칼라를 직접 사용
            let jongScalars = remainingJong.unicodeScalars
            if let firstScalar = jongScalars.first {
                let jongIdx = Int(firstScalar.value - UnicodeConstants.jongseongBase)
                
                if composeIndex.cho != nil && composeIndex.jung != nil {
                    // 완전한 음절 베이스가 있음 - 종성 추가 가능한지 확인
                    if jongIdx >= 1 && jongIdx <= 27 {  // 종성 범위는 1-27
                        composeIndex.jong = jongIdx
                        // 첫 번째 유니코드 스칼라 제거, not the first Character
                        let index = remainingJong.unicodeScalars.index(after: remainingJong.unicodeScalars.startIndex)
                        remainingJong = String(remainingJong.unicodeScalars[index...])
                    } else {
                        // 유효하지 않은 종성
                        return buildResult(composeIndex: composeIndex,
                                         remainingCho: remainingCho,
                                         remainingJung: remainingJung,
                                         remainingJong: remainingJong)
                    }
                } else {
                    // 완전한 음절 베이스 없음
                    composeIndex.jong = jongIdx
                    // 첫 번째 유니코드 스칼라 제거, not the first Character
                    let index = remainingJong.unicodeScalars.index(after: remainingJong.unicodeScalars.startIndex)
                    remainingJong = String(remainingJong.unicodeScalars[index...])
                    return buildResult(composeIndex: composeIndex,
                                     remainingCho: remainingCho,
                                     remainingJung: remainingJung,
                                     remainingJong: remainingJong)
                }
            }
        }
        
        return buildResult(composeIndex: composeIndex,
                         remainingCho: remainingCho,
                         remainingJung: remainingJung,
                         remainingJong: remainingJong)
    }
    
    // MARK: - Private 메서드
    
    private static func buildResult(composeIndex: (cho: Int?, jung: Int?, jong: Int?),
                                  remainingCho: String,
                                  remainingJung: String,
                                  remainingJong: String) -> CompositionResult {
        let remaining = buildRemainingState(cho: remainingCho, jung: remainingJung, jong: remainingJong)
        
        // 완전한 음절 조합 (초성 + 중성 필수)
        if let choIdx = composeIndex.cho, let jungIdx = composeIndex.jung {
            // 공식: 0xAC00 + (초성_인덱스 * 588) + (중성_인덱스 * 28) + 종성_인덱스
            var syllableCode = Int(UnicodeConstants.syllableBase)
            syllableCode += choIdx * Int(UnicodeConstants.syllablesPerChoseong)
            syllableCode += jungIdx * Int(UnicodeConstants.jongseongCount)
            
            if let jongIdx = composeIndex.jong {
                syllableCode += jongIdx
            }
            
            if let scalar = UnicodeScalar(syllableCode) {
                return CompositionResult(composed: String(Character(scalar)), remaining: remaining)
            }
        }
        
        // 부분 조합 - 호환 자모로 반환
        if let choIdx = composeIndex.cho {
            let code = Int(UnicodeConstants.choseongBase) + choIdx
            if let scalar = UnicodeScalar(code) {
                let jamo = String(Character(scalar))
                return CompositionResult(
                    composed: UnicodeUtils.jamoToCompatibility(jamo),
                    remaining: remaining
                )
            }
        } else if let jungIdx = composeIndex.jung {
            let code = Int(UnicodeConstants.jungseongBase) + jungIdx
            if let scalar = UnicodeScalar(code) {
                let jamo = String(Character(scalar))
                return CompositionResult(
                    composed: UnicodeUtils.jamoToCompatibility(jamo),
                    remaining: remaining
                )
            }
        } else if let jongIdx = composeIndex.jong {
            let code = Int(UnicodeConstants.jongseongBase) + jongIdx
            if let scalar = UnicodeScalar(code) {
                let jamo = String(Character(scalar))
                return CompositionResult(
                    composed: UnicodeUtils.jamoToCompatibility(jamo),
                    remaining: remaining
                )
            }
        }
        
        return CompositionResult(composed: nil, remaining: remaining)
    }
    
    private static func buildCompatibilityResult(cho: String, jung: String, jong: String) -> CompositionResult {
        // 첫 번째 문자를 호환 자모로 변환
        if !cho.isEmpty {
            let firstChar = String(cho.first!)
            let compatChar = UnicodeUtils.jamoToCompatibility(firstChar)
            
            var remaining = cho
            remaining.removeFirst()
            let remainingState = buildRemainingState(cho: remaining, jung: jung, jong: jong)
            
            return CompositionResult(composed: compatChar, remaining: remainingState)
        } else if !jung.isEmpty {
            let firstChar = String(jung.first!)
            let compatChar = UnicodeUtils.jamoToCompatibility(firstChar)
            
            var remaining = jung
            remaining.removeFirst()
            let remainingState = buildRemainingState(cho: cho, jung: remaining, jong: jong)
            
            return CompositionResult(composed: compatChar, remaining: remainingState)
        } else if !jong.isEmpty {
            let firstChar = String(jong.first!)
            let compatChar = UnicodeUtils.jamoToCompatibility(firstChar)
            
            var remaining = jong
            remaining.removeFirst()
            let remainingState = buildRemainingState(cho: cho, jung: jung, jong: remaining)
            
            return CompositionResult(composed: compatChar, remaining: remainingState)
        }
        
        return CompositionResult(composed: nil, remaining: nil)
    }
    
    private static func buildRemainingState(cho: String, jung: String, jong: String) -> SyllableDisplayState? {
        if cho.isEmpty && jung.isEmpty && jong.isEmpty {
            return nil
        }
        
        let remaining = SyllableDisplayState()
        
        if !cho.isEmpty {
            remaining.remainingChoseong = cho
        }
        if !jung.isEmpty {
            remaining.remainingJungseong = jung
        }
        if !jong.isEmpty {
            remaining.remainingJongseong = jong
        }
        
        return remaining
    }
}