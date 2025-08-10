//
//  NonJamoInputProcessor.swift
//  MetaHangulIME
//
//  비자모(Non-Jamo) 입력 처리 전용 프로세서
//

import Foundation

/// 비자모 입력 처리 전용 프로세서
public final class NonJamoInputProcessor {
    // 오토마타
    private let nonJamoAutomaton: NonJamoAutomaton?

    // 설정
    public let config: InputProcessorConfig

    public init(
        nonJamoAutomaton: NonJamoAutomaton? = nil,
        config: InputProcessorConfig
    ) {
        self.nonJamoAutomaton = nonJamoAutomaton
        self.config = config
    }

    /// Non-Jamo 입력 처리
    public func process(
        previousState: SyllableState?,
        currentState: SyllableState,
        inputKey: VirtualKey
    ) -> ProcessResult {
        let hasJamo = currentState.hasJamo

        if hasJamo {
            let newState = SyllableState()
            if let transitioned = nonJamoAutomaton?.transition(currentState: nil, inputKey: inputKey.keyIdentifier) {
                newState.specialCharacterState = transitioned
            } else {
                newState.specialCharacterState = inputKey.keyIdentifier
            }
            return ProcessResult(
                previousState: currentState,
                currentState: newState,
                cursorMovement: 1
            )
        }

        // 현재 상태에서 transition 시도
        let currentSpecial = currentState.specialCharacterState
        let newSpecialFromCurrent = nonJamoAutomaton?.transition(
            currentState: currentSpecial,
            inputKey: inputKey.keyIdentifier
        )

        // 빈 상태에서 transition 시도
        let newSpecialFromEmpty = nonJamoAutomaton?.transition(
            currentState: nil,
            inputKey: inputKey.keyIdentifier
        )

        // Case 1: 현재 상태에서 transition 성공
        if let newSpecial = newSpecialFromCurrent {
            currentState.specialCharacterState = newSpecial
            return ProcessResult(
                previousState: previousState,
                currentState: currentState,
                cursorMovement: 0
            )
        }

        // Case 2: 현재 상태에서 transition 실패, 빈 상태에서 transition 가능
        if let newSpecial = newSpecialFromEmpty {
            let newState = SyllableState(
                specialCharacterState: newSpecial
            )
            return ProcessResult(
                previousState: currentState,
                currentState: newState,
                cursorMovement: 1
            )
        }

        // Case 3: 오토마타가 없거나 어떤 transition도 불가능 (단순 문자 처리)
        // 현재 상태와 빈 상태 모두에서 transition이 불가능한 경우
        if currentSpecial == nil {
            // 빈 상태에서 입력된 경우
            currentState.specialCharacterState = inputKey.keyIdentifier
            return ProcessResult(
                previousState: previousState,
                currentState: currentState,
                cursorMovement: 0
            )
        } else {
            // 현재 상태에 입력된 경우
            let newState = SyllableState(
                specialCharacterState: inputKey.keyIdentifier
            )
            return ProcessResult(
                previousState: currentState,
                currentState: newState,
                cursorMovement: 1
            )
        }
    }

    /// Non-Jamo 상태에 대한 백스페이스 처리
    public func processBackspace(
        previousState: SyllableState?,
        currentState: SyllableState
    ) -> BackspaceProcessResult {
        // Non-Jamo 상태가 없으면 처리하지 않음
        guard currentState.specialCharacterState != nil else {
            return BackspaceProcessResult(previousState: previousState, currentState: currentState)
        }

        // Non-Jamo 상태 제거
        currentState.specialCharacterState = nil

        return BackspaceProcessResult(previousState: previousState, currentState: currentState)
    }

    // MARK: - Public 메서드

    /// 오토마타에서 추가 전이가 가능한지 확인
    public func canTransitionFurther(from state: String) -> Bool {
        guard let automaton = nonJamoAutomaton else {
            // 오토마타가 없으면 전이 불가능
            return false
        }
        // Automaton 클래스의 canTransition 메서드를 사용하여
        // 현재 상태에서 추가 전이가 가능한지 확인
        return automaton.canTransition(from: state)
    }
}
