# 메타 한글 입력기 설계 문서

## 개요

메타 한글 입력기는 다양한 한글 입력 방식을 통합 지원하는 범용 프레임워크입니다. 키보드 기반 한글 입력기의 다양한 입력 방식과 규칙을 추상화하여, 하나의 엔진으로 여러 입력기를 구현할 수 있도록 설계되었습니다.

## 핵심 설계 원칙

### 1. 유연한 조합 순서 지원

메타 한글 입력기는 두 가지 조합 모드를 지원합니다:

#### 순차적 조합 모드 (Sequential Mode)
- **규칙**: 초성 → 중성 → 종성 순서만 허용
- **특징**: 역순 입력 불가 (중성 후 초성 추가 불가)
- **예시**: 대부분의 전통적 입력기 (두벌식, 천지인플러스 등)

#### 자유 조합 모드 (Free Order Mode)
- **규칙**: 초성, 중성, 종성을 임의의 순서로 입력 가능
- **제약**: 동일 위치에 대한 분할 조합은 불가
  - ❌ 초성→종성→초성→중성
  - ❌ 초성→중성→종성→중성
  - ✅ 초성→종성→중성
  - ✅ 종성→중성→초성

### 2. 종성부용초성 처리

종성에만 존재할 수 있는 자음 조합(겹받침)의 처리 방식을 정의합니다.

#### 종성부용초성 허용 모드
- **동작**: 단독 겹받침 입력 허용 (예: ㄳ, ㄵ 등)
- **재해석**: 초성 조합 중 종성 전용 입력이 들어오면 기존 조합을 초성으로 재해석
- **예시**: 
  ```
  ㄱ (초성) + ㅅ (초성) → ㄳ (종성부용초성으로 재해석)
  ```

#### 종성부용초성 불허 모드
- **동작**: 겹받침은 반드시 종성 위치에서만 조합 가능
- **예시**: 초성 위치에서 ㄱ + ㅅ 입력 시 별개의 음절로 처리

### 3. 커밋 정책 관리

한글 조합의 확정 정책과 삭제 동작을 정의합니다.

#### 한글 자모 커밋 정책 (JamoCommitPolicy)
- **음절 단위 (syllable)**: 음절 단위로 조합 관리 및 삭제, 도깨비불 현상 이후에도 음절 단위 삭제
- **명시적 커밋 (explicitCommit)**: 명시적 커밋 전까지 낱자 단위로 세밀한 조합 관리
- **예시**: 
  ```
  갃 + ㅣ → 각시
  백스페이스 → 각ㅅ (시 전체 삭제)
  ```

#### 비자모 문자 커밋 정책 (NonJamoCommitPolicy)
- **문자 단위 (character)**: 다음 문자로 넘어갈 때 자동 커밋
- **명시적 커밋 (explicitCommit)**: 수동 커밋 필요
- **완료 시 (onComplete)**: 오토마타 전이 완료 시 자동 커밋

#### 전환 커밋 정책 (TransitionCommitPolicy)
- **항상 커밋 (always)**: 한글↔비한글 전환 시 항상 커밋
- **커밋 안 함 (never)**: 전환 시 커밋하지 않음

백스페이스 동작:
- JamoCommitPolicy가 syllable인 경우: 도깨비불 현상 이후에도 음절 단위 삭제
- JamoCommitPolicy가 explicitCommit인 경우: 역 도깨비불 현상 지원

### 4. 조합 표시 규칙

완성되지 않은 조합의 표시 방식을 정의합니다.

#### 옛한글 지원 모드
- **규칙**: NFD(Normalization Form D) 사용
- **표시**: 현대 한글로 조합되지 않는 글자도 조합 형태로 표시
- **예시**: ᄀᅠᆨ (초성 ㄱ + 종성 ㄱ, 중성 없음)

#### 현대 한글 전용 모드

두 가지 표시 방식 중 선택:

**다중 음절 표시**
- **규칙**: 조합 불가능한 요소를 별개 음절로 표시
- **예시**: ㄱㄱ (초성 ㄱ + 종성 ㄱ → 두 개의 ㄱ으로 표시)

**부분 표시**
- **규칙**: 표시 가능한 부분만 조합하여 표시
- **예시**: ㄱ (초성 ㄱ. 중성이 없어 이후 조합이 불가능하기 때문에, 음절 수를 유지하며 초성만 조합해서 표시)

## 구현 아키텍처

### 핵심 Enum 정의

입력기의 동작 방식을 정의하는 열거형들:

```python
from enum import Enum

class JamoPosition(Enum):
    CHOSEONG = "choseong"
    JUNGSEONG = "jungseong"
    JONGSEONG = "jongseong"

class OrderMode(Enum):
    SEQUENTIAL = "sequential"
    FREE_ORDER = "free_order"

class CommitUnit(Enum):
    SYLLABLE = "syllable"
    EXPLICIT_COMMIT = "explicit_commit"

class DisplayMode(Enum):
    ARCHAIC = "archaic"
    MODERN_MULTIPLE = "modern_multiple"
    MODERN_PARTIAL = "modern_partial"
```

### SyllableState

조합 중인 단일 음절의 상태를 관리하는 구조체:

```python
@dataclass
class SyllableState:
    choseong_state: Optional[str] = None      # 현재 초성 상태
    jungseong_state: Optional[str] = None     # 현재 중성 상태
    jongseong_state: Optional[str] = None     # 현재 종성 상태
    special_character_state: Optional[str] = None  # 현재 특수문자/기타 입력 상태
    
    # FREE_ORDER 모드를 위한 조합 순서 추적
    composition_order: List[JamoPosition] = field(default_factory=list)
    
    def is_empty(self) -> bool:
        """비어있는 상태인지 확인"""
        return (self.choseong_state is None and 
                self.jungseong_state is None and 
                self.jongseong_state is None and 
                self.special_character_state is None)
    
    def has_hangul(self) -> bool:
        """한글 자모가 있는지 확인"""
        return (self.choseong_state is not None or 
                self.jungseong_state is not None or 
                self.jongseong_state is not None)
    
    def can_add_jamo(self, position: JamoPosition, order_mode: OrderMode) -> bool:
        """주어진 위치에 자모를 추가할 수 있는지 확인"""
        if order_mode == OrderMode.SEQUENTIAL:
            # 순차적 모드: 초성 → 중성 → 종성 순서 엄격히 준수
            if position == JamoPosition.CHOSEONG:
                return self.jungseong_state is None and self.jongseong_state is None
            elif position == JamoPosition.JUNGSEONG:
                return self.jongseong_state is None
            else:  # JONGSEONG
                return True
        else:  # FREE_ORDER
            # 자유 순서 모드: 마지막 입력 위치 이후 다른 위치 입력이 없어야 함
            if position in self.composition_order:
                last_occurrence = max(i for i, p in enumerate(self.composition_order) if p == position)
                for i in range(last_occurrence + 1, len(self.composition_order)):
                    if self.composition_order[i] != position:
                        return False
            return True
    
    def add_jamo(self, position: JamoPosition, state: str):
        """자모 추가 및 조합 순서 기록"""
        # 기존 상태 확인 (업데이트인지 새로운 추가인지)
        is_update = False
        if position == JamoPosition.CHOSEONG:
            is_update = self.choseong_state is not None
            self.choseong_state = state
        elif position == JamoPosition.JUNGSEONG:
            is_update = self.jungseong_state is not None
            self.jungseong_state = state
        else:  # JONGSEONG
            is_update = self.jongseong_state is not None
            self.jongseong_state = state
        
        # 새로운 위치에 추가하는 경우에만 composition_order에 추가
        if not is_update:
            self.composition_order.append(position)
    
    def copy(self) -> 'SyllableState':
        """상태 복사"""
        return SyllableState(
            choseong_state=self.choseong_state,
            jungseong_state=self.jungseong_state,
            jongseong_state=self.jongseong_state,
            special_character_state=self.special_character_state,
            composition_order=self.composition_order.copy()
        )
```

### VirtualKey

가상 키는 입력기의 키를 추상화한 데이터 구조입니다:

```python
@dataclass
class VirtualKey:
    keyIdentifier: str    # 내부 처리용 고유 식별자
    label: str           # 표시용 레이블
    isSpecialKey: bool = False  # 특수문자/기타 입력 여부
```

### InputProcessor

입력을 처리하고 적절한 오토마타로 라우팅하는 핵심 클래스:

```python
class InputProcessor:
    def __init__(self, 
                 choseong_automaton: ChoseongAutomaton,
                 jungseong_automaton: JungseongAutomaton,
                 jongseong_automaton: JongseongAutomaton,
                 special_character_automaton: Optional[SpecialCharacterAutomaton] = None,
                 dokkaebi_automaton: Optional[DokkaebiAutomaton] = None,
                 backspace_automaton: Optional[BackspaceAutomaton] = None,
                 order_mode: OrderMode = OrderMode.SEQUENTIAL,
                 commit_unit: CommitUnit = CommitUnit.SYLLABLE,
                 display_mode: DisplayMode = DisplayMode.MODERN_MULTIPLE,
                 support_standalone_cluster: bool = False):
        
        # 오토마타들
        self.choseong_automaton = choseong_automaton
        self.jungseong_automaton = jungseong_automaton
        self.jongseong_automaton = jongseong_automaton
        self.special_character_automaton = special_character_automaton
        self.dokkaebi_automaton = dokkaebi_automaton
        self.backspace_automaton = backspace_automaton
        
        # 설정
        self.order_mode = order_mode
        self.commit_unit = commit_unit
        self.display_mode = display_mode
        self.support_standalone_cluster = support_standalone_cluster
    
    def process(self, previous_state: SyllableState, current_state: SyllableState, 
                input_key: VirtualKey) -> Tuple[Optional[SyllableState], SyllableState, int]:
        """
        입력 키 처리
        
        Returns:
            tuple[Optional[SyllableState], SyllableState, int]: 
            (이전 음절의 수정된 상태, 현재 음절의 상태, 커서 이동)
            - 이전 음절 상태: None이면 이전 음절 수정 없음
            - 커서 이동: 0(현재 유지), 1(새 음절)
        """
        cursor_movement = 0
        
        # 특수문자 처리
        if input_key.isSpecialKey:
            # ... 특수문자 처리 로직 ...
            pass
        
        # 종성부용초성 처리
        if (self.support_standalone_cluster and 
            not current_state.jungseong_state and
            current_state.choseong_state):
            # ... 종성부용초성 처리 로직 ...
            pass
        
        # 현재 음절에 추가 시도
        result = self._try_add_to_current_syllable(current_state, input_key)
        if result:
            return previous_state, current_state, cursor_movement
        
        # 도깨비불 처리
        if (self.dokkaebi_automaton and 
            current_state.jongseong_state and
            self.jungseong_automaton.transition(None, input_key.keyIdentifier)):
            # ... 도깨비불 처리 로직 ...
            pass
        
        # 새 음절 생성
        new_state = self._create_new_syllable_with_input(input_key)
        
        if current_state.is_empty():
            return previous_state, new_state, cursor_movement
        else:
            return current_state, new_state, 1
    
    def process_backspace(self, previous_state: SyllableState, current_state: SyllableState) -> Tuple[Optional[SyllableState], SyllableState]:
        """
        백스페이스 처리
        
        백스페이스에는 두 가지 특수 케이스가 있습니다:
        
        1. '종성부용초성' 되돌리기
           조건 1: 종성부용초성이 켜져있는 입력기
           조건 2: 현재 음절에 종성만 입력되어 있음
           조건 3: 백스페이스 오토마타의 동작 결과 종성이 초성이 될 수 있는 글자로 바뀌었음
           결과: 해당 낱자는 초성으로 이동
           예시: ㄱ(초성) → [입력:ㅅ] → ㄳ(종성) → [입력:백스페이스] → ㄱ(초성)
        
        2. '역 도깨비불' 현상
           조건 1: 도깨비불 현상이 허용되는 입력기
           조건 2: 백스페이스의 결과로 현재 음절에 초성만 남았을 경우
           조건 3: 이전 음절의 composition_order가 종성으로 끝나거나 혹은 이전 음절에 종성이 없을 때
           조건 4: 이전 음절의 종성 위치에 남아 있는 초성을 조합할 수 있으면
           결과: 해당 낱자는 이전 음절의 종성으로 이동하거나, 그 종성과 조합
           예시: 갃 → [입력:ㅣ] → 각시 → [입력:백스페이스] → 갃
        
        Returns:
            tuple[Optional[SyllableState], SyllableState]: 
            (이전 음절의 수정된 상태, 현재 음절의 상태)
        """
        if self.current_syllable.is_empty:
            return None, self.current_syllable
        
        # composition_order의 마지막부터 처리
        if not self.current_syllable.composition_order:
            return None, self.current_syllable
        
        last_position = self.current_syllable.composition_order[-1]
        current_state = None
        
        # 현재 상태 가져오기
        if last_position == JamoPosition.CHOSEONG:
            current_state = self.current_syllable.choseong_state
        elif last_position == JamoPosition.JUNGSEONG:
            current_state = self.current_syllable.jungseong_state
        elif last_position == JamoPosition.JONGSEONG:
            current_state = self.current_syllable.jongseong_state
        
        if not current_state:
            return None, self.current_syllable
        
        # 백스페이스 오토마타 적용
        backspace_result = self.backspace_automaton.process(current_state)
        
        # 상태 업데이트
        if backspace_result.new_state:
            # 낱자 변경
            if last_position == JamoPosition.CHOSEONG:
                self.current_syllable.choseong_state = backspace_result.new_state
            elif last_position == JamoPosition.JUNGSEONG:
                self.current_syllable.jungseong_state = backspace_result.new_state
            elif last_position == JamoPosition.JONGSEONG:
                self.current_syllable.jongseong_state = backspace_result.new_state
        else:
            # 낱자 완전 삭제
            if last_position == JamoPosition.CHOSEONG:
                self.current_syllable.choseong_state = None
            elif last_position == JamoPosition.JUNGSEONG:
                self.current_syllable.jungseong_state = None
            elif last_position == JamoPosition.JONGSEONG:
                self.current_syllable.jongseong_state = None
            self.current_syllable.composition_order.pop()
        
        # 특수 케이스 1: 종성부용초성 되돌리기
        if (self.config.allow_standalone_cluster and
            last_position == JamoPosition.JONGSEONG and
            not self.current_syllable.choseong_state and
            not self.current_syllable.jungseong_state and
            self.current_syllable.jongseong_state):
            
            # 종성이 초성이 될 수 있는지 확인 (초성 오토마타에 존재하는지)
            jong_state = self.current_syllable.jongseong_state
            if self.choseong_automaton.has_state(jong_state):
                # 종성을 초성으로 이동
                self.current_syllable.choseong_state = jong_state
                self.current_syllable.jongseong_state = None
                # composition_order 업데이트
                idx = self.current_syllable.composition_order.index(JamoPosition.JONGSEONG)
                self.current_syllable.composition_order[idx] = JamoPosition.CHOSEONG
        
        # 특수 케이스 2: 역 도깨비불 (명시적 커밋 모드에서만)
        if (self.config.commit_unit == CommitUnit.EXPLICIT_COMMIT and
            self.dokkaebi_automaton and
            len(self.current_syllable.composition_order) == 1 and
            self.current_syllable.composition_order[0] == JamoPosition.CHOSEONG and
            self.current_syllable.choseong_state):
            
            # 이전 음절 확인
            if (self.previous_syllable and not self.previous_syllable.is_empty):
                # 이전 음절의 마지막이 종성이거나 종성이 없는 경우
                prev_has_jongseong = (self.previous_syllable.composition_order and 
                                    self.previous_syllable.composition_order[-1] == JamoPosition.JONGSEONG)
                prev_no_jongseong = not self.previous_syllable.jongseong_state
                
                if prev_has_jongseong or prev_no_jongseong:
                    # 현재 초성과 이전 종성을 결합할 수 있는지 확인
                    current_cho = self.current_syllable.choseong_state
                    prev_jong = self.previous_syllable.jongseong_state or ""
                    
                    # 종성 오토마타로 결합 시도
                    test_transition = self.jongseong_automaton.transition(
                        prev_jong, VirtualKey(current_cho, True, False, True, False)
                    )
                    
                    if test_transition:
                        # 역 도깨비불 발생
                        modified_prev = SyllableState()
                        modified_prev.choseong_state = self.previous_syllable.choseong_state
                        modified_prev.jungseong_state = self.previous_syllable.jungseong_state
                        modified_prev.jongseong_state = test_transition
                        modified_prev.composition_order = self.previous_syllable.composition_order.copy()
                        
                        if not prev_has_jongseong:
                            modified_prev.composition_order.append(JamoPosition.JONGSEONG)
                        
                        # 현재 음절 비우기
                        self.current_syllable = SyllableState()
                        
                        return modified_prev, self.current_syllable
        
        return None, self.current_syllable
    
    def handle_explicit_commit(self):
        """명시적 커밋 처리"""
        if self.pre_commit_buffer:
            self.committed_text += self.pre_commit_buffer.commit()
            self.pre_commit_buffer = PreCommitBuffer()
```

### Automaton

오토마타는 상태 전이와 문자 매핑을 관리합니다:

```python
class Automaton:
    def __init__(self):
        # 상태 전이 테이블
        self.transition_table: dict[str, dict[str, str]] = {}
        # 상태-문자 매퍼
        self.state_to_character_map: dict[str, str] = {}
    
    def transition(self, current_state: str, input_key: VirtualKey) -> str | None:
        """현재 상태에서 입력 키에 따른 다음 상태 반환"""
        return self.transition_table.get(current_state, {}).get(input_key.key_identifier)
    
    def to_character(self, state: str) -> str | None:
        """상태를 한글 낱자로 변환 (Hangul Jamo U+1100-U+11FF 영역 사용)"""
        return self.state_to_character_map.get(state)
    
    def has_state(self, state: str) -> bool:
        """주어진 상태가 오토마타에 존재하는지 확인 (초기 상태 또는 결과 상태)"""
        # 초기 상태로 존재하는지 확인
        if state in self.transition_table:
            return True
        # 결과 상태로 존재하는지 확인
        for transitions in self.transition_table.values():
            if state in transitions.values():
                return True
        return False
```

### 핵심 메서드들

#### _try_add_to_current_syllable
```python
def _try_add_to_current_syllable(self, current_state: SyllableState, input_key: VirtualKey) -> bool:
    """현재 음절에 입력을 추가할 수 있는지 시도. 성공하면 True 반환"""
    # ... 구현 ...
```

#### _create_new_syllable_with_input
```python
def _create_new_syllable_with_input(self, input_key: VirtualKey) -> SyllableState:
    """주어진 입력 키로 새 음절 생성"""
    # ... 구현 ...
```

### build_display 메서드

상태를 바탕으로 한글 음절을 조합하는 핵심 메서드:

```python
def build_display(self, state: SyllableState) -> str:
    """현재 상태를 표시용 문자열로 빌드"""
    if state.special_character_state:
        if self.special_character_automaton:
            return self.special_character_automaton.display(state.special_character_state)
        return ""
    
    if self.display_mode == DisplayMode.ARCHAIC:
        return self._build_archaic_display(state)
    elif self.display_mode == DisplayMode.MODERN_MULTIPLE:
        return self._build_multiple_syllables(state)
    else:  # MODERN_PARTIAL
        return self._build_partial_display(state)
```

#### _try_compose_syllable
```python
def _try_compose_syllable(self, cho: str, jung: str, jong: str) -> Tuple[Optional[str], Optional['SyllableState']]:
    """
    한글 음절 조합 시도
    
    Returns:
        (composed_char, remaining_state) - 조합된 문자와 남은 상태
    """
    # ... 구현 ...
```

#### _jamo_to_compatibility
```python
def _jamo_to_compatibility(self, jamo: str) -> str:
    """Hangul Jamo (U+1100-U+11FF)를 Compatibility Jamo (U+3130-U+318F)로 변환"""
    # ... 구현 ...
```
```

### KoreanIME 클래스

모든 한국어 IME의 베이스 클래스:

```python
class KoreanIME(ABC):
    """
    한국어 IME의 추상 베이스 클래스
    
    핵심 기능:
    - 문자 입력 처리
    - 백스페이스 처리
    - 상태 관리 (previous/current syllables)
    - 커밋 처리 (SYLLABLE vs EXPLICIT_COMMIT modes)
    """
    
    def __init__(self, processor: InputProcessor, layout: Dict[str, VirtualKey]):
        self.processor = processor
        self.layout = layout
        self.previous_state = None
        self.current_state = SyllableState()
        self.committed_text = ""
        # EXPLICIT_COMMIT 모드에서 사용
        self.uncommitted_syllables = []
    
    def input(self, key: str) -> str:
        """키 입력 처리하고 현재 표시 문자열 반환"""
        # ... 구현 ...
    
    def backspace(self) -> str:
        """백스페이스 처리하고 현재 표시 문자열 반환"""
        # ... 구현 ...
    
    def get_display(self) -> str:
        """현재 표시 텍스트 반환"""
        # ... 구현 ...
    
    def commit(self) -> str:
        """모든 대기 중인 텍스트 커밋, 상태 초기화, 커밋된 텍스트 반환"""
        # ... 구현 ...
```

## 입력기별 구현 예시

### 두벌식 표준

```python
def create_standard_dubeolsik_processor():
    """Create InputProcessor for Standard Dubeolsik"""
    return InputProcessor(
        choseong_automaton=create_choseong_automaton(),
        jungseong_automaton=create_jungseong_automaton(),
        jongseong_automaton=create_jongseong_automaton(),
        dokkaebi_automaton=create_dokkaebi_automaton(),
        backspace_automaton=create_backspace_automaton(),
        order_mode=OrderMode.SEQUENTIAL,
        commit_unit=CommitUnit.SYLLABLE,
        display_mode=DisplayMode.MODERN_MULTIPLE,
        support_standalone_cluster=False
    )
```

### 세벌식 최종

```python
def create_sebeolsik_final_processor():
    """Create InputProcessor for Sebeolsik Final"""
    return InputProcessor(
        choseong_automaton=create_choseong_automaton(),
        jungseong_automaton=create_jungseong_automaton(),
        jongseong_automaton=create_jongseong_automaton(),
        backspace_automaton=create_backspace_automaton(),
        order_mode=OrderMode.FREE_ORDER,  # 모아쓰기 지원
        commit_unit=CommitUnit.SYLLABLE,
        display_mode=DisplayMode.MODERN_MULTIPLE,
        support_standalone_cluster=False
    )
```

### 천지인

```python
def create_cheonjiin_processor():
    """Create InputProcessor for CheonJiIn"""
    return InputProcessor(
        choseong_automaton=create_choseong_automaton(),
        jungseong_automaton=create_jungseong_automaton(),
        jongseong_automaton=create_jongseong_automaton(),
        order_mode=OrderMode.SEQUENTIAL,
        commit_unit=CommitUnit.EXPLICIT_COMMIT,  # 명시적 커밋
        display_mode=DisplayMode.MODERN_MULTIPLE,
        support_standalone_cluster=True
    )
```

### KoreanIME 사용 예시

```python
class StandardDubeolsik(KoreanIME):
    """Standard Dubeolsik IME"""
    def __init__(self):
        processor = create_standard_dubeolsik_processor()
        layout = create_standard_dubeolsik_layout()
        super().__init__(processor, layout)

# 사용
ime = StandardDubeolsik()
result = ime.input('r')  # ㄱ
result = ime.input('k')  # 가
result = ime.input('s')  # 간
ime.commit()             # 현재 음절 확정
result = ime.input(' ')  # 공백 입력
```

### DokkaebiAutomaton

도깨비불 현상을 처리하는 전용 오토마타:

```python
from dataclasses import dataclass
from typing import Optional

@dataclass
class DokkaebiResult:
    """도깨비불 처리 결과"""
    should_split: bool  # 도깨비불 발생 여부
    remaining_jongseong_state: Optional[str] = None  # 이전 음절에 남은 종성 상태
    moved_choseong_state: Optional[str] = None       # 새 음절로 이동할 초성 상태

class DokkaebiAutomaton:
    """
    도깨비불 현상 처리를 위한 오토마타
    
    이전 음절에 종성이 있고 중성이 입력될 때 호출되어,
    종성을 분리하거나 이동시켜 새 음절을 생성하는 규칙을 정의
    """
    
    def __init__(self):
        # 도깨비불 전이 테이블: 종성_상태 -> (남은_종성, 이동할_초성)
        # 전이 테이블에 정의된 경우만 도깨비불 발생
        self.transition_table: dict[str, tuple[Optional[str], str]] = {}
    
    def can_split(self, jongseong_state: str) -> bool:
        """도깨비불 발생 가능 여부 확인"""
        return jongseong_state in self.transition_table
    
    def process(self, jongseong_state: str) -> DokkaebiResult:
        """
        도깨비불 현상 처리
        
        Args:
            jongseong_state: 현재 종성 상태
            
        Returns:
            DokkaebiResult: 도깨비불 처리 결과
        """
        if jongseong_state in self.transition_table:
            remaining_jong, moved_cho = self.transition_table[jongseong_state]
            
            return DokkaebiResult(
                should_split=True,
                remaining_jongseong_state=remaining_jong,  # None일 수 있음 (종성 전체 이동)
                moved_choseong_state=moved_cho
            )
        
        # 전이 테이블에 없으면 도깨비불 발생하지 않음
        return DokkaebiResult(should_split=False)

class TwoBeolsikDokkaebiAutomaton(DokkaebiAutomaton):
    """두벌식 표준을 위한 도깨비불 오토마타 구현 예시"""
    
    def __init__(self):
        super().__init__()
        
        # 홑받침 이동 규칙 - 전체가 이동 (남은 종성은 None)
        single_consonants = ["ㄱ", "ㄴ", "ㄷ", "ㄹ", "ㅁ", "ㅂ", "ㅅ", 
                           "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ", "ㄲ", "ㅆ"]
        
        for jong in single_consonants:
            self.transition_table[jong] = (None, jong)
        
        # 겹받침 분리 규칙
        self.transition_table["ㄳ"] = ("ㄱ", "ㅅ")  # ㄳ = ㄱ + ㅅ
        self.transition_table["ㄵ"] = ("ㄴ", "ㅈ")  # ㄵ = ㄴ + ㅈ
        self.transition_table["ㄶ"] = ("ㄴ", "ㅎ")  # ㄶ = ㄴ + ㅎ
        self.transition_table["ㄺ"] = ("ㄹ", "ㄱ")  # ㄺ = ㄹ + ㄱ
        self.transition_table["ㄻ"] = ("ㄹ", "ㅁ")  # ㄻ = ㄹ + ㅁ
        self.transition_table["ㄼ"] = ("ㄹ", "ㅂ")  # ㄼ = ㄹ + ㅂ
        self.transition_table["ㄽ"] = ("ㄹ", "ㅅ")  # ㄽ = ㄹ + ㅅ
        self.transition_table["ㄾ"] = ("ㄹ", "ㅌ")  # ㄾ = ㄹ + ㅌ
        self.transition_table["ㄿ"] = ("ㄹ", "ㅍ")  # ㄿ = ㄹ + ㅍ
        self.transition_table["ㅀ"] = ("ㄹ", "ㅎ")  # ㅀ = ㄹ + ㅎ
        self.transition_table["ㅄ"] = ("ㅂ", "ㅅ")  # ㅄ = ㅂ + ㅅ

### 백스페이스 처리의 복잡성

백스페이스는 단순히 마지막 입력을 제거하는 것이 아니라, 한글 조합의 특성상 복잡한 처리가 필요합니다:

#### 1. 기본 백스페이스
- 겹자음/겹모음의 분해: ㄲ → ㄱ, ㅘ → ㅗ
- 단일 자모의 삭제: ㄱ → (삭제)

#### 2. 종성부용초성 되돌리기 (Standalone Cluster Reversal)
초성 위치에서 종성으로 재해석된 자음이 백스페이스로 다시 초성이 되는 현상:
```
ㄱ(초성) → [ㅅ 입력] → ㄳ(종성) → [백스페이스] → ㄱ(초성)
```

#### 3. 역 도깨비불 (Reverse Dokkaebi)
EXPLICIT_COMMIT 모드에서 분리된 음절이 다시 결합하는 현상:
```
갃 → [ㅣ 입력] → 각시 → [백스페이스] → 갃
```

조건:
- 현재 음절에 초성만 남음
- 이전 음절이 존재하고 종성 위치가 비어있거나 종성으로 끝남
- 현재 초성이 이전 종성과 결합 가능

#### 4. 이전 음절로의 이동
현재 음절이 비어있을 때 이전 음절로 커서 이동하여 백스페이스 처리

### BackspaceAutomaton

백스페이스 처리를 위한 전용 오토마타:

```python
@dataclass
class BackspaceResult:
    """백스페이스 처리 결과"""
    new_state: Optional[str] = None  # 변경된 낱자 상태 (None이면 완전 삭제)
    
class BackspaceAutomaton:
    """
    백스페이스 처리를 위한 오토마타
    
    낱자의 종류(초성/중성/종성)를 구분하지 않고,
    현재 상태에서 백스페이스 시 다음 상태를 정의
    """
    
    def __init__(self):
        # 백스페이스 전이 테이블: 현재_상태 -> 다음_상태 (None이면 삭제)
        self.transition_table: dict[str, Optional[str]] = {}
    
    def process(self, current_state: str) -> BackspaceResult:
        """백스페이스 처리"""
        new_state = self.transition_table.get(current_state)
        return BackspaceResult(new_state=new_state)

class DefaultBackspaceAutomaton(BackspaceAutomaton):
    """기본 백스페이스 오토마타 - 한 번에 한 낱자씩 삭제"""
    
    def __init__(self):
        super().__init__()
        # 대부분의 낱자는 백스페이스 시 완전 삭제
        # 겹자음/겹모음만 분해
        self.transition_table = {
            # 겹자음 분해
            "ㄲ": "ㄱ", "ㄸ": "ㄷ", "ㅃ": "ㅂ", "ㅆ": "ㅅ", "ㅉ": "ㅈ",
            # 겹받침 분해
            "ㄳ": "ㄱ", "ㄵ": "ㄴ", "ㄶ": "ㄴ", "ㄺ": "ㄹ", "ㄻ": "ㄹ",
            "ㄼ": "ㄹ", "ㄽ": "ㄹ", "ㄾ": "ㄹ", "ㄿ": "ㄹ", "ㅀ": "ㄹ", "ㅄ": "ㅂ",
            # 이중모음 분해 (입력기에 따라 다를 수 있음)
            "ㅘ": "ㅗ", "ㅙ": "ㅘ", "ㅚ": "ㅗ", "ㅝ": "ㅜ", "ㅞ": "ㅝ", 
            "ㅟ": "ㅜ", "ㅢ": "ㅡ"
        }

## 도깨비불 현상 처리

도깨비불 현상은 입력기별로 다르게 구현되며, DokkaebiAutomaton을 통해 처리됩니다:

### 정방향 도깨비불
종성이 다음 음절의 초성으로 이동:
```
갃 + ㅣ → 각시
```

### 역방향 도깨비불 (명시적 커밋이 있는 입력기에서만)
백스페이스로 이전 상태 복원:
```
각시 → (백스페이스) → 갃
```

명시적 커밋이 있는 입력기에서만 역방향 도깨비불이 가능한 이유:
- 음절 단위 커밋: 이전 음절이 이미 확정되어 수정 불가
- 명시적 커밋: 이전 음절이 아직 미확정 상태로 수정 가능

## 테스트 시나리오

### 1. 조합 순서 테스트
- 순차 모드: ㄱ→ㅏ→ㄴ ✅, ㅏ→ㄱ→ㄴ ❌
- 자유 모드: ㄱ→ㄴ→ㅏ ✅, ㄴ→ㅏ→ㄱ ✅

### 2. 종성부용초성 테스트
- 허용 모드: ㄱ+ㅅ (초성 위치) → ㄳ
- 불허 모드: ㄱ+ㅅ (초성 위치) → ㄱㅅ (별개)

### 3. 커밋 정책 테스트
- JamoCommitPolicy.syllable: 갃ㅣ → 각시 → (BS) → 각ㅅ → (BS) → 각 → (BS) → (빈 상태)
- JamoCommitPolicy.explicitCommit: 갃ㅣ → 각시 → (BS) → 갃 → (BS) → 각 → (BS) → 가
- TransitionCommitPolicy.always: 안+a → 안 커밋 후 a 입력
- TransitionCommitPolicy.never: 안+a → 안a (커밋 없이 이어서)

### 4. 표시 규칙 테스트
- 옛한글: ㄱ(초)+ㄱ(종) → ᄀᅠᆨ
- 현대한글(다중): ㄱ(초)+ㄱ(종) → ㄱㄱ
- 현대한글(부분): ㄱ(초)+ㄱ(종) → ㄱ (초성만 표시)

### 5. 특수문자 오토마타 테스트
- 천지인 예시: . → , → ? → ! (순환)
- 특수문자 상태에서 한글 입력: ! + ㄱ → ! ㄱ (새 음절)
- 한글 상태에서 특수문자 입력: 가 + . → 가. (새 음절)

### 6. 백스페이스 특수 케이스 종합 테스트
명시적 커밋과 종성부용초성이 모두 켜진 입력기에서 두 특수 케이스를 모두 테스트:

```
ㄱ(초성) 
→ [입력:ㅅ, 종성부용초성 발생] → ㄳ(종성) 
→ [입력:ㅣ, 도깨비불 발생] → ㄱ시 
→ [입력: 백스페이스, 역 도깨비불 발생] → ㄳ(종성) 
→ [입력: 백스페이스, 종성부용초성 되돌리기 발생] → ㄱ(초성)
```

이 시나리오는 다음을 검증합니다:
- 종성부용초성이 정상적으로 작동 (ㄱ+ㅅ → ㄳ)
- 도깨비불 현상이 정상적으로 작동 (ㄳ+ㅣ → ㄱ시)
- 역 도깨비불이 정상적으로 작동 (ㄱ시 → ㄳ)
- 종성부용초성 되돌리기가 정상적으로 작동 (ㄳ → ㄱ)

## Python 구현

현재 구현된 메타 한글 IME의 핵심 구조:

### InputProcessor 클래스
```python
class InputProcessor:
    def __init__(self, 
                 choseong_automaton: ChoseongAutomaton,
                 jungseong_automaton: JungseongAutomaton,
                 jongseong_automaton: JongseongAutomaton,
                 special_character_automaton: Optional[SpecialCharacterAutomaton] = None,
                 dokkaebi_automaton: Optional[DokkaebiAutomaton] = None,
                 backspace_automaton: Optional[BackspaceAutomaton] = None,
                 order_mode: OrderMode = OrderMode.SEQUENTIAL,
                 commit_unit: CommitUnit = CommitUnit.SYLLABLE,
                 display_mode: DisplayMode = DisplayMode.MODERN_MULTIPLE,
                 support_standalone_cluster: bool = False)
```

### process 메서드 구조
```python
def process(self, previous_state: SyllableState, current_state: SyllableState, 
            input_key: VirtualKey) -> Tuple[Optional[SyllableState], SyllableState, int]:
    """
    Returns:
        - 이전 음절의 수정된 상태 (도깨비불 처리용)
        - 현재 음절의 상태
        - 커서 이동 (0: 유지, 1: 새 음절)
    """
```

### process_backspace 메서드 구조
```python
def process_backspace(self, previous_state: SyllableState, current_state: SyllableState) -> Tuple[Optional[SyllableState], SyllableState]:
    """
    Returns:
        - 이전 음절의 수정된 상태 (역 도깨비불 처리용)
        - 현재 음절의 상태
    """
```

## 확장성

이 설계는 다음과 같은 확장을 지원합니다:

1. **새로운 입력기 추가**: 오토마타와 InputProcessor 파라미터만 정의
2. **커스텀 규칙**: 특수한 조합 규칙을 가진 입력기 지원
3. **다국어 지원**: 한글 외 다른 단순 오토마타 문자 입력 시스템 적용 가능
4. **플랫폼 독립성**: 핵심 로직은 플랫폼 중립적으로 설계

## 결론

메타 한글 입력기는 RULES.md에 정의된 네 가지 핵심 규칙을 모두 지원하여, 현존하는 대부분의 키보드 기반 한글 입력기를 하나의 통합된 프레임워크로 구현할 수 있습니다. 이를 통해 새로운 입력기 개발 시간을 단축하고, 일관된 품질과 동작을 보장할 수 있습니다.