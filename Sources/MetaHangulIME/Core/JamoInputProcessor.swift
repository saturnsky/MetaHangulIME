//
//  JamoInputProcessor.swift
//  MetaHangulIME
//
//  자모(Jamo) 입력 처리 전용 프로세서
//

import Foundation

/// 자모 입력 처리 전용 프로세서
public final class JamoInputProcessor {
    // 오토마타
    private let choseongAutomaton: ChoseongAutomaton
    private let jungseongAutomaton: JungseongAutomaton
    private let jongseongAutomaton: JongseongAutomaton
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
        dokkaebiAutomaton: DokkaebiAutomaton? = nil,
        backspaceAutomaton: BackspaceAutomaton? = nil,
        config: InputProcessorConfig,
        displayBuilder: DisplayBuilder
    ) {
        self.choseongAutomaton = choseongAutomaton
        self.jungseongAutomaton = jungseongAutomaton
        self.jongseongAutomaton = jongseongAutomaton
        self.dokkaebiAutomaton = dokkaebiAutomaton
        self.backspaceAutomaton = backspaceAutomaton
        self.config = config
        self.displayBuilder = displayBuilder
    }

    /// 자모 입력 처리
    public func process(
        previousState: SyllableState?,
        currentState: SyllableState,
        inputKey: VirtualKey
    ) -> ProcessResult {
        // 종성부용초성 모드가 켜져 있을 경우, 종성부용초성 조건을 먼저 확인
        // 현재 음절에 초성만이 존재하는 경우, 초성 조합을 먼저 시도하고, 종성 전이 후 조합을 시도
        if config.supportStandaloneCluster &&
           currentState.jongseongState == nil &&
           currentState.jungseongState == nil &&
           currentState.choseongState != nil {
            if tryStandaloneCluster(currentState: currentState, inputKey: inputKey) != nil {
                return ProcessResult(
                    previousState: previousState,
                    currentState: currentState,
                    cursorMovement: 0
                )
            }
        }

        // 현재 음절에 낱자를 추가할 수 있는지 확인
        // 순서 모드 조건을 충족하며 통과되는 오토마타가 있을 경우, 현재 음절에 낱자를 추가
        if tryAddToCurrentSyllable(currentState: currentState, inputKey: inputKey) {
            return ProcessResult(
                previousState: previousState,
                currentState: currentState,
                cursorMovement: 0
            )
        }

        // 일반적인 조합이 불가능할 경우, 도깨비불 조합을 시도
        // 현재 낱자에 종성이 있고, 도깨비불 오토마타에 따라 중성과 결합 가능한 경우 해당 결과를 반환
        if let dokkaebiResult = tryDokkaebi(currentState: currentState, inputKey: inputKey) {
            return dokkaebiResult
        }

        // 모든 조건에 해당하지 않을 경우 새 음절을 생성
        let newState = createNewSyllableWithInput(inputKey: inputKey)

        if currentState.isEmpty {
            return ProcessResult(
                previousState: previousState,
                currentState: newState,
                cursorMovement: 0
            )
        } else {
            return ProcessResult(
                previousState: currentState,
                currentState: newState,
                cursorMovement: 1
            )
        }
    }

    /// 백스페이스 처리
    public func processBackspace(
        previousState: SyllableState?,
        currentState: SyllableState
    ) -> BackspaceProcessResult {
        // 현재 상태가 비어있으면 동작하지 않음
        if currentState.isEmpty {
            return BackspaceProcessResult(previousState: previousState, currentState: currentState)
        }

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

    // MARK: - Private 메서드

    /// '종성부용초성' 동작이 가능한지 확인
    private func tryStandaloneCluster(
        currentState: SyllableState,
        inputKey: VirtualKey
    ) -> Bool? {
        guard let choseong = currentState.choseongState else { return nil }

        // 초성 조합을 먼저 시도
        if let newChoseong = choseongAutomaton.transition(
            currentState: choseong,
            inputKey: inputKey.keyIdentifier
        ) {
            currentState.addJamo(position: .choseong, state: newChoseong)
            return true
        }

        // 종성으로 시도
        if let jongseong = jongseongAutomaton.transition(
            currentState: choseong,
            inputKey: inputKey.keyIdentifier
        ) {
            // 종성으로 재해석
            currentState.jongseongState = jongseong
            currentState.choseongState = nil
            currentState.compositionOrder = [.jongseong]
            return true
        }

        return nil
    }

    /// 현재 음절에 낱자를 추가할 수 있는지 확인
    private func tryAddToCurrentSyllable(
        currentState: SyllableState,
        inputKey: VirtualKey
    ) -> Bool {
        let allowedPositions = getAllowedPositions(for: currentState)

        for position in allowedPositions {
            guard let automaton = automatonMap[position] else { continue }

            let currentJamo = currentState.getJamoState(for: position)
            if let newState = automaton.transition(
                currentState: currentJamo,
                inputKey: inputKey.keyIdentifier
            ) {
                currentState.addJamo(position: position, state: newState)
                return true
            }
        }

        return false
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

    /// 도깨비불 조합을 시도
    private func tryDokkaebi(
        currentState: SyllableState,
        inputKey: VirtualKey
    ) -> ProcessResult? {
        guard let dokkaebi = dokkaebiAutomaton,
              let jongseong = currentState.jongseongState,
              jungseongAutomaton.transition(currentState: nil, inputKey: inputKey.keyIdentifier) != nil,
              currentState.compositionOrder.isEmpty || currentState.compositionOrder.last == .jongseong
        else { return nil }

        let result = dokkaebi.process(jongseong)
        guard result.shouldSplit else { return nil }

        // 이전 음절의 종성 정보를 업데이트
        let updatedPrevious = currentState.copy()
        updatedPrevious.jongseongState = result.remainingJongseongState
        if result.remainingJongseongState == nil,
           let lastIdx = updatedPrevious.compositionOrder.lastIndex(of: .jongseong) {
            updatedPrevious.compositionOrder.remove(at: lastIdx)
        }

        // 이전 음절에서 분리된 종성을 새로운 음절의 초성으로 이동
        let newCurrent = SyllableState()
        newCurrent.choseongState = result.movedChoseongState
        newCurrent.compositionOrder.append(.choseong)

        // 위 음절에 입력된 중성 낱자를 추가
        if let jungseong = jungseongAutomaton.transition(
            currentState: nil,
            inputKey: inputKey.keyIdentifier
        ) {
            newCurrent.jungseongState = jungseong
            newCurrent.compositionOrder.append(.jungseong)
        }

        return ProcessResult(
            previousState: updatedPrevious,
            currentState: newCurrent,
            cursorMovement: 1
        )
    }

    private func createNewSyllableWithInput(inputKey: VirtualKey) -> SyllableState {
        let newState = SyllableState()

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

        return newState
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
        // - 종성부용초성 모드가 켜져 있을 경우
        // - 음절에 다른 낱자가 없고, 종성이 초성에도 쓰일 수 있으면 종성을 초성으로 이동
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
}
