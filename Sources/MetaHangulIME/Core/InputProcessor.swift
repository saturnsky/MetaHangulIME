//
//  InputProcessor.swift
//  MetaHangulIME
//
//  메타 한글 입력기의 핵심 입력 처리 엔진
//

import Foundation

/// InputProcessor 설정
public struct InputProcessorConfig {
    public let orderMode: OrderMode
    public let jamoCommitPolicy: JamoCommitPolicy
    public let nonJamoCommitPolicy: NonJamoCommitPolicy
    public let transitionCommitPolicy: TransitionCommitPolicy
    public let displayMode: DisplayMode
    public let supportStandaloneCluster: Bool

    public init(
        orderMode: OrderMode = .sequential,
        jamoCommitPolicy: JamoCommitPolicy = .syllable,
        nonJamoCommitPolicy: NonJamoCommitPolicy = .onComplete,
        transitionCommitPolicy: TransitionCommitPolicy = .always,
        displayMode: DisplayMode = .modernMultiple,
        supportStandaloneCluster: Bool = false
    ) {
        self.orderMode = orderMode
        self.jamoCommitPolicy = jamoCommitPolicy
        self.nonJamoCommitPolicy = nonJamoCommitPolicy
        self.transitionCommitPolicy = transitionCommitPolicy
        self.displayMode = displayMode
        self.supportStandaloneCluster = supportStandaloneCluster
    }
}

public enum JamoState: Int {
    case empty = 0 // 없음
    case jamo = 1  // 자모 입력 키
    case nonJamo = 2 // 비자모 입력 키
}

/// 입력 처리 결과
/// 주의: previousState는 변환 전의 상태를 뜻하는 것이 아니라, 이전 음절의 상태를 뜻함
public struct ProcessResult {
    /// 전이로 인한 자동 커밋이 발생할지 여부
    public let needAutoCommit: Bool

    /// 이전 음절의 상태값 (도깨비불 처리용)
    public let previousState: SyllableState?

    /// 현재 음절의 상태값
    public let currentState: SyllableState

    /// 커서 이동 (0: 유지, 1: 새 음절)
    public let cursorMovement: Int
}

/// 백스페이스 처리 결과
public struct BackspaceProcessResult {
    /// 수정된 이전 음절의 상태 (역 도깨비불 처리용)
    public let previousState: SyllableState?

    /// 백스페이스 후 현재 음절의 상태
    public let currentState: SyllableState
}

// swiftlint:disable type_body_length
/// 핵심 입력 처리 엔진
public final class InputProcessor {
    // 오토마타
    private let choseongAutomaton: ChoseongAutomaton
    private let jungseongAutomaton: JungseongAutomaton
    private let jongseongAutomaton: JongseongAutomaton
    private let nonJamoAutomaton: NonJamoAutomaton?
    private let dokkaebiAutomaton: DokkaebiAutomaton?
    private let backspaceAutomaton: BackspaceAutomaton?

    // 설정
    public let config: InputProcessorConfig

    // Display 빌더
    private let displayBuilder: DisplayBuilder

    // 성능 최적화: 오토마타 조회 캐시
    private lazy var automatonMap: [JamoPosition: Automaton] = [
        .choseong: choseongAutomaton,
        .jungseong: jungseongAutomaton,
        .jongseong: jongseongAutomaton,
    ]

    public init(
        choseongAutomaton: ChoseongAutomaton,
        jungseongAutomaton: JungseongAutomaton,
        jongseongAutomaton: JongseongAutomaton,
        nonJamoAutomaton: NonJamoAutomaton? = nil,
        dokkaebiAutomaton: DokkaebiAutomaton? = nil,
        backspaceAutomaton: BackspaceAutomaton? = nil,
        config: InputProcessorConfig = InputProcessorConfig()
    ) {
        self.choseongAutomaton = choseongAutomaton
        self.jungseongAutomaton = jungseongAutomaton
        self.jongseongAutomaton = jongseongAutomaton
        self.nonJamoAutomaton = nonJamoAutomaton
        self.dokkaebiAutomaton = dokkaebiAutomaton
        self.backspaceAutomaton = backspaceAutomaton
        self.config = config

        // DisplayBuilder 초기화
        self.displayBuilder = DisplayBuilder(
            choseongAutomaton: choseongAutomaton,
            jungseongAutomaton: jungseongAutomaton,
            jongseongAutomaton: jongseongAutomaton,
            nonJamoAutomaton: nonJamoAutomaton,
            displayMode: config.displayMode
        )
    }

    /// 백스페이스 처리
    /// - 이전 상태와 현재 상태를 받아 백스페이스 후의 상태를 반환
    /// - 이전 상태는 '역 도깨비불' 현상을 처리하기 위해 사용
    public func processBackspace(
        previousState: SyllableState?,
        currentState: SyllableState
    ) -> BackspaceProcessResult {
        // 현재 상태가 비어있으면 동작하지 않음
        if currentState.isEmpty {
            return BackspaceProcessResult(previousState: previousState, currentState: currentState)
        }

        // Non-Jamo 상태가 있으면 NonJamo 백스페이스 처리
        if currentState.nonJamoState != nil {
            return processNonJamoBackspace(
                previousState: previousState,
                currentState: currentState
            )
        }

        // Jamo 상태 처리
        return processJamoBackspace(
            previousState: previousState,
            currentState: currentState
        )
    }

    /// 현재 상태의 표시 문자열 생성
    /// - archaic 모드: 현대 한글로 조합되면 현대 한글로. 아니면 NFD로 표시
    /// - modernMultiple 모드: 조합할 수 없는 자모를 별도 음절로 풀어서 표시
    /// - modernPartial 모드: 첫 음절에서 표시 가능한 부분까지만 표시
    public func buildDisplay(_ state: SyllableState) -> String {
        displayBuilder.buildDisplay(state)
    }

    /// NonJamo 오토마타에서 추가 전이가 가능한지 확인
    public func canTransitionFurtherForNonJamo(from state: String) -> Bool {
        guard let automaton = nonJamoAutomaton else {
            return false
        }
        return automaton.canTransition(from: state)
    }

    /// 입력 키 통합 처리
    public func process(
        previousState: SyllableState?,
        currentState: SyllableState,
        inputKey: VirtualKey
    ) -> ProcessResult {
        // 현재 상태를 확인
        let currentJamoState: JamoState = currentState.isEmpty ? .empty : currentState.hasJamo ? .jamo : .nonJamo
        if currentJamoState == .empty {
            // 현재 상태가 비어있으면 새 음절 생성
            let newState: SyllableState = createNewSyllableWithInput(inputKey: inputKey)
            return ProcessResult(
                needAutoCommit: false,
                previousState: previousState,
                currentState: newState,
                cursorMovement: 0
            )
        } else if currentJamoState == .nonJamo {
            // 현재 상태가 Non-Jamo 상태인 경우, Non-Jamo Transition을 우선적으로 시도
            if let newSpecialFromCurrent = nonJamoAutomaton?.transition(
                currentState: currentState.nonJamoState,
                inputKey: inputKey.keyIdentifier
            ) {
                let newState = currentState.copy()
                newState.nonJamoState = newSpecialFromCurrent
                return ProcessResult(
                    needAutoCommit: false,
                    previousState: previousState,
                    currentState: newState,
                    cursorMovement: 0
                )
            }
            // Non-Jamo 상태에서 전이가 불가능한 경우, 새 음절 생성
            let newState: SyllableState = createNewSyllableWithInput(inputKey: inputKey)
            if config.transitionCommitPolicy == .always && newState.hasJamo {
                // 새로 입력된 키가 Jamo일 경우, transition이 발생하였으니 커밋 처리
                return ProcessResult(
                    needAutoCommit: true,
                    previousState: nil,
                    currentState: newState,
                    cursorMovement: 0
                )
            }
            return ProcessResult(
                needAutoCommit: false,
                previousState: currentState,
                currentState: newState,
                cursorMovement: 1
            )
        }
        // 이 아래는 현재 상태가 Jamo인 경우

        // 종성부용초성 모드가 켜져 있을 경우, 종성부용초성 조건을 먼저 확인
        if config.supportStandaloneCluster &&
           currentState.jongseongState == nil &&
           currentState.jungseongState == nil &&
           currentState.choseongState != nil {
            if let newState = tryStandaloneCluster(currentState: currentState, inputKey: inputKey) {
                return ProcessResult(
                    needAutoCommit: false,
                    previousState: previousState,
                    currentState: newState,
                    cursorMovement: 0
                )
            }
        }

        // 현재 음절에 낱자 추가 시도
        if let tryResult = tryAddToCurrentSyllable(currentState: currentState, inputKey: inputKey) {
            return ProcessResult(
                needAutoCommit: false,
                previousState: previousState,
                currentState: tryResult,
                cursorMovement: 0
            )
        }

        // 도깨비불 조합 시도
        if let dokkaebiResult = tryDokkaebi(currentState: currentState, inputKey: inputKey) {
            return dokkaebiResult
        }

        // 모든 조건에 해당하지 않을 경우 새 음절을 생성
        let newState = createNewSyllableWithInput(inputKey: inputKey)

        if currentJamoState == .empty {
            return ProcessResult(
                needAutoCommit: false,
                previousState: previousState,
                currentState: newState,
                cursorMovement: 0
            )
        } else {
            // 새로 입력된 결과가 Non-Jamo인 경우
            if config.transitionCommitPolicy == .always && !newState.hasJamo {
                // Non-Jamo 상태로 전이되었으니 커밋 처리
                return ProcessResult(
                    needAutoCommit: true,
                    previousState: nil,
                    currentState: newState,
                    cursorMovement: 0
                )
            }

            return ProcessResult(
                needAutoCommit: false,
                previousState: currentState,
                currentState: newState,
                cursorMovement: 1
            )
        }
    }

    /// '종성부용초성' 동작이 가능한지 확인
    private func tryStandaloneCluster(
        currentState: SyllableState,
        inputKey: VirtualKey
    ) -> SyllableState? {
        guard let choseong = currentState.choseongState else { return nil }
        let newState = currentState.copy()

        // 초성 조합을 먼저 시도
        if let newChoseong = choseongAutomaton.transition(
            currentState: choseong,
            inputKey: inputKey.keyIdentifier
        ) {
            newState.addJamo(position: .choseong, state: newChoseong)
            return newState
        }

        // 종성으로 시도
        if let jongseong = jongseongAutomaton.transition(
            currentState: choseong,
            inputKey: inputKey.keyIdentifier
        ) {
            // 종성으로 재해석
            newState.jongseongState = jongseong
            newState.choseongState = nil
            newState.compositionOrder = [.jongseong]
            return newState
        }

        return nil
    }

    /// 현재 음절에 낱자를 추가할 수 있는지 확인
    private func tryAddToCurrentSyllable(
        currentState: SyllableState,
        inputKey: VirtualKey
    ) -> SyllableState? {
        let allowedPositions = getAllowedPositions(for: currentState)

        for position in allowedPositions {
            guard let automaton = automatonMap[position] else { continue }

            let currentJamo = currentState.getJamoState(for: position)
            if let newState = automaton.transition(
                currentState: currentJamo,
                inputKey: inputKey.keyIdentifier
            ) {
                let newCurrent = currentState.copy()
                newCurrent.addJamo(position: position, state: newState)
                return newCurrent
            }
        }

        return nil
    }

    /// 현재 음절에 낱자를 추가 가능한 위치를 반환
    private func getAllowedPositions(for state: SyllableState) -> [JamoPosition] {
        switch config.orderMode {
        case .sequential:
            return getSequentialAllowedPositions(for: state)
        case .freeOrder:
            return getFreeOrderAllowedPositions(for: state)
        }
    }

    /// 순차적 조합 모드에서 현재 상태에 따라 추가 가능한 위치를 반환
    private func getSequentialAllowedPositions(for state: SyllableState) -> [JamoPosition] {
        if state.choseongState != nil && state.jungseongState == nil && state.jongseongState == nil {
            return [.choseong, .jungseong]
        } else if state.choseongState != nil && state.jungseongState != nil && state.jongseongState == nil {
            return [.jungseong, .jongseong]
        } else if state.choseongState != nil && state.jungseongState != nil && state.jongseongState != nil {
            return [.jongseong]
        } else if state.isEmpty {
            return [.choseong, .jungseong, .jongseong]
        } else if state.choseongState == nil && state.jungseongState != nil && state.jongseongState == nil {
            // 중성만 존재 - 추가 중성 조합 허용
            return [.jungseong]
        } else if state.choseongState == nil && state.jungseongState == nil && state.jongseongState != nil {
            // 종성만 존재 - 추가 종성 조합 허용
            return [.jongseong]
        }
        return []
    }

    /// 자유 조합 모드에서 현재 상태에 따라 추가 가능한 위치를 반환
    private func getFreeOrderAllowedPositions(for state: SyllableState) -> [JamoPosition] {
        var allowed: [JamoPosition] = []

        // 마지막으로 추가된 위치를 먼저 추가
        if let last = state.compositionOrder.last {
            allowed.append(last)
        }

        // 나머지 빈 위치를 추가 (중복 방지)
        for position in JamoPosition.allCases {
            let currentJamo = state.getJamoState(for: position)
            if currentJamo == nil && position != state.compositionOrder.last {
                allowed.append(position)
            }
        }

        return allowed
    }

    /// 도깨비불 조합을 시도 (중성-도깨비불 및 초성-도깨비불)
    private func tryDokkaebi(
        currentState: SyllableState,
        inputKey: VirtualKey
    ) -> ProcessResult? {
        guard let dokkaebi = dokkaebiAutomaton,
              let jongseong = currentState.jongseongState,
              currentState.compositionOrder.isEmpty || currentState.compositionOrder.last == .jongseong
        else { return nil }

        let inputIdentifier = inputKey.keyIdentifier
        var dokkaebiResult: DokkaebiResult?
        var isJungseongDokkaebi = false

        // 중성-도깨비불 체크 (입력키가 중성으로 전이 가능한 경우)
        if jungseongAutomaton.transition(currentState: nil, inputKey: inputIdentifier) != nil {
            let result = dokkaebi.processJungseongDokkaebi(jongseong)
            if result.shouldSplit {
                dokkaebiResult = result
                isJungseongDokkaebi = true
            }
        }

        // 초성-도깨비불 체크 (입력키가 초성으로 전이 가능한 경우)
        if dokkaebiResult == nil && choseongAutomaton.transition(currentState: nil, inputKey: inputIdentifier) != nil {
            let result = dokkaebi.processChoseongDokkaebi(jongseong, inputKey: inputIdentifier)
            if result.shouldSplit {
                dokkaebiResult = result
                isJungseongDokkaebi = false
            }
        }

        guard let result = dokkaebiResult else { return nil }

        // 이전 음절의 종성 정보를 업데이트
        let updatedPrevious = currentState.copy()
        updatedPrevious.jongseongState = result.remainingJongseongState
        if result.remainingJongseongState == nil,
           let lastIdx = updatedPrevious.compositionOrder.lastIndex(of: .jongseong) {
            updatedPrevious.compositionOrder.remove(at: lastIdx)
        }

        // 새 음절을 생성하고 이동된 초성과 입력된 키를 추가
        let newCurrent = SyllableState()
        newCurrent.choseongState = result.movedChoseongState
        newCurrent.compositionOrder.append(.choseong)

        if isJungseongDokkaebi {
            // 중성-도깨비불: 입력된 중성 낱자를 추가
            if let jungseong = jungseongAutomaton.transition(
                currentState: nil,
                inputKey: inputIdentifier
            ) {
                newCurrent.jungseongState = jungseong
                newCurrent.compositionOrder.append(.jungseong)
            }
        } else {
            // 초성-도깨비불: 결과를 그대로 반영
            newCurrent.choseongState = result.movedChoseongState
            newCurrent.compositionOrder.append(.choseong)
        }

        return ProcessResult(
            needAutoCommit: false,
            previousState: updatedPrevious,
            currentState: newCurrent,
            cursorMovement: 1
        )
    }

    private func createNewSyllableWithInput(inputKey: VirtualKey) -> SyllableState {
        let newState = SyllableState()

        // 우선 Non-Jamo 오토마타부터 확인
        if let nonJamoState = nonJamoAutomaton?.transition(currentState: nil, inputKey: inputKey.keyIdentifier) {
            // Non-Jamo 오토마타로 조합 가능한 경우, Non-Jamo 상태로 새 음절 생성
            newState.nonJamoState = nonJamoState
            return newState
        }

        // 순서대로 확인: 초성, 중성, 종성
        // 이렇게 하면 새 음절 시작 시 자음이 먼저 초성으로 감
        let orderedPositions: [JamoPosition] = [.choseong, .jungseong, .jongseong]

        for position in orderedPositions {
            guard let automaton = automatonMap[position] else { continue }
            if let state = automaton.transition(currentState: nil, inputKey: inputKey.keyIdentifier) {
                newState.addJamo(position: position, state: state)
                break
            }
        }

        if newState.isEmpty {
            // 입력된 키가 어떤 자모로도 조합되지 않는 경우, Non-Jamo 상태로 설정
            newState.nonJamoState = inputKey.keyIdentifier
        }

        return newState
    }

    /// 자모 백스페이스 처리
    private func processJamoBackspace(
        previousState: SyllableState?,
        currentState: SyllableState
    ) -> BackspaceProcessResult {
        // 이전 상태를 보존하면서 현재 상태를 처리
        let result = processBackspaceOnState(currentState)

        // 역 도깨비불 확인
        if config.jamoCommitPolicy == .explicitCommit,
           let reverseResult = tryReverseDokkaebi(
               previousState: previousState,
               currentState: result.currentState
           ) {
            return reverseResult
        }

        // 보존된 이전 상태와 함께 반환
        return BackspaceProcessResult(previousState: previousState, currentState: result.currentState)
    }

    /// 음절 하나에 대해 백스페이스를 처리하는 메서드
    private func processBackspaceOnState(_ state: SyllableState) -> BackspaceProcessResult {
        guard let lastPosition = state.compositionOrder.last else {
            return BackspaceProcessResult(previousState: nil, currentState: state)
        }

        guard let currentJamo = state.getJamoState(for: lastPosition) else {
            return BackspaceProcessResult(previousState: nil, currentState: state)
        }

        // 백스페이스 적용
        let newJamo: String?
        if let backspace = backspaceAutomaton {
            newJamo = backspace.process(currentJamo).newState
        } else {
            newJamo = nil
        }

        state.setJamoState(for: lastPosition, state: newJamo)

        // 완전히 삭제된 경우 조합 순서에서 제거
        if newJamo == nil {
            state.compositionOrder.removeLast()
        }

        // '종성부용초성 되돌리기'
        if config.supportStandaloneCluster,
           lastPosition == .jongseong,
           state.choseongState == nil,
           state.jungseongState == nil,
           let jong = state.jongseongState,
           choseongAutomaton.hasState(jong) {
            state.choseongState = jong
            state.jongseongState = nil
            state.compositionOrder = [.choseong]
        }

        return BackspaceProcessResult(previousState: nil, currentState: state)
    }

    /// 역 도깨비불 현상을 처리하는 메서드
    private func tryReverseDokkaebi(
        previousState: SyllableState?,
        currentState: SyllableState
    ) -> BackspaceProcessResult? {
        // 가장 기본적인 역 도깨비불 시나리오
        guard let prev = previousState,
              prev.choseongState != nil,
              prev.jungseongState != nil,
              currentState.choseongState != nil,
              currentState.jungseongState == nil,
              currentState.jongseongState == nil,
              let currentCho = currentState.choseongState
        else { return nil }

        // 복잡한 역 도깨비불 시나리오

        // 조건: 이전 composition_order가 종성으로 끝나거나 종성이 없어야 역 도깨비불 테스트가 가능
        let canReverseDokkaebi: Bool
        if prev.jongseongState == nil {
            canReverseDokkaebi = true
        } else if let lastPos = prev.compositionOrder.last, lastPos == .jongseong {
            canReverseDokkaebi = true
        } else {
            canReverseDokkaebi = false
        }

        if !canReverseDokkaebi {
            return nil
        }

        // 현재 초성을 이전 상태의 종성과 결합 시도
        if let prevJong = prev.jongseongState {
            // Case 1: 이전 상태에 이미 종성이 있음. 결합 시도
            if let combined = jongseongAutomaton.transition(
                currentState: prevJong,
                inputKey: currentCho
            ) {
                prev.jongseongState = combined
                // 현재 음절이 소비되고 이전 음절이 업데이트됨
                // 수정된 이전 상태를 새로운 현재 상태로 반환
                return BackspaceProcessResult(previousState: nil, currentState: prev)
            }
        } else if jongseongAutomaton.hasState(currentCho) {
            // Case 2: 이전 상태에 종성이 없고, 초성이 종성으로 쓰일 수 있음
            // 현재 초성을 새 종성으로 이동
            prev.jongseongState = currentCho
            prev.compositionOrder.append(.jongseong)
            // 현재 음절이 소비되고 이전 음절이 업데이트됨
            return BackspaceProcessResult(previousState: nil, currentState: prev)
        }

        return nil
    }

    /// Non-Jamo 상태에 대한 백스페이스 처리
    private func processNonJamoBackspace(
        previousState: SyllableState?,
        currentState: SyllableState
    ) -> BackspaceProcessResult {
        // Non-Jamo 상태가 없으면 처리하지 않음
        guard currentState.nonJamoState != nil else {
            return BackspaceProcessResult(previousState: previousState, currentState: currentState)
        }

        // Non-Jamo 상태 제거
        currentState.nonJamoState = nil

        return BackspaceProcessResult(previousState: previousState, currentState: currentState)
    }
}
// swiftlint:enable type_body_length
