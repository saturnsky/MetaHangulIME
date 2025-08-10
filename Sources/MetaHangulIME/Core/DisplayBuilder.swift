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
        if let specialChar = state.specialCharacterState {
            return nonJamoAutomaton?.display(specialChar) ?? ""
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
        let cho = state.choseongState.map { choseongAutomaton.display($0) } ?? ""
        let jung = state.jungseongState.map { jungseongAutomaton.display($0) } ?? ""
        let jong = state.jongseongState.map { jongseongAutomaton.display($0) } ?? ""

        let (composed, remaining) = tryComposeSyllable(cho: cho, jung: jung, jong: jong)

        // 모든 자모가 조합된 경우(남은 상태 없음) 조합된 결과 반환
        // 그렇지 않으면 NFD로 표시
        if remaining == nil {
            return composed ?? ""
        } else {
            return concatenateJamoDisplays(state)
        }
    }

    /// 현대 한글로 조합할 수 없는 음절은 여러 음절로 풀어서 표시하는 메서드
    private func buildMultipleSyllables(_ state: SyllableState) -> String {
        guard state.hasJamo else { return "" }

        var result = ""
        var cho = state.choseongState.map { choseongAutomaton.display($0) } ?? ""
        var jung = state.jungseongState.map { jungseongAutomaton.display($0) } ?? ""
        var jong = state.jongseongState.map { jongseongAutomaton.display($0) } ?? ""

        while !cho.isEmpty || !jung.isEmpty || !jong.isEmpty {
            let (composed, remaining) = tryComposeSyllable(cho: cho, jung: jung, jong: jong)

            if let composed = composed {
                result += composed
            }

            if let remaining = remaining {
                // 남은 상태는 이미 상태 이름이 아닌 표시 문자열을 포함
                cho = remaining.remainingChoseong ?? ""
                jung = remaining.remainingJungseong ?? ""
                jong = remaining.remainingJongseong ?? ""
            } else {
                break
            }
        }

        return result
    }

    /// 현대 한글로 조합할 수 있는 부분까지만 표시하는 메서드
    private func buildPartialDisplay(_ state: SyllableState) -> String {
        guard state.hasJamo else { return "" }

        let cho = state.choseongState.map { choseongAutomaton.display($0) } ?? ""
        let jung = state.jungseongState.map { jungseongAutomaton.display($0) } ?? ""
        let jong = state.jongseongState.map { jongseongAutomaton.display($0) } ?? ""

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
