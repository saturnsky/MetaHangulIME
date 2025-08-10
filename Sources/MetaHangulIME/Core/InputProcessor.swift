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
    // 자모 및 비자모 프로세서
    private let jamoProcessor: JamoInputProcessor
    private let nonJamoProcessor: NonJamoInputProcessor

    // 설정
    public let config: InputProcessorConfig

    // Display 빌더
    private let displayBuilder: DisplayBuilder

    public init(
        choseongAutomaton: ChoseongAutomaton,
        jungseongAutomaton: JungseongAutomaton,
        jongseongAutomaton: JongseongAutomaton,
        nonJamoAutomaton: NonJamoAutomaton? = nil,
        dokkaebiAutomaton: DokkaebiAutomaton? = nil,
        backspaceAutomaton: BackspaceAutomaton? = nil,
        config: InputProcessorConfig = InputProcessorConfig()
    ) {
        self.config = config

        // DisplayBuilder 초기화
        self.displayBuilder = DisplayBuilder(
            choseongAutomaton: choseongAutomaton,
            jungseongAutomaton: jungseongAutomaton,
            jongseongAutomaton: jongseongAutomaton,
            nonJamoAutomaton: nonJamoAutomaton,
            displayMode: config.displayMode
        )

        // JamoInputProcessor 초기화
        self.jamoProcessor = JamoInputProcessor(
            choseongAutomaton: choseongAutomaton,
            jungseongAutomaton: jungseongAutomaton,
            jongseongAutomaton: jongseongAutomaton,
            dokkaebiAutomaton: dokkaebiAutomaton,
            backspaceAutomaton: backspaceAutomaton,
            config: config,
            displayBuilder: displayBuilder
        )

        // NonJamoInputProcessor 초기화
        self.nonJamoProcessor = NonJamoInputProcessor(
            nonJamoAutomaton: nonJamoAutomaton,
            config: config
        )
    }

    /// 입력 키 처리
    public func process(
        previousState: SyllableState?,
        currentState: SyllableState,
        inputKey: VirtualKey
    ) -> ProcessResult {
        // 자모가 아닌 문자 처리. 자모가 아닌 문자는 한글과 조합되지 않으며, NonJamo 오토마타를 사용
        if inputKey.isNonJamo {
            return nonJamoProcessor.process(
                previousState: previousState,
                currentState: currentState,
                inputKey: inputKey
            )
        } else {
            // 자모 입력 처리
            return jamoProcessor.process(
                previousState: previousState,
                currentState: currentState,
                inputKey: inputKey
            )
        }
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

        // Non-Jamo 상태가 있으면 NonJamoProcessor로 처리
        if currentState.nonJamoState != nil {
            return nonJamoProcessor.processBackspace(
                previousState: previousState,
                currentState: currentState
            )
        }

        // Jamo 상태 처리
        return jamoProcessor.processBackspace(
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
        nonJamoProcessor.canTransitionFurther(from: state)
    }

    // MARK: - Private 메서드
}
