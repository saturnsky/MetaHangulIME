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
    public let commitUnit: CommitUnit
    public let displayMode: DisplayMode
    public let supportStandaloneCluster: Bool
    
    public init(orderMode: OrderMode = .sequential,
                commitUnit: CommitUnit = .syllable,
                displayMode: DisplayMode = .modernMultiple,
                supportStandaloneCluster: Bool = false) {
        self.orderMode = orderMode
        self.commitUnit = commitUnit
        self.displayMode = displayMode
        self.supportStandaloneCluster = supportStandaloneCluster
    }
}

/// 입력 처리 결과
/// 주의: previousState는 변환 전의 상태를 뜻하는 것이 아니라, 이전 음절의 상태를 뜻함
public struct ProcessResult {
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
    
    // 성능 최적화: 오토마타 조회 캐시
    private lazy var automatonMap: [JamoPosition: Automaton] = [
        .choseong: choseongAutomaton,
        .jungseong: jungseongAutomaton,
        .jongseong: jongseongAutomaton
    ]
    
    public init(choseongAutomaton: ChoseongAutomaton,
                jungseongAutomaton: JungseongAutomaton,
                jongseongAutomaton: JongseongAutomaton,
                nonJamoAutomaton: NonJamoAutomaton? = nil,
                dokkaebiAutomaton: DokkaebiAutomaton? = nil,
                backspaceAutomaton: BackspaceAutomaton? = nil,
                config: InputProcessorConfig = InputProcessorConfig()) {
        self.choseongAutomaton = choseongAutomaton
        self.jungseongAutomaton = jungseongAutomaton
        self.jongseongAutomaton = jongseongAutomaton
        self.nonJamoAutomaton = nonJamoAutomaton
        self.dokkaebiAutomaton = dokkaebiAutomaton
        self.backspaceAutomaton = backspaceAutomaton
        self.config = config
    }
    
    /// 입력 키 처리
    public func process(previousState: SyllableState?,
                       currentState: SyllableState,
                       inputKey: VirtualKey) -> ProcessResult {
        // 자모가 아닌 문자 처리. 자모가 아닌 문자는 한글과 조합되지 않으며, NonJamo 오토마타를 사용
        if inputKey.isNonJamo {
            return handleSpecialCharacter(
                previousState: previousState,
                currentState: currentState,
                inputKey: inputKey
            )
        }
        
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
    /// - 이전 상태와 현재 상태를 받아 백스페이스 후의 상태를 반환
    /// - 이전 상태는 '역 도깨비불' 현상을 처리하기 위해 사용
    public func processBackspace(previousState: SyllableState?,
                                currentState: SyllableState) -> BackspaceProcessResult {
        // 현재 상태가 비어있으면 동작하지 않음
        // 이전 상태가 존재하는 경우, processBackspace를 호출하기 전에 시프트 되어야 함
        if currentState.isEmpty {
            return BackspaceProcessResult(previousState: previousState, currentState: currentState)
        }
        
        // 이전 상태를 보존하면서 현재 상태를 처리
        let result = processBackspaceOnState(currentState)
        
        // 역 도깨비불 확인
        if config.commitUnit == .explicitCommit,
           let reverseResult = tryReverseDokkaebi(
               previousState: previousState,
               currentState: result.currentState
           ) {
            return reverseResult
        }
        
        // 보존된 이전 상태와 함께 반환
        return BackspaceProcessResult(previousState: previousState, currentState: result.currentState)
    }
    
    /// 현재 상태의 표시 문자열 생성
    /// - archaic 모드: 현대 한글로 조합되면 현대 한글로. 아니면 NFD로 표시
    /// - modernMultiple 모드: 조합할 수 없는 자모를 별도 음절로 풀어서 표시
    /// - modernPartial 모드: 첫 음절에서 표시 가능한 부분까지만 표시
    public func buildDisplay(_ state: SyllableState) -> String {
        if let specialChar = state.specialCharacterState {
            return nonJamoAutomaton?.display(specialChar) ?? ""
        }
        
        switch config.displayMode {
        case .archaic:
            return buildArchaicDisplay(state)
        case .modernMultiple:
            return buildMultipleSyllables(state)
        case .modernPartial:
            return buildPartialDisplay(state)
        }
    }
    
    // MARK: - Private 메서드
    
    // 특수문자(비한글 문자)의 경우, 특수문자 오토마타를 사용하여 처리
    // 특수문자 오토마타의 경우 previousState는 의미가 없고, 인터페이스 통일을 위해 존재함
    private func handleSpecialCharacter(previousState: SyllableState?,
                                      currentState: SyllableState,
                                      inputKey: VirtualKey) -> ProcessResult {
        // transition이 존재하는 경우, 현재 상태를 업데이트
        if let specialAutomaton = nonJamoAutomaton,
           let currentSpecial = currentState.specialCharacterState {
            if let newSpecial = specialAutomaton.transition(
                currentState: currentSpecial,
                inputKey: inputKey.keyIdentifier
            ) {
                currentState.specialCharacterState = newSpecial
                return ProcessResult(
                    previousState: previousState,
                    currentState: currentState,
                    cursorMovement: 0
                )
            }
        }
        
        // 조합이 없을 경우, 새 음절을 생성
        let newState = SyllableState()
        if let specialAutomaton = nonJamoAutomaton,
           let newSpecial = specialAutomaton.transition(
               currentState: nil,
               inputKey: inputKey.keyIdentifier
           ) {
            newState.specialCharacterState = newSpecial
        }
        
        // 커서 이동: 새 음절이 생성된 경우, 커서가 새 음절로 이동
        let cursor = currentState.isEmpty ? 0 : 1
        let prev = currentState.isEmpty ? previousState : currentState
        
        return ProcessResult(
            previousState: prev,
            currentState: newState,
            cursorMovement: cursor
        )
    }
    
    /// '종성부용초성' 동작이 가능한지 확인
    /// - 현재 상태에 초성이 존재하고, 입력된 키로 초성 조합이 가능한 경우, 초성 조합을 진행함
    /// - 초성 조합이 불가능하고, 종성 조합이 가능한 경우, 초성을 종성으로 옮긴 뒤 종성 조합을 진행함
    private func tryStandaloneCluster(currentState: SyllableState,
                                    inputKey: VirtualKey) -> Bool? {
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
    /// - 정의된 오토마타로 transition이 가능하면 낱자를 추가 가능한 상태
    private func tryAddToCurrentSyllable(currentState: SyllableState,
                                       inputKey: VirtualKey) -> Bool {
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
    /// - orderMode가 sequential인 경우: 초성, 중성, 종성 순서로 추가 가능
    /// - orderMode가 freeOrder인 경우: 현재 상태에 따라 가능한 모든 위치를 반환
    /// 주의: 반환 순서는 오토마타의 탐색 순서와 동일하니, 그 점을 고려해야 함
    private func getAllowedPositions(for state: SyllableState) -> [JamoPosition] {
        switch config.orderMode {
        case .sequential:
            return getSequentialAllowedPositions(for: state)
        case .freeOrder:
            return getFreeOrderAllowedPositions(for: state)
        }
    }
    
    /// 순차적 조합 모드에서 현재 상태에 따라 추가 가능한 위치를 반환
    /// - 초성만 존재: 초성, 중성 추가 가능
    /// - 초성, 중성 존재: 중성, 종성 추가 가능
    /// - 초성, 중성, 종성 모두 존재: 종성만 추가 가능
    /// - 비어있는 상태: 초성, 중성, 종성 모두 추가 가능
    /// - 중성만 존재: 추가 중성 조합 허용
    /// - 종성만 존재: 추가 종성 조합 허용
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
    /// - 마지막으로 추가된 위치를 먼저 확인하고, 다른 빈 위치를 이후에 확인
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
    /// - 도깨비불: 현재 음절에 종성이 존재하고, 입력된 글자가 중성일 경우, 종성이 다음 음절로 이동하는 현상
    /// - 도깨비 오토마타에 따라 종성 상태를 남을 낱자와 다음 음절로 이동할 낱자로 분리
    /// - 도깨비 오토마타에 정의되지 않은 경우는 종성이 이동할 수 없는 것으로 간주
    private func tryDokkaebi(currentState: SyllableState,
                           inputKey: VirtualKey) -> ProcessResult? {
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
    /// - 조합 순서에서 마지막으로 입력된 낱자를 찾아, 해당 낱자에 백스페이스 오토마타를 적용
    /// - 백스페이스 오토마타가 없다면, 해당 낱자를 제거하고 조합 순서에서 삭제
    /// - 종성부용초성 모드가 켜져 있을 경우, 종성부용초성 되돌리기를 진행
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
    /// - 이전 상태와 현재 상태를 받아, 역 도깨비불이 가능한 경우, 역 도깨비불을 진행
    /// - 역 도깨비불은 백스페이스 처리 후의 음절에 초성만이 존재하고,
    /// - 이전 상태의 종성이 현재 상태의 초성과 결합 가능한 경우,
    ///  종성을 결합하여 이전 상태를 업데이트하고, 현재 상태를 nil로 반환
    private func tryReverseDokkaebi(previousState: SyllableState?,
                                  currentState: SyllableState) -> BackspaceProcessResult? {

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
        guard state.hasHangul else { return "" }
        
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
        guard state.hasHangul else { return "" }
        
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