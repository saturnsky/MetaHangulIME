//
//  KoreanIME.swift
//  MetaHangulIME
//
//  메타 한글 프레임워크를 사용하는 모든 한국어 IME의 베이스 클래스
//

import Foundation

/// 입력 결과 처리를 위한 delegate 프로토콜
public protocol KoreanIMEDelegate: AnyObject {
    /// 모든 입력 처리 후 결과를 전달할 때 호출됨
    /// - Parameters:
    ///   - text: 커밋된 텍스트 (빈 문자열일 수 있음)
    ///   - composingText: 현재 조합 중인 텍스트
    /// - Note: 이 메서드는 텍스트 커밋 여부와 관계없이 모든 입력에 대해 호출됩니다
    func koreanIME(_ ime: KoreanIME, didCommitText text: String, composingText: String)

    /// IME 내부에서 처리할 수 없는 백스페이스 요청
    /// 호스트 애플리케이션에서 직접 백스페이스를 처리해야 할 때 호출됨
    /// - Parameter ime: 요청하는 IME 인스턴스
    func koreanIME(_ ime: KoreanIME, requestBackspace: Void)
}

/// 현재 IME 상태 정보를 외부에 제공하기 위한 구조체
/// 외부 입력기에서 조건절 평가 등에 사용할 수 있음
public struct StateInfo {
    /// 초성이 존재하는지 여부
    public let hasChoseong: Bool
    /// 중성이 존재하는지 여부
    public let hasJungseong: Bool
    /// 종성이 존재하는지 여부
    public let hasJongseong: Bool
    /// 비자모 상태가 존재하는지 여부
    public let hasNonJamo: Bool
    /// 현재 초성 상태 값 (없으면 nil)
    public let choseongValue: String?
    /// 현재 중성 상태 값 (없으면 nil)
    public let jungseongValue: String?
    /// 현재 종성 상태 값 (없으면 nil)
    public let jongseongValue: String?
    /// 현재 비자모 상태 값 (없으면 nil)
    public let nonJamoValue: String?

    public init(
        hasChoseong: Bool,
        hasJungseong: Bool,
        hasJongseong: Bool,
        hasNonJamo: Bool,
        choseongValue: String?,
        jungseongValue: String?,
        jongseongValue: String?,
        nonJamoValue: String?
    ) {
        self.hasChoseong = hasChoseong
        self.hasJungseong = hasJungseong
        self.hasJongseong = hasJongseong
        self.hasNonJamo = hasNonJamo
        self.choseongValue = choseongValue
        self.jungseongValue = jungseongValue
        self.jongseongValue = jongseongValue
        self.nonJamoValue = nonJamoValue
    }
}

// swiftlint:disable type_body_length
/// 메타 한글 프레임워크를 사용하는 한국어 IME의 추상 베이스 클래스
///
/// 이 클래스는 한국어 입력 메서드의 핵심 기능을 제공합니다:
/// - 문자 입력 처리
/// - 백스페이스 처리
/// - 상태 관리 (이전/현재 음절)
/// - 커밋 처리 (커밋 정책에 따른 처리)
///
/// 중요: Swift 라이브러리에서의 입력 처리
/// ========================================
/// 이 Swift 라이브러리는 delegate 패턴을 사용하여 호스트 애플리케이션에
/// 모든 입력 처리 결과를 전달합니다. 이는 적절한 IME 통합을 위해 필수적입니다:
///
/// - 라이브러리는 커밋된 텍스트를 내부적으로 저장하지 않습니다
/// - 모든 입력 처리 후 delegate의 didCommitText 메서드를 호출합니다
/// - 호스트 애플리케이션(IME, 텍스트 편집기 등)은 다음을 담당합니다:
///   1. delegate를 통해 커밋된 텍스트와 조합 중인 텍스트 수신
///   2. 적절한 텍스트 버퍼 관리
///   3. 커밋된 텍스트와 조합 중인 텍스트 상태 관리
///
/// 이 설계는 다양한 플랫폼(iOS, macOS 등)에서 시스템 IME 프레임워크 및
/// 텍스트 입력 시스템과의 적절한 통합을 가능하게 합니다
open class KoreanIME {
    // MARK: - 속성

    /// 커밋 이벤트를 위한 delegate
    public weak var delegate: KoreanIMEDelegate?

    /// 핵심 로직을 처리하는 입력 프로세서
    public let processor: InputProcessor

    /// 키보드 레이아웃 매핑
    public let layout: [String: VirtualKey]

    /// 커밋되지 않은 음절들
    /// 이 배열이 모든 상태를 관리하는 단일 진실 소스입니다
    /// - lastIndex는 currentState에 해당
    /// - lastIndex - 1은 previousState에 해당 (존재하지 않으면 nil)
    private var uncommittedSyllables: [SyllableState]

    /// 이전 음절 상태 (도깨비불용) - computed property
    internal var previousState: SyllableState? {
        get {
            guard uncommittedSyllables.count >= 2 else { return nil }
            return uncommittedSyllables[uncommittedSyllables.count - 2]
        }
        set {
            if let newValue = newValue {
                // 이전 상태를 설정하는 경우
                if uncommittedSyllables.count >= 2 {
                    uncommittedSyllables[uncommittedSyllables.count - 2] = newValue
                } else if uncommittedSyllables.count == 1 {
                    // currentState가 있고 previousState를 설정하는 경우
                    uncommittedSyllables.insert(newValue, at: 0)
                } else {
                    // 둘 다 없는 경우, 빈 currentState와 함께 추가
                    uncommittedSyllables = [newValue, SyllableState()]
                }
            } else {
                // nil로 설정하는 경우 - previousState 제거
                if uncommittedSyllables.count >= 2 {
                    uncommittedSyllables.removeFirst(uncommittedSyllables.count - 1)
                }
            }
        }
    }

    /// 현재 조합 중인 음절 - computed property
    internal var currentState: SyllableState {
        get {
            uncommittedSyllables.last ?? SyllableState()
        }
        set {
            if uncommittedSyllables.isEmpty {
                uncommittedSyllables.append(newValue)
            } else {
                uncommittedSyllables[uncommittedSyllables.count - 1] = newValue
            }
        }
    }

    // MARK: - 초기화

    public init(processor: InputProcessor, layout: [String: VirtualKey]) {
        self.processor = processor
        self.layout = layout
        self.uncommittedSyllables = [SyllableState()] // 빈 currentState로 시작
    }

    // MARK: - Public 메서드

    /// IME 상태 초기화
    /// 참고: 이미 커밋된 텍스트에는 영향을 주지 않습니다.
    /// 커밋된 텍스트는 이 라이브러리가 아닌 호스트 애플리케이션에서 관리합니다
    public func reset() {
        uncommittedSyllables = [SyllableState()] // 빈 currentState로 초기화
    }

    /// 키 입력을 처리하고 현재 커밋 된 텍스트를 반환
    /// - Parameter key: 입력 키 문자열
    /// - Returns: 현재 커밋 된 텍스트
    /// - Note: 모든 입력에 대해 delegate가 호출되어 커밋된 텍스트와 조합 중인 텍스트를 전달합니다
    public func input(_ key: String) -> String {
        var committedText = ""

        // 가상 키 찾기
        guard let virtualKey = layout[key] else {
            // 알 수 없는 키 - 키 입력을 무시하고, 디버그용 경고 메시지를 출력
            print("Warning: Unknown key '\(key)'")
            let composingText = getComposingText()
            delegate?.koreanIME(self, didCommitText: "", composingText: composingText)
            return composingText
        }

        // 입력 처리
        let result = processor.process(
            previousState: previousState,
            currentState: currentState,
            inputKey: virtualKey
        )

        // 자동 커밋이 필요한 경우, 상태 업데이트 전에 커밋을 우선 진행
        if result.needAutoCommit {
            committedText = getComposingText()
            uncommittedSyllables = [result.currentState]
        }

        // 커밋 정책에 따라 상태 업데이트 처리
        if result.cursorMovement > 0 {
            committedText += handleCursorMovement(result: result)
        } else {
            // 커서 이동 없음 - 현재의 타입에 따라 적절한 update 함수 호출
            if !result.currentState.hasJamo {
                committedText += updateNonJamoStatesFromResult(result)
            } else {
                committedText += updateJamoStatesFromResult(result)
            }
        }

        let composingText = getComposingText()
        delegate?.koreanIME(self, didCommitText: committedText, composingText: composingText)
        return committedText
    }

    /// 백스페이스를 처리하고 현재 조합 중인 텍스트를 반환
    /// - Returns: 현재 조합 중인 텍스트
    /// - Note: 내부 상태가 있는 경우에만 delegate가 호출됩니다
    ///         내부에서 처리할 상태가 없을 경우 delegate를 통해 호스트에 백스페이스를 요청합니다
    public func backspace() -> String {
        // 내부에서 처리할 상태가 있는지 확인
        let hasInternalState = uncommittedSyllables.contains { !$0.isEmpty }

        if !hasInternalState {
            // 내부 상태가 없으면 delegate에게 백스페이스 요청만 하고 리턴
            delegate?.koreanIME(self, requestBackspace: ())
            return getComposingText()
        }

        // 백스페이스 처리
        let result = processor.processBackspace(
            previousState: previousState,
            currentState: currentState
        )

        // 상태 업데이트
        updateStatesFromBackspaceResult(result)

        // 백스페이스 처리 후 delegate 호출
        let composingText = getComposingText()
        delegate?.koreanIME(self, didCommitText: "", composingText: composingText)
        return composingText
    }

    /// 현재 조합 중인 텍스트 가져오기 (커밋되지 않은 것만)
    /// - Returns: 현재 조합 중인 텍스트
    /// - Note: 이미 커밋된 텍스트는 포함하지 않습니다
    public func getComposingText() -> String {
        var result = ""

        for syllable in uncommittedSyllables where !syllable.isEmpty {
            result += processor.buildDisplay(syllable)
        }

        return result
    }

    /// 모든 대기 중인 텍스트 강제 커밋
    /// - Returns: 커밋된 텍스트
    /// - Note: 텍스트가 있는 경우 delegate의 didCommitText 메서드가 호출됩니다
    public func forceCommit() -> String {
        if uncommittedSyllables.isEmpty {
            // 커밋할 텍스트가 없는 경우 빈 문자열 반환
            return ""
        }

        let textToCommit = getComposingText()
        uncommittedSyllables = []

        // delegate를 통해 커밋
        delegate?.koreanIME(self, didCommitText: textToCommit, composingText: "")
        // 커밋된 텍스트 반환
        return textToCommit
    }

    /// 조합 중인 텍스트가 있는지 확인
    /// - Returns: 커밋되지 않은 텍스트가 있으면 true
    public var hasComposingText: Bool {
        if processor.config.jamoCommitPolicy == .explicitCommit {
            return uncommittedSyllables.contains { !$0.isEmpty }
        } else {
            if let prev = previousState, !prev.isEmpty {
                return true
            }
            return !currentState.isEmpty
        }
    }

    /// 현재 상태 정보를 가져옴
    /// - Returns: 현재 조합 중인 음절의 상태 정보
    /// - Note: 이 메서드는 외부 입력기에서 조건절 평가 등에 사용할 수 있습니다
    public func getCurrentStateInfo() -> StateInfo {
        StateInfo(
            hasChoseong: currentState.choseongState != nil,
            hasJungseong: currentState.jungseongState != nil,
            hasJongseong: currentState.jongseongState != nil,
            hasNonJamo: currentState.nonJamoState != nil,
            choseongValue: currentState.choseongState,
            jungseongValue: currentState.jungseongState,
            jongseongValue: currentState.jongseongState,
            nonJamoValue: currentState.nonJamoState
        )
    }

    // MARK: - Private 메서드

    private func handleCursorMovement(result: ProcessResult) -> String {
        // 현재 입력이 Non-Jamo인지 확인 (현재 상태의 nonJamoState로 판단)
        // - 현재 상태에 nonJamoState가 있으면 Non-Jamo 입력
        // - 현재 상태에 jamo가 있으면 Jamo 입력
        let isCurrentInputNonJamo: Bool
        if result.currentState.nonJamoState != nil {
            isCurrentInputNonJamo = true
        } else if result.currentState.hasJamo {
            isCurrentInputNonJamo = false
        } else {
            // 빈 상태인 경우 이전 상태로 판단
            isCurrentInputNonJamo = result.previousState?.nonJamoState != nil
        }

        if isCurrentInputNonJamo {
            return handleNonJamoCursorMovement(result: result)
        } else {
            return handleJamoCursorMovement(result: result)
        }
    }

    /// Non-Jamo 입력에 대한 커서 이동 처리
    /// - Returns: 커밋된 텍스트
    private func handleNonJamoCursorMovement(result: ProcessResult) -> String {
        var committedText = ""

        switch processor.config.nonJamoCommitPolicy {
        case .character:
            // 이전 상태 커밋
            // 마지막 글자 한 글자 전까지만 커밋
            let syllablesToCommit = uncommittedSyllables.dropLast(1)
            for syllable in syllablesToCommit where !syllable.isEmpty {
                committedText += processor.buildDisplay(syllable)
            }
            if let previousState = result.previousState, !previousState.isEmpty {
                committedText += processor.buildDisplay(previousState)
            }
            uncommittedSyllables = [result.currentState]

        case .onComplete:
            // onComplete 모드: 오토마타 전이 완료 시 현재 상태도 커밋
            let syllablesToCommit = uncommittedSyllables.dropLast(1)
            for syllable in syllablesToCommit where !syllable.isEmpty {
                committedText += processor.buildDisplay(syllable)
            }
            if let previousState = result.previousState, !previousState.isEmpty {
                committedText += processor.buildDisplay(previousState)
            }
            if !processor.canTransitionFurtherForNonJamo(from: result.currentState.nonJamoState ?? "") {
                // Non-Jamo 오토마타에서 추가 전이가 불가능한 경우
                committedText += processor.buildDisplay(result.currentState)
                uncommittedSyllables = [] // 커밋 후 상태 초기화
            } else {
                // 전이가 가능한 경우 현재 상태를 uncommittedSyllables에 유지
                uncommittedSyllables = [result.currentState]
            }

        case .explicitCommit:
            // explicitCommit 모드: 수동 커밋
            var newSyllables = uncommittedSyllables
            if let prevState = result.previousState {
                if newSyllables.isEmpty {
                    newSyllables = [prevState]
                } else {
                    newSyllables[newSyllables.count - 1] = prevState
                }
            }
            newSyllables.append(result.currentState)
            uncommittedSyllables = newSyllables
        }

        return committedText
    }

    /// Jamo 입력에 대한 커서 이동 처리 (cursorMovement > 0인 경우)
    /// - Returns: 커밋된 텍스트
    private func handleJamoCursorMovement(result: ProcessResult) -> String {
        var committedText = ""

        switch processor.config.jamoCommitPolicy {
        case .syllable:
            // 이전 상태 커밋
            let syllablesToCommit = uncommittedSyllables.dropLast(1)
            for syllable in syllablesToCommit where !syllable.isEmpty {
                committedText += processor.buildDisplay(syllable)
            }
            if let previousState = result.previousState, !previousState.isEmpty {
                committedText += processor.buildDisplay(previousState)
            }
            uncommittedSyllables = [result.currentState]

        case .explicitCommit:
            // 새 음절로 이동: 기존 배열 크기 + 1
            var newSyllables = uncommittedSyllables

            // result의 previousState가 있다면 현재 currentState 자리에 설정
            // 없다면 기존 currentState를 그대로 유지
            if let prevState = result.previousState {
                if newSyllables.isEmpty {
                    newSyllables = [prevState]
                } else {
                    newSyllables[newSyllables.count - 1] = prevState
                }
            }
            // else: result.previousState가 nil이면 기존 currentState 유지

            // result의 currentState를 새로운 음절로 추가
            newSyllables.append(result.currentState)

            uncommittedSyllables = newSyllables
        }

        return committedText
    }

    /// ProcessResult를 기반으로 Jamo 상태 업데이트
    /// - Returns: 커밋된 텍스트 (빈 문자열)
    private func updateJamoStatesFromResult(_ result: ProcessResult) -> String {
        if processor.config.jamoCommitPolicy == .explicitCommit {
            // explicitCommit 모드: 기존 배열을 보존하면서 마지막 부분만 업데이트
            var newSyllables = uncommittedSyllables

            // previousState와 currentState에 따라 마지막 1-2개 음절 조정
            if let prevState = result.previousState {
                if result.currentState.isEmpty {
                    // previousState만 있는 경우: 마지막 음절을 previousState로 교체
                    if newSyllables.isEmpty {
                        newSyllables = [prevState]
                    } else {
                        newSyllables[newSyllables.count - 1] = prevState
                    }
                } else {
                    // 둘 다 있는 경우: 마지막 2음절을 교체
                    if newSyllables.count >= 2 {
                        newSyllables[newSyllables.count - 2] = prevState
                        newSyllables[newSyllables.count - 1] = result.currentState
                    } else if newSyllables.count == 1 {
                        newSyllables[0] = prevState
                        newSyllables.append(result.currentState)
                    } else {
                        newSyllables = [prevState, result.currentState]
                    }
                }
            } else {
                // currentState만 있는 경우: 마지막 음절을 currentState로 교체
                if newSyllables.isEmpty {
                    newSyllables = [result.currentState]
                } else {
                    newSyllables[newSyllables.count - 1] = result.currentState
                }
            }

            uncommittedSyllables = newSyllables
        } else {
            // syllable 모드
            if let prevState = result.previousState {
                if result.currentState.isEmpty {
                    uncommittedSyllables = [prevState]
                } else {
                    uncommittedSyllables = [prevState, result.currentState]
                }
            } else {
                uncommittedSyllables = [result.currentState]
            }
        }

        return "" // 커서 이동 없는 경우 커밋 없음
    }

    /// ProcessResult를 기반으로 Non-Jamo 상태 업데이트
    /// - Returns: 커밋된 텍스트
    private func updateNonJamoStatesFromResult(_ result: ProcessResult) -> String {
        if processor.config.nonJamoCommitPolicy == .explicitCommit {
            // explicitCommit 모드: 기존 배열을 보존하면서 새 음절 추가
            var newSyllables = uncommittedSyllables
            // cursorMovement가 1이면 새 음절 추가
            if result.cursorMovement == 1 {
                // previousState가 있다면 현재 위치에 설정
                if let prevState = result.previousState {
                    if newSyllables.isEmpty {
                        newSyllables = [prevState]
                    } else {
                        newSyllables[newSyllables.count - 1] = prevState
                    }
                }
                // 새 음절 추가
                newSyllables.append(result.currentState)
            } else {
                // cursorMovement가 0이면 현재 위치 업데이트
                if newSyllables.isEmpty {
                    newSyllables = [result.currentState]
                } else {
                    newSyllables[newSyllables.count - 1] = result.currentState
                }
            }

            uncommittedSyllables = newSyllables
        } else {
            // character/onComplete 모드: 기존 로직 유지
            if result.currentState.isEmpty {
                uncommittedSyllables = []
            } else {
                uncommittedSyllables = [result.currentState]
            }
            if processor.config.nonJamoCommitPolicy == .onComplete && !uncommittedSyllables.isEmpty {
                // nonJamoAutomaton.canTransitionFurther 를 통해 last에서 다음 전이가 가능한지 확인
                // nonJamoAutomaton이 없을 경우 항상 전이가 불가능한 것으로 간주
                // 다음 전이가 불가능할 경우 마지막 글자를 커밋하고, uncommittedSyllables를 비움
                if let lastSyllable = uncommittedSyllables.last,
                   let nonJamoState = lastSyllable.nonJamoState {
                    // NonJamo 오토마타에서 현재 상태로부터 추가 전이가 가능한지 확인
                    let canTransition = processor.canTransitionFurtherForNonJamo(from: nonJamoState)
                    if !canTransition {
                        // 전이가 불가능하면 마지막 음절을 커밋
                        if let lastToCommit = uncommittedSyllables.last {
                            let displayText = processor.buildDisplay(lastToCommit)
                            uncommittedSyllables = []
                            return displayText
                        }
                    }
                }
            }
        }

        return "" // 커밋 없음
    }

    /// BackspaceProcessResult를 기반으로 상태 업데이트
    private func updateStatesFromBackspaceResult(_ result: BackspaceProcessResult) {
        if processor.config.jamoCommitPolicy == .explicitCommit {
            // explicitCommit 모드: 기존 배열의 앞부분을 보존하고 마지막 1-2개만 교체
            let baseCount = uncommittedSyllables.count >= 2 ? uncommittedSyllables.count - 2 : 0
            var newSyllables = Array(uncommittedSyllables.prefix(baseCount))

            // 백스페이스 결과에 따라 마지막 1-2개 음절 추가
            if let prevState = result.previousState {
                if result.currentState.isEmpty {
                    // previousState만 추가
                    newSyllables.append(prevState)
                } else {
                    // 둘 다 추가
                    newSyllables.append(prevState)
                    newSyllables.append(result.currentState)
                }
            } else {
                if !result.currentState.isEmpty {
                    // currentState만 추가
                    newSyllables.append(result.currentState)
                }
                // 둘 다 비어있으면 아무것도 추가하지 않음 (음절 삭제)
            }

            // 최소한 빈 음절 하나는 유지
            if newSyllables.isEmpty {
                newSyllables = [SyllableState()]
            }

            uncommittedSyllables = newSyllables
        } else {
            // syllable 모드: 기존 로직 유지
            if result.currentState.isEmpty {
                uncommittedSyllables = []
            } else {
                uncommittedSyllables = [result.currentState]
            }
        }
    }
}
// swiftlint:enable type_body_length
