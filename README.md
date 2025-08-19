# Meta Hangul IME for Swift

> ⚠️ **Experimental Stage**: 이 프로젝트는 현재 실험적 단계에 있습니다. 버전 업데이트 시 설정 파일 형식, API, 동작 방식 등이 변경될 수 있으며, 이전 버전과의 호환성이 보장되지 않을 수 있습니다.

Meta Hangul IME는 다양한 한글 입력 방식을 통합 지원하는 범용 프레임워크입니다. 키보드 기반 한글 입력기의 다양한 입력 방식과 규칙을 추상화하여, 하나의 엔진으로 여러 입력기를 구현할 수 있도록 설계되었습니다.

## 주요 특징

- ✨ **통합 프레임워크**: 두벌식, 세벌식, 천지인 등 다양한 입력 방식을 하나의 엔진으로 지원
- 🎯 **핵심 규칙**: 조합 순서, 종성부용초성, 커밋 정책, 표시 방식을 독립적으로 설정
- 📝 **YAML 기반 설정**: 코드 수정 없이 YAML 파일로 새로운 입력기 정의 가능
- 🚀 **Swift 네이티브**: 순수 Swift로 구현되어 iOS/macOS에서 최적의 성능 제공

## 설치

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/saturnsky/MetaHangulIME.git", from: "1.0.0")
]
```

## 빠른 시작

### 기본 사용법

```swift
import MetaHangulIME

// 표준 두벌식 IME 생성
let ime = StandardDubeolsik()

// delegate 설정
ime.delegate = self

// 입력 처리
_ = ime.input("d")  // ㅇ
_ = ime.input("k")  // 아
_ = ime.input("s")  // 안

// 커밋된 텍스트는 delegate를 통해 전달됨
```

### 입력 메서드

```swift
// 키 입력 - 모든 입력에 대해 delegate가 호출됨
let result = ime.input("k")  // 현재 조합 중인 문자열 반환
// 입력값은 layout에 정의된 키값 (identifier가 아님에 유의)

// 백스페이스 - 내부 상태 변화 시만 delegate 호출
let deleted = ime.backspace()  // 삭제 후 남은 문자열 반환

// 강제 커밋
let committed = ime.forceCommit()  // 현재 조합 중인 문자를 커밋

// 현재 조합 중인 텍스트 확인
let composing = ime.getComposingText()

// IME 초기화
ime.reset()
```

### Delegate 구현

```swift
extension MyViewController: KoreanIMEDelegate {
    func koreanIME(_ ime: KoreanIME, didCommitText text: String, composingText: String) {
        // 모든 입력 처리 후 호출됨
        // text: 커밋된 텍스트 (빈 문자열일 수 있음)
        // composingText: 현재 조합 중인 텍스트
        
        if !text.isEmpty {
            // 커밋된 텍스트 처리
            textField.insertText(text)
        }
        
        // 조합 중인 텍스트 표시
        displayComposingText(composingText)
    }
    
    func koreanIME(_ ime: KoreanIME, requestBackspace: Void) {
        // IME 내부에 처리할 상태가 없을 때 호출
        textField.deleteBackward()
    }
}
```

### 전체 예제

```swift
class ViewController: UIViewController {
    @IBOutlet weak var textField: UITextField!
    let ime = StandardDubeolsik()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ime.delegate = self
    }
    
    // 키보드 입력 처리
    func handleKeyPress(_ key: String) {
        if key == "⌫" {  // 백스페이스
            _ = ime.backspace()
        } else if key == "⏎" {  // 엔터
            _ = ime.forceCommit()
        } else {
            _ = ime.input(key)
        }
        
        // 현재 조합 중인 텍스트 표시
        updateComposingText()
    }
    
    func updateComposingText() {
        let composingText = ime.getComposingText()
        // 조합 중인 텍스트 표시 로직
    }
}

extension ViewController: KoreanIMEDelegate {
    func koreanIME(_ ime: KoreanIME, didCommitText text: String, composingText: String) {
        // 커밋된 텍스트를 텍스트 필드에 추가
        if !text.isEmpty {
            textField.text = (textField.text ?? "") + text
        }
        
        // 조합 중인 텍스트 표시 (예: 커서 위치에 표시)
        showComposingTextAtCursor(composingText)
    }
    
    func koreanIME(_ ime: KoreanIME, requestBackspace: Void) {
        // IME가 처리할 수 없는 백스페이스 요청
        // (예: 조합 중인 문자가 없을 때)
        guard let text = textField.text, !text.isEmpty else { return }
        textField.text = String(text.dropLast())
    }
}
```

## 핵심 설계 원칙

### 1. 조합 순서 (Composition Order)

메타 한글 입력기는 두 가지 조합 모드를 지원합니다:

#### 순차적 조합 모드 (Sequential Mode)
- **규칙**: 초성 → 중성 → 종성 순서만 허용
- **특징**: 역순 입력 불가 (중성 후 초성 추가 불가)
- **예시**: 대부분의 전통적 입력기 (두벌식, 천지인플러스 등)

#### 자유 조합 모드 (Free Order Mode)
- **규칙**: 초성, 중성, 종성을 임의의 순서로 입력 가능
- **제약**: 동일 위치에 대한 분할 조합은 불가
- **예시**: 세벌식 (모아치기 지원)

### 2. 종성부용초성 (Standalone Cluster)

종성에만 존재할 수 있는 자음 조합(겹받침)의 처리 방식을 정의합니다.

#### 종성부용초성 허용 모드
- **동작**: 단독 겹받침 입력 허용 (예: ㄳ, ㄵ 등)
- **예시**: ㄱ (초성) + ㅅ (초성) → ㄳ (종성으로 재해석)

### 3. 커밋 정책 (Commit Policy)

#### 한글 자모 커밋 정책 (JamoCommitPolicy)
- **음절 단위 (syllable)**: 음절 단위로 조합 관리 및 삭제, 도깨비불 현상 이후에도 음절 단위 삭제
- **명시적 커밋 (explicitCommit)**: 명시적 커밋 전까지 낱자 단위로 세밀한 조합 관리, 역 도깨비불 현상 지원

#### 비자모 문자 커밋 정책 (NonJamoCommitPolicy)
- **문자 단위 (character)**: 다음 문자로 넘어갈 때 자동 커밋
- **명시적 커밋 (explicitCommit)**: 수동 커밋 필요
- **완료 시 (onComplete)**: 오토마타 전이 완료 시 자동 커밋

#### 전환 커밋 정책 (TransitionCommitPolicy)
- **항상 커밋 (always)**: 한글↔비한글 전환 시 항상 커밋
- **커밋 안 함 (never)**: 전환 시 커밋하지 않음

### 4. 표시 규칙 (Display Mode)

#### 옛한글 지원 모드
- **규칙**: NFD(Normalization Form D) 사용
- **표시**: 현대 한글로 조합되지 않는 글자도 조합 형태로 표시

#### 현대 한글 전용 모드
- **다중 음절 표시**: 조합 불가능한 요소를 별개 음절로 표시
- **부분 표시**: 표시 가능한 부분만 조합하여 표시

## 아키텍처

### 핵심 구성 요소

```swift
// 가상 키 표현
public struct VirtualKey {
    public let keyIdentifier: String    // 내부 처리용 식별자
    public let label?: String           // 표시용 레이블
}

// 음절 상태 관리
public class SyllableState {
    var choseongState: String?     // 현재 초성 상태
    var jungseongState: String?    // 현재 중성 상태
    var jongseongState: String?    // 현재 종성 상태
    var compositionOrder: [JamoPosition]  // 조합 순서
}

// 입력 처리 설정
public struct InputProcessorConfig {
    public let orderMode: OrderMode
    public let commitUnit: CommitUnit
    public let displayMode: DisplayMode
    public let supportStandaloneCluster: Bool
}
```

### 오토마타 시스템

```swift
// 기본 오토마타 프로토콜
public protocol Automaton {
    func transition(currentState: String?, inputKey: String) -> String?
    func display(_ state: String) -> String
}

// 도깨비불 처리
public struct DokkaebiResult {
    public let shouldSplit: Bool
    public let remainingJongseongState: String?
    public let movedChoseongState: String?
}
```

## YAML 설정 구조

새로운 입력기는 YAML 파일로 정의할 수 있습니다:

```yaml
name: "천지인"
identifier: "cheonjiin"

# 입력기 설정
config:
  orderMode: "sequential"        # sequential | freeOrder
  commitUnit: "explicitCommit"   # syllable | explicitCommit
  displayMode: "modernMultiple"  # archaic | modernMultiple | modernPartial
  supportStandaloneCluster: true

# 키보드 레이아웃
layout:
  q: { identifier: "ㄱ", label: "ㄱ" }
  w: { identifier: "ㄴ", label: "ㄴ" }
  1: { identifier: "ㅣ", label: "ㅣ" }
  c: { identifier: ".,?!", label: ".,?!" }

# 오토마타 정의
automata:
  choseong:
    transitions:
      - { from: "", input: "ㄱ", to: "ㄱ" }
      - { from: "ㄱ", input: "ㄱ", to: "ㅋ" }
    display:
      "ㄱ": "\u1100"  # ᄀ
      "ㅋ": "\u110F"  # ᄏ

  jungseong:
    transitions:
      - { from: "", input: "ㅣ", to: "ㅣ" }
      - { from: "ㅣ", input: "ㆍ", to: "ㅏ" }
    display:
      "ㅣ": "\u1175"  # ᅵ
      "ㅏ": "\u1161"  # ᅡ

  jongseong:
    transitions:
      - { from: "", input: "ㄱ", to: "ㄱ" }
      - { from: "ㄱ", input: "ㅅ", to: "ㄳ" }
    display:
      "ㄱ": "\u11A8"  # ᆨ
      "ㄳ": "\u11AA"  # ᆪ

  dokkaebibul:
    transitions:
      - { jongseong: "ㄳ", remaining: "ㄱ", moved: "ㅅ" }
      - { jongseong: "ㄱ", remaining: null, moved: "ㄱ" }

  backspace:
    transitions:
      - { from: "ㄳ", to: "ㄱ" }
      - { from: "ㅏ", to: "ㅣ" }

  specialCharacter:
    transitions:
      - { from: "", input: ".,?!", to: "." }
      - { from: ".", input: ".,?!", to: "," }
    display:
      ".": "."
      ",": ","
```

## 제공되는 입력기

### 1. 표준 두벌식 (StandardDubeolsik)
- 가장 널리 사용되는 한글 입력 방식
- 자음과 모음이 분리된 2벌 자판
- 순차적 조합 모드, 음절 단위 커밋

### 2. 천지인 (CheonJiIn)
- 모바일 기기용 최소 키 입력 방식
- ㆍ, ㅡ, ㅣ 세 개의 모음으로 모든 모음 조합
- 명시적 커밋, 종성부용초성 지원

### 3. 천지인 플러스 (CheonJiIn Plus)
- 천지인의 개선 버전
- 자음 입력 최적화
- 특수문자 입력 개선

## 사용자 정의 입력기 만들기

### 방법 1: YAML 파일로 정의

```swift
// YAML 파일에서 IME 생성
let customIME = try IMEFactory.createFromFile(at: yamlFileURL)
```

### 방법 2: 프로그래밍 방식

```swift
class MyCustomIME: KoreanIME {
    init() {
        let processor = InputProcessor(
            choseongAutomaton: createMyChoseongAutomaton(),
            jungseongAutomaton: createMyJungseongAutomaton(),
            jongseongAutomaton: createMyJongseongAutomaton(),
            config: InputProcessorConfig(
                orderMode: .sequential,
                commitUnit: .syllable,
                displayMode: .modernMultiple,
                supportStandaloneCluster: false
            )
        )
        
        let layout = createMyLayout()
        super.init(processor: processor, layout: layout)
    }
}
```

## 고급 기능

### 도깨비불 현상
종성이 다음 음절의 초성으로 이동하는 현상:
```
갃 + ㅣ → 각시
```

### 역 도깨비불 (명시적 커밋 모드에서만 존재)
백스페이스로 이전 상태 복원:
```
각시 → (백스페이스) → 갃
```

### 종성부용초성 되돌리기
초성에서 종성으로 재해석된 자음이 백스페이스로 다시 초성이 되는 현상:
```
ㄱ(초성) → [ㅅ 입력] → ㄳ(종성) → [백스페이스] → ㄱ(초성)
```

## 테스트

```bash
# 모든 테스트 실행
swift test

# 특정 입력기 테스트
swift test --filter StandardDubeolsikTests
swift test --filter CheonJiInTests
```

## 요구사항

- Swift 5.5+
- iOS 13.0+ / macOS 10.15+

## 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 참고 자료

- [RULES.md](RULES.md) - 메타한글 입력기의 4가지 핵심 규칙
- [AUTOMATA.md](AUTOMATA.md) - 오토마타 작성용 상세 가이드

## 라이센스

이 프로젝트는 MIT 라이센스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.