//
//  DokkaebiAutomaton.swift
//  MetaHangulIME
//
//  Handles the 'dokkaebi' (도깨비불) phenomenon in Korean typing
//

import Foundation

/// 초성-도깨비불 전이 정보를 담는 구조체
public struct ChoseongTransition {
    let jongseong: String
    let inputKey: String
    let remaining: String?
    let moved: String
}

/// 도깨비불 처리 결과
public struct DokkaebiResult {
    /// 도깨비불 분리가 발생해야 하는지 여부
    public let shouldSplit: Bool

    /// 현재 음절에 남아있는 종성 상태 (완전히 이동한 경우 nil)
    public let remainingJongseongState: String?

    /// 다음 음절로 이동할 초성 상태
    public let movedChoseongState: String

    public init(
        shouldSplit: Bool,
        remainingJongseongState: String? = nil,
        movedChoseongState: String = ""
    ) {
        self.shouldSplit = shouldSplit
        self.remainingJongseongState = remainingJongseongState
        self.movedChoseongState = movedChoseongState
    }
}

/// 한글 타이핑의 '도깨비불' 현상을 처리
///
/// 도깨비불 현상은 종성(받침)이 다음과 같이 분리되는 현상:
/// 1. 현재 음절에 남아있는 종성 (또는 nil)
/// 2. 다음 음절의 초성(첫소리)
///
/// 도깨비불의 두 가지 유형:
/// 1. 중성-도깨비불: 모음 입력으로 발생 (예: 갃 + ㅣ -> 각 + 시)
/// 2. 초성-도깨비불: 자음 입력으로 발생 (예: 롵 + ㅌ -> 로 + 뜨) (천지인플러스)
public final class DokkaebiAutomaton {
    // MARK: - Pattern Support

    /// Compiled jungseong dokkaebi pattern
    private struct JungseongPattern {
        let jongseongPattern: Automaton.FromPattern
        let remainingPattern: Automaton.ToPattern
        let movedPattern: Automaton.ToPattern
    }

    /// Compiled choseong dokkaebi pattern
    private struct ChoseongPattern {
        let jongseongPattern: Automaton.FromPattern
        let inputKey: String
        let remainingPattern: Automaton.ToPattern
        let movedPattern: Automaton.ToPattern
    }

    // MARK: - Storage

    /// Tier 1: Exact match 중성-도깨비불 전이 테이블: jongseong -> (remaining, moved)
    private var jungseongTransitionTable: [String: (remaining: String?, moved: String)] = [:]

    /// Tier 2: Pattern match 중성-도깨비불
    private var jungseongPatterns: [JungseongPattern] = []

    /// Tier 1: Exact match 초성-도깨비불 전이 테이블: (jongseong, inputKey) -> (remaining, moved)
    private var choseongTransitionTable: [String: [String: (remaining: String?, moved: String)]] = [:]

    /// Tier 2: Pattern match 초성-도깨비불
    private var choseongPatterns: [ChoseongPattern] = []

    /// Temporary automaton instance for pattern parsing
    private let patternParser = Automaton()

    public init() {}

    /// 중성-도깨비불 전이 규칙 추가
    /// - Parameters:
    ///   - jongseongState: 도깨비불을 발생시키는 종성 상태 (패턴 지원: "{:3}ㅅ")
    ///   - remainingJong: 남아있는 종성 (완전히 이동하면 nil, 패턴 지원: "{:3}")
    ///   - movedCho: 다음 음절로 이동할 초성 (패턴 지원: "{-1}")
    public func addJungseongTransition(
        jongseongState: String,
        remainingJong: String?,
        movedCho: String
    ) {
        // Parse patterns
        let jongPattern = patternParser.parseFromPattern(jongseongState)
        let remainingPattern = patternParser.parseToPattern(remainingJong ?? "")
        let movedPattern = patternParser.parseToPattern(movedCho)

        // Check if exact match
        if jongPattern.isExact {
            // Tier 1: Exact match
            jungseongTransitionTable[jongseongState] = (remainingJong, movedCho)
        } else {
            // Tier 2: Pattern match
            jungseongPatterns.append(JungseongPattern(
                jongseongPattern: jongPattern,
                remainingPattern: remainingPattern,
                movedPattern: movedPattern
            ))
        }
    }

    /// 초성-도깨비불 전이 규칙 추가
    /// - Parameters:
    ///   - jongseongState: 도깨비불을 발생시키는 종성 상태 (패턴 지원: "{:2}ㅌ")
    ///   - inputKey: 전이를 발생시키는 입력 키
    ///   - remainingJong: 남아있는 종성 (완전히 이동하면 nil, 패턴 지원: "{0:2}")
    ///   - movedCho: 다음 음절로 이동할 초성
    public func addChoseongTransition(
        jongseongState: String,
        inputKey: String,
        remainingJong: String?,
        movedCho: String
    ) {
        // Parse patterns
        let jongPattern = patternParser.parseFromPattern(jongseongState)
        let remainingPattern = patternParser.parseToPattern(remainingJong ?? "")
        let movedPattern = patternParser.parseToPattern(movedCho)

        // Check if exact match
        if jongPattern.isExact {
            // Tier 1: Exact match
            if choseongTransitionTable[jongseongState] == nil {
                choseongTransitionTable[jongseongState] = [:]
            }
            choseongTransitionTable[jongseongState]![inputKey] = (remainingJong, movedCho)
        } else {
            // Tier 2: Pattern match
            choseongPatterns.append(ChoseongPattern(
                jongseongPattern: jongPattern,
                inputKey: inputKey,
                remainingPattern: remainingPattern,
                movedPattern: movedPattern
            ))
        }
    }

    /// 주어진 종성에서 중성-도깨비불이 발생할 수 있는지 확인
    /// - Parameter jongseongState: 현재 종성 상태
    /// - Returns: 중성-도깨비불이 발생할 수 있으면 true
    public func canSplitForJungseong(_ jongseongState: String) -> Bool {
        // Tier 1: Exact match
        if jungseongTransitionTable[jongseongState] != nil {
            return true
        }

        // Tier 2: Pattern match
        for pattern in jungseongPatterns {
            if pattern.jongseongPattern.match(state: jongseongState) != nil {
                return true
            }
        }

        return false
    }

    /// 주어진 종성과 입력에서 초성-도깨비불이 발생할 수 있는지 확인
    /// - Parameters:
    ///   - jongseongState: 현재 종성 상태
    ///   - inputKey: 입력 키
    /// - Returns: 초성-도깨비불이 발생할 수 있으면 true
    public func canSplitForChoseong(_ jongseongState: String, inputKey: String) -> Bool {
        // Tier 1: Exact match
        if choseongTransitionTable[jongseongState]?[inputKey] != nil {
            return true
        }

        // Tier 2: Pattern match
        for pattern in choseongPatterns where pattern.inputKey == inputKey {
            if pattern.jongseongPattern.match(state: jongseongState) != nil {
                return true
            }
        }

        return false
    }

    /// 중성-도깨비불 현상 처리
    /// - Parameter jongseongState: 현재 종성 상태
    /// - Returns: 분리 정보를 담은 DokkaebiResult
    public func processJungseongDokkaebi(_ jongseongState: String) -> DokkaebiResult {
        // Tier 1: Exact match
        if let (remaining, moved) = jungseongTransitionTable[jongseongState] {
            return DokkaebiResult(
                shouldSplit: true,
                remainingJongseongState: remaining,
                movedChoseongState: moved
            )
        }

        // Tier 2: Pattern match
        for pattern in jungseongPatterns {
            if let captured = pattern.jongseongPattern.match(state: jongseongState) {
                let remaining = pattern.remainingPattern.apply(captured: captured)
                let moved = pattern.movedPattern.apply(captured: captured)
                return DokkaebiResult(
                    shouldSplit: true,
                    remainingJongseongState: remaining.isEmpty ? nil : remaining,
                    movedChoseongState: moved
                )
            }
        }

        return DokkaebiResult(
            shouldSplit: false,
            remainingJongseongState: jongseongState,
            movedChoseongState: ""
        )
    }

    /// 초성-도깨비불 현상 처리
    /// - Parameters:
    ///   - jongseongState: 현재 종성 상태
    ///   - inputKey: 입력 키
    /// - Returns: 분리 정보를 담은 DokkaebiResult
    public func processChoseongDokkaebi(_ jongseongState: String, inputKey: String) -> DokkaebiResult {
        // Tier 1: Exact match
        if let (remaining, moved) = choseongTransitionTable[jongseongState]?[inputKey] {
            return DokkaebiResult(
                shouldSplit: true,
                remainingJongseongState: remaining,
                movedChoseongState: moved
            )
        }

        // Tier 2: Pattern match
        for pattern in choseongPatterns where pattern.inputKey == inputKey {
            if let captured = pattern.jongseongPattern.match(state: jongseongState) {
                let remaining = pattern.remainingPattern.apply(captured: captured)
                let moved = pattern.movedPattern.apply(captured: captured)
                return DokkaebiResult(
                    shouldSplit: true,
                    remainingJongseongState: remaining.isEmpty ? nil : remaining,
                    movedChoseongState: moved
                )
            }
        }

        return DokkaebiResult(
            shouldSplit: false,
            remainingJongseongState: jongseongState,
            movedChoseongState: ""
        )
    }

    /// 성능을 위한 중성 전이 일괄 추가
    /// - Parameter transitions: (jongseong: String, remaining: String?, moved: String) 튜플 배열
    public func addJungseongTransitions(_ transitions: [(jongseong: String, remaining: String?, moved: String)]) {
        for transition in transitions {
            addJungseongTransition(
                jongseongState: transition.jongseong,
                remainingJong: transition.remaining,
                movedCho: transition.moved
            )
        }
    }

    /// 성능을 위한 초성 전이 일괄 추가
    /// - Parameter transitions: ChoseongTransition 구조체 배열
    public func addChoseongTransitions(_ transitions: [ChoseongTransition]) {
        for transition in transitions {
            addChoseongTransition(
                jongseongState: transition.jongseong,
                inputKey: transition.inputKey,
                remainingJong: transition.remaining,
                movedCho: transition.moved
            )
        }
    }
}
