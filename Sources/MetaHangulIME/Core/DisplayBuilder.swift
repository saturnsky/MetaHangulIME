//
//  DisplayBuilder.swift
//  MetaHangulIME
//
//  Display 문자열 생성을 담당하는 유틸리티
//

import Foundation

/// Display 문자열을 생성하는 빌더 클래스
/// InputProcessor에서 분리된 display 관련 로직을 담당
public final class DisplayBuilder {
    private let choseongAutomaton: ChoseongAutomaton
    private let jungseongAutomaton: JungseongAutomaton
    private let jongseongAutomaton: JongseongAutomaton
    private let nonJamoAutomaton: NonJamoAutomaton?
    private let displayMode: DisplayMode

    public init(
        choseongAutomaton: ChoseongAutomaton,
        jungseongAutomaton: JungseongAutomaton,
        jongseongAutomaton: JongseongAutomaton,
        nonJamoAutomaton: NonJamoAutomaton? = nil,
        displayMode: DisplayMode = .modernMultiple
    ) {
        self.choseongAutomaton = choseongAutomaton
        self.jungseongAutomaton = jungseongAutomaton
        self.jongseongAutomaton = jongseongAutomaton
        self.nonJamoAutomaton = nonJamoAutomaton
        self.displayMode = displayMode
    }

    /// 현재 상태의 표시 문자열 생성
    /// - archaic 모드: 현대 한글로 조합되면 현대 한글로. 아니면 NFD로 표시
    /// - modernMultiple 모드: 조합할 수 없는 자모를 별도 음절로 풀어서 표시
    /// - modernPartial 모드: 첫 음절에서 표시 가능한 부분까지만 표시
    public func buildDisplay(_ state: SyllableState) -> String {
        if let nonJamo = state.nonJamoState {
            return nonJamoAutomaton?.display(nonJamo) ?? ""
        }

        switch displayMode {
        case .archaic:
            return buildArchaicDisplay(state)
        case .modernMultiple:
            return buildMultipleSyllables(state)
        case .modernPartial:
            return buildPartialDisplay(state)
        }
    }

    // MARK: - Private Display Methods

    /// 현대 한글로 조합 가능한 음절은 현대 한글로, 아닌 음절은 옛한글로 표시하는 메서드
    private func buildArchaicDisplay(_ state: SyllableState) -> String {
        // displayPartialAll로 모든 글자를 Hangul Jamo로 변환
        let cho = state.choseongState.map { choseongAutomaton.displayPartialAll($0) } ?? ""
        let jung = state.jungseongState.map { jungseongAutomaton.displayPartialAll($0) } ?? ""
        let jong = state.jongseongState.map { jongseongAutomaton.displayPartialAll($0) } ?? ""

        let (composed, remaining) = tryComposeSyllable(cho: cho, jung: jung, jong: jong)

        if let composedChar = composed {
            // 부분 조합 성공: composed + remaining(NFD)
            var result = composedChar
            if let r = remaining {
                if let rCho = r.remainingChoseong { result += rCho }
                if let rJung = r.remainingJungseong { result += rJung }
                if let rJong = r.remainingJongseong { result += rJong }
            }
            return result
        } else {
            // 조합 불가능 (중성 없음 등): 전체 NFD
            return cho + jung + jong
        }
    }

    /// 현대 한글로 조합할 수 없는 음절은 여러 음절로 풀어서 표시하는 메서드
    private func buildMultipleSyllables(_ state: SyllableState) -> String {
        guard state.hasJamo else { return "" }

        var result = ""
        var choState = state.choseongState ?? ""
        var jungState = state.jungseongState ?? ""
        var jongState = state.jongseongState ?? ""

        // Process each jamo one by one using displayFirstMatch
        while !choState.isEmpty || !jungState.isEmpty || !jongState.isEmpty {
            // Get first match for each position
            var choDisplay = ""
            if !choState.isEmpty {
                let (display, remaining) = choseongAutomaton.displayFirstMatch(choState)
                choDisplay = display
                choState = remaining
            }

            var jungDisplay = ""
            if !jungState.isEmpty {
                let (display, remaining) = jungseongAutomaton.displayFirstMatch(jungState)
                jungDisplay = display
                jungState = remaining
            }

            var jongDisplay = ""
            if !jongState.isEmpty {
                let (display, remaining) = jongseongAutomaton.displayFirstMatch(jongState)
                jongDisplay = display
                jongState = remaining
            }

            // Try to compose syllable
            let (composed, remaining) = tryComposeSyllable(
                cho: choDisplay,
                jung: jungDisplay,
                jong: jongDisplay
            )

            if let composedChar = composed {
                // Composition succeeded (fully or partially)
                result += composedChar

                // Process remaining from tryComposeSyllable (if any)
                if remaining != nil {
                    var cho = remaining?.remainingChoseong ?? ""
                    var jung = remaining?.remainingJungseong ?? ""
                    var jong = remaining?.remainingJongseong ?? ""

                    while !cho.isEmpty || !jung.isEmpty || !jong.isEmpty {
                        let compatResult = HangulComposer.buildCompatibilityResult(
                            cho: cho,
                            jung: jung,
                            jong: jong
                        )
                        result += compatResult.composed ?? ""
                        cho = compatResult.remaining?.remainingChoseong ?? ""
                        jung = compatResult.remaining?.remainingJungseong ?? ""
                        jong = compatResult.remaining?.remainingJongseong ?? ""
                    }
                }
            } else {
                // Composition failed - convert to compatibility jamo
                var cho = choDisplay
                var jung = jungDisplay
                var jong = jongDisplay

                while !cho.isEmpty || !jung.isEmpty || !jong.isEmpty {
                    let compatResult = HangulComposer.buildCompatibilityResult(
                        cho: cho,
                        jung: jung,
                        jong: jong
                    )
                    result += compatResult.composed ?? ""
                    cho = compatResult.remaining?.remainingChoseong ?? ""
                    jung = compatResult.remaining?.remainingJungseong ?? ""
                    jong = compatResult.remaining?.remainingJongseong ?? ""
                }
            }
        }

        return result
    }

    /// 현대 한글로 조합할 수 있는 부분까지만 표시하는 메서드
    private func buildPartialDisplay(_ state: SyllableState) -> String {
        guard state.hasJamo else { return "" }

        // Get first match for each position (remaining is ignored)
        let cho = state.choseongState.map {
            choseongAutomaton.displayFirstMatch($0).display
        } ?? ""
        let jung = state.jungseongState.map {
            jungseongAutomaton.displayFirstMatch($0).display
        } ?? ""
        let jong = state.jongseongState.map {
            jongseongAutomaton.displayFirstMatch($0).display
        } ?? ""

        let (composed, _) = tryComposeSyllable(cho: cho, jung: jung, jong: jong)
        return composed ?? ""
    }

    private func concatenateJamoDisplays(_ state: SyllableState) -> String {
        var result = ""
        if let cho = state.choseongState {
            result += choseongAutomaton.display(cho)
        }
        if let jung = state.jungseongState {
            result += jungseongAutomaton.display(jung)
        }
        if let jong = state.jongseongState {
            result += jongseongAutomaton.display(jong)
        }
        return result
    }

    /// 초성, 중성, 종성을 조합하여 현대 한글 음절을 생성하는 메서드
    /// - 앞에서부터 조합에 성공하는 부분까지를 composed로 반환
    /// - 조합에 실패한 부분은 remaining으로 반환
    /// - 주의: 인자로 들어오는 cho, jung, jong는 이미 오토마타에 의해 표시 문자열로 변환된 상태여야 함
    private func tryComposeSyllable(cho: String, jung: String, jong: String)
        -> (composed: String?, remaining: SyllableDisplayState?) {
        let result = HangulComposer.tryComposeSyllable(cho: cho, jung: jung, jong: jong)
        return (result.composed, result.remaining)
    }
}
