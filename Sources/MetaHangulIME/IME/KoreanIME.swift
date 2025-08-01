//
//  KoreanIME.swift
//  MetaHangulIME
//
//  메타 한글 프레임워크를 사용하는 모든 한국어 IME의 베이스 클래스
//

import Foundation

/// 커밋 이벤트 처리를 위한 delegate 프로토콜
public protocol KoreanIMEDelegate: AnyObject {
    /// 텍스트가 커밋되어야 할 때 호출됨
    /// - Parameter text: 커밋할 텍스트
    func koreanIME(_ ime: KoreanIME, didCommitText text: String)
    
    /// IME 내부에서 처리할 수 없는 백스페이스 요청
    /// 호스트 애플리케이션에서 직접 백스페이스를 처리해야 할 때 호출됨
    /// - Parameter ime: 요청하는 IME 인스턴스
    func koreanIME(_ ime: KoreanIME, requestBackspace: Void)
}

/// 메타 한글 프레임워크를 사용하는 한국어 IME의 추상 베이스 클래스
///
/// 이 클래스는 한국어 입력 메서드의 핵심 기능을 제공합니다:
/// - 문자 입력 처리
/// - 백스페이스 처리
/// - 상태 관리 (이전/현재 음절)
/// - 커밋 처리 (SYLLABLE vs EXPLICIT_COMMIT 모드)
///
/// 중요: Swift 라이브러리에서의 커밋 처리
/// ========================================
/// 이 Swift 라이브러리는 delegate 패턴을 사용하여 호스트 애플리케이션에
/// 텍스트가 커밋되어야 할 때를 알립니다. 이는 적절한 IME 통합을 위해 필수적입니다:
///
/// - 라이브러리는 커밋된 텍스트를 내부적으로 저장하지 않습니다
/// - 텍스트가 커밋되어야 할 때, delegate의 didCommitText 메서드를 호출합니다
/// - 호스트 애플리케이션(IME, 텍스트 편집기 등)은 다음을 담당합니다:
///   1. delegate를 통해 커밋된 텍스트 수신
///   2. 적절한 텍스트 버퍼에 삽입
///   3. 커밋된 텍스트 상태 관리
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
            guard !uncommittedSyllables.isEmpty else { return SyllableState() }
            return uncommittedSyllables.last!
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
    
    /// 키 입력을 처리하고 현재 조합 중인 텍스트를 반환
    /// - Parameter key: 입력 키 문자열
    /// - Returns: 현재 조합 중인 텍스트 (커밋되지 않음)
    /// - Note: 텍스트가 커밋되어야 하는 경우 delegate가 호출됩니다
    public func input(_ key: String) -> String {
        // 가상 키 찾기
        guard let virtualKey = layout[key] else {
            // 알 수 없는 키 - 키 입력을 무시하고, 디버그용 경고 메시지를 출력
            print("Warning: Unknown key '\(key)'")
            
            return getComposingText()
        }
        
        // 입력 처리
        let result = processor.process(
            previousState: previousState,
            currentState: currentState,
            inputKey: virtualKey
        )
        
        // 특수문자가 입력되고 한글이 있는 경우, 먼저 커밋
        // 특수문자만 있는 것이 아닌 실제 한글 텍스트가 있는 경우에만 커밋
        let hasHangulText = (previousState?.hasHangul ?? false) || currentState.hasHangul
        if virtualKey.isNonKorean && hasHangulText {
            // 특수문자 처리 전에 현재 조합 커밋
            performCommitAll()
            
            // 빈 상태에서 특수문자를 다시 처리
            let specialResult = processor.process(
                previousState: previousState,
                currentState: currentState,
                inputKey: virtualKey
            )

            if specialResult.cursorMovement > 0 {
                handleCursorMovement(result: specialResult)
            } else {
                updateStatesFromResult(specialResult)
            }            
        } else {
            // 커밋 단위에 따라 상태 업데이트 처리
            if result.cursorMovement > 0 {
                handleCursorMovement(result: result)
            } else {
                // 커서 이동 없음
                updateStatesFromResult(result)
            }
        }
        
        return getComposingText()
    }
    
    /// 백스페이스를 처리하고 현재 조합 중인 텍스트를 반환
    /// - Returns: 현재 조합 중인 텍스트 (커밋되지 않음)
    /// - Note: 백스페이스는 조합 중인 텍스트에만 영향을 주며, 커밋된 텍스트에는 영향을 주지 않습니다
    ///         내부에서 처리할 상태가 없을 경우 delegate를 통해 호스트에 백스페이스를 요청합니다
    public func backspace() -> String {
        // 내부에서 처리할 상태가 있는지 확인
        let hasInternalState = uncommittedSyllables.contains { !$0.isEmpty }
        
        if !hasInternalState {
            // 내부 상태가 없으면 delegate에게 백스페이스 요청
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
        
        return getComposingText()
    }
    
    /// 현재 조합 중인 텍스트 가져오기 (커밋되지 않은 것만)
    /// - Returns: 현재 조합 중인 텍스트
    /// - Note: 이미 커밋된 텍스트는 포함하지 않습니다
    public func getComposingText() -> String {
        var result = ""
        
        for syllable in uncommittedSyllables {
            if !syllable.isEmpty {
                result += processor.buildDisplay(syllable)
            }
        }
        
        return result
    }
    
    /// 모든 대기 중인 텍스트 강제 커밋
    /// - Returns: 커밋된 텍스트
    /// - Note: delegate의 didCommitText 메서드가 호출됩니다
    public func forceCommit() -> String {
        let textToCommit = getComposingText()
        
        if !textToCommit.isEmpty {
            performCommitAll()
        }
        
        return textToCommit
    }
    
    /// 조합 중인 텍스트가 있는지 확인
    /// - Returns: 커밋되지 않은 텍스트가 있으면 true
    public var hasComposingText: Bool {
        if processor.config.commitUnit == .explicitCommit {
            return uncommittedSyllables.contains { !$0.isEmpty }
        } else {
            if let prev = previousState, !prev.isEmpty {
                return true
            }
            return !currentState.isEmpty
        }
    }
    
    // MARK: - Private 메서드
    
    private func handleCursorMovement(result: ProcessResult) {
        let cursorMovement = result.cursorMovement
        
        switch processor.config.commitUnit {
        case .syllable:
            // 이전 상태 커밋
            if let prev = result.previousState, !prev.isEmpty {
                let text = processor.buildDisplay(prev)
                delegate?.koreanIME(self, didCommitText: text)
            }
            // SYLLABLE 모드에서는 이전 상태를 유지하지 않음
            uncommittedSyllables = [result.currentState]
            
        case .explicitCommit:
            // cursorMovement에 따라 배열 크기 조정
            if cursorMovement == 1 {
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
            } else {
                // cursorMovement == 0: 현재 위치에서 상태만 업데이트
                updateStatesFromResult(result)
            }
        }
    }
    
    /// 명시적 커밋 수행
    private func performCommitAll() {
        var textToCommit = ""
        
        // 모든 음절 수집 (빈 음절 제외)
        for syllable in uncommittedSyllables {
            if !syllable.isEmpty {
                textToCommit += processor.buildDisplay(syllable)
            }
        }

        // 상태 초기화
        uncommittedSyllables = [SyllableState()]

        // delegate를 통해 커밋
        if !textToCommit.isEmpty {
            delegate?.koreanIME(self, didCommitText: textToCommit)
        }
    }
    
    /// ProcessResult를 기반으로 상태 업데이트
    private func updateStatesFromResult(_ result: ProcessResult) {
        if processor.config.commitUnit == .explicitCommit {
            // EXPLICIT_COMMIT 모드: 기존 배열을 보존하면서 마지막 부분만 업데이트
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
            // SYLLABLE 모드: 기존 로직 유지
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
    }
    
    /// BackspaceProcessResult를 기반으로 상태 업데이트
    private func updateStatesFromBackspaceResult(_ result: BackspaceProcessResult) {
        if processor.config.commitUnit == .explicitCommit {
            // EXPLICIT_COMMIT 모드: 기존 배열의 앞부분을 보존하고 마지막 1-2개만 교체
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
            // SYLLABLE 모드: 기존 로직 유지
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
    }
}