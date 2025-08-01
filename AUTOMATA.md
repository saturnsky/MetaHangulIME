# 메타 한글 입력기 오토마타 작성 가이드

이 문서는 메타 한글 입력기의 YAML 설정 파일을 작성하는 방법을 설명합니다. YAML 파일을 통해 다양한 한글 입력 방식을 정의할 수 있습니다.

## YAML 파일 구조

### 기본 정보
```yaml
name: "입력기 이름"
identifier: "고유 식별자"
```

### 설정 (config)
```yaml
config:
  orderMode: "sequential"           # sequential | freeOrder
  commitUnit: "syllable"           # syllable | explicitCommit
  displayMode: "modernMultiple"    # archaic | modernMultiple | modernPartial
  supportStandaloneCluster: false  # true | false
```

- **orderMode**: 자모 입력 순서
  - `sequential`: 초성→중성→종성 순서로만 입력
  - `freeOrder`: 자유로운 순서로 입력 가능

- **commitUnit**: 커밋 단위
  - `syllable`: 음절 단위로 자동 커밋
  - `explicitCommit`: 명시적 커밋 필요

- **displayMode**: 표시 방식
  - `archaic`: 현대 한글 한 음절로 조합되지 않을 경우 옛한글 형태로 표시
  - `modernMultiple`: 한 음절로 조합되지 않을 경우 여러 음절로 나눠 표시
  - `modernPartial`: 한 음절로 조합되지 않을 경우 조합되는 부분까지만 표시

- **supportStandaloneCluster**: 종성을 단독으로 입력할 수 있는지 여부
  - `true`: 종성으로만 조합 가능한 조합도 단독으로 조합 가능
  - `false`: 종성으로만 조합 가능한 조합은 단독으로 조합 불가

## 레이아웃 정의

### 기본 구조
```yaml
layout:
  "키": { identifier: "식별자", label: "레이블", isNonKorean: true | false }
```
- **키**: 레이아웃에 정의할 키 이름. 키보드 위치에 따른 값을 사용해도 되고, 의미 있는 이름을 사용해도 됩니다. 유니크해야 합니다.
- **identifier**: 입력 처리에 사용되는 식별자. 내부 State 관리에 사용되며, 유니크해야 합니다. 이 값이 오토마타에 전달됩니다.
- **label**: 표시용 레이블. 입력하지 않아도 됩니다. 레이아웃 디스플레이 등에 활용할 수 있습니다.
- **isNonKorean**: 한글이 아닌 문자 여부. `true`로 설정하면 한글 오토마타가 아닌 특수문자 오토마타를 사용합니다. 기본값은 `false`입니다.

### 예시
```yaml
layout:
  # 자음 - 두벌식 키보드 기준
  r: { identifier: "ㄱ", label: "ㄱ" }
  R: { identifier: "ㄲ", label: "ㄲ" }
  
  # 모음
  k: { identifier: "ㅏ", label: "ㅏ" }
  
  # 특수문자 - 천지인의 마침표 순환 입력 예시
  c: { identifier: ".,?!", label: ".,?!", isNonKorean: true }
```

## 오토마타 정의

### 낱자 오토마타 (choseong, jungseong, jongseong)

#### 전이 규칙 (transitions)
```yaml
automata:
  choseong:
    transitions:
      - { from: "", input: "ㄱ", to: "ㄱ" }
      - { from: "ㄱ", input: "ㄱ", to: "ㅋ" }
      - { from: "ㅋ", input: "ㄱ", to: "ㄲ" }
  jungseong:
    transitions:
      - { from: "", input: "ㅏ", to: "ㅏ" }
      - { from: "", input: "ㅣ", to: "ㅣ" }
      # ㅗ + ㅏ = ㅘ
      - { from: "ㅗ", input: "ㅏ", to: "ㅘ" }
      # ㅘ + ㅣ = ㅙ
      - { from: "ㅘ", input: "ㅣ", to: "ㅙ" }
  jongseong:
    transitions:
      - { from: "", input: "ㄱ", to: "ㄱ" }
      - { from: "", input: "ㄴ", to: "ㄴ" }
      # ㄱ + ㅅ = ㄳ
      - { from: "ㄱ", input: "ㅅ", to: "ㄳ" }
      # ㄴ + ㅈ = ㄵ
      - { from: "ㄴ", input: "ㅈ", to: "ㄵ" }
```

- **from**: 현재 상태 (빈 문자열 ""은 초기 상태)
- **input**: 입력 키의 identifier
- **to**: 다음 상태

#### 표시 매핑 (display)
```yaml
automata:
  choseong:
    display:
      "ㄱ": "\u1100"  # ᄀ (HANGUL JAMO 초성)
      "ㄲ": "\u1101"  # ᄁ
      "ㄴ": "\u1102"  # ᄂ
  jungseong:
    display:
      "ㅏ": "\u1161"  # ᅡ (HANGUL JAMO 중성)
      "ㅘ": "\u116A"  # ᅪ
  jongseong:
    display:
      "ㄳ": "\u11AA"  # ᆪ (HANGUL JAMO 종성)
      "ㄵ": "\u11AC"  # ᆬ
```

#### 주의사항

- **유니코드 영역**: 표시 매핑은 반드시 HANGUL JAMO 영역의 유니코드 문자를 사용해야 합니다. 예를 들어, 초성 "ㄱ"은 `\u1100` (ᄀ)입니다.
- **상태 식별자 중복**: 초성과 종성에 동일한 identifier가 있을 수 있습니다. 예를 들어, "ㄱ"은 초성으로도 종성으로도 사용됩니다. 이 경우 입력 컨텍스트에 따라 적절한 오토마타가 선택됩니다.
- **복수 문자 표시**: 표시 매핑에 여러 HANGUL JAMO 문자를 연속으로 사용할 수 있습니다. 예: "ㄹㄷ"를 `\u11AF\u11AE` (ᆯᆮ)로 표시. 이는 중간 상태 표시나 옛한글 입력에 활용됩니다.
- **동일 표시값**: 여러 상태가 동일한 표시값을 가질 수 있습니다. 세벌식처럼 위치별로 다른 키가 동일한 자모를 입력하는 경우에 유용합니다.

## 도깨비불 오토마타 (dokkaebibul)

도깨비불 현상은 종성이 다음 음절의 초성으로 이동하는 현상입니다.
종성 입력 후 중성을 입력할 때 도깨비불 현상이 발생하는 입력기는 도깨비 오토마타를 정의해야 합니다.

```yaml
  dokkaebibul:
    transitions:
      # 전체 이동
      - { jongseong: "ㄱ", remaining: null, moved: "ㄱ" }
      
      # 부분 이동 (겹받침 분리)
      - { jongseong: "ㄳ", remaining: "ㄱ", moved: "ㅅ" }
      - { jongseong: "ㄵ", remaining: "ㄴ", moved: "ㅈ" }
```

- **jongseong**: 원래 존재하던 종성
- **remaining**: 현재 음절에 남을 종성 (null이면 전체 이동)
- **moved**: 다음 음절로 이동할 초성

## 백스페이스 오토마타 (backspace)

백스페이스 시 낱자가 어떻게 변할지를 정의합니다. 정의가 없을 경우 낱자가 한 번에 삭제됩니다.

```yaml
  backspace:
    transitions:
      # 겹자음 분해
      - { from: "ㄲ", to: "ㄱ" }
      
      # 복합 모음 분해
      - { from: "ㅘ", to: "ㅗ" }
      - { from: "ㅙ", to: "ㅘ" }
      
      # 겹받침 분해
      - { from: "ㄳ", to: "ㄱ" }
```

- **from**: 현재 상태
- **to**: 백스페이스 후 상태 (null이면 완전 삭제)

## 특수문자 오토마타 (specialCharacter)

```yaml
  specialCharacter:
    transitions:
      - { from: "", input: ".,?!", to: "." }
      - { from: ".", input: ".,?!", to: "," }
      - { from: ",", input: ".,?!", to: "?" }
      - { from: "?", input: ".,?!", to: "!" }
    
    display:
      ".": "."
      ",": ","
      "?": "?"
      "!": "!"
```

특수문자 입력 시의 오토마타를 정의합니다. `isNonKorean`이 `true`인 키에 대해서만 적용됩니다.
천지인의 마침표 순환 입력처럼 한글 영역 밖의 문자에도 오토마타를 정의할 수 있습니다.

## 유니코드 참조

### 초성 (U+1100-U+115F)
- ㄱ: `\u1100` (ᄀ)
- ㄲ: `\u1101` (ᄁ)
- ㄴ: `\u1102` (ᄂ)
- ㄷ: `\u1103` (ᄃ)
- ㄸ: `\u1104` (ᄄ)
- ㄹ: `\u1105` (ᄅ)
- ㅁ: `\u1106` (ᄆ)
- ㅂ: `\u1107` (ᄇ)
- ㅃ: `\u1108` (ᄈ)
- ㅅ: `\u1109` (ᄉ)
- ㅆ: `\u110A` (ᄊ)
- ㅇ: `\u110B` (ᄋ)
- ㅈ: `\u110C` (ᄌ)
- ㅉ: `\u110D` (ᄍ)
- ㅊ: `\u110E` (ᄎ)
- ㅋ: `\u110F` (ᄏ)
- ㅌ: `\u1110` (ᄐ)
- ㅍ: `\u1111` (ᄑ)
- ㅎ: `\u1112` (ᄒ)

### 중성 (U+1161-U+11A7)
- ㅏ: `\u1161` (ᅡ)
- ㅐ: `\u1162` (ᅢ)
- ㅑ: `\u1163` (ᅣ)
- ㅒ: `\u1164` (ᅤ)
- ㅓ: `\u1165` (ᅥ)
- ㅔ: `\u1166` (ᅦ)
- ㅕ: `\u1167` (ᅧ)
- ㅖ: `\u1168` (ᅨ)
- ㅗ: `\u1169` (ᅩ)
- ㅘ: `\u116A` (ᅪ)
- ㅙ: `\u116B` (ᅫ)
- ㅚ: `\u116C` (ᅬ)
- ㅛ: `\u116D` (ᅭ)
- ㅜ: `\u116E` (ᅮ)
- ㅝ: `\u116F` (ᅯ)
- ㅞ: `\u1170` (ᅰ)
- ㅟ: `\u1171` (ᅱ)
- ㅠ: `\u1172` (ᅲ)
- ㅡ: `\u1173` (ᅳ)
- ㅢ: `\u1174` (ᅴ)
- ㅣ: `\u1175` (ᅵ)

#### 특수 중성 (천지인용)
- ㆍ: `\u119E` (ᆞ)
- ᆢ: `\u11A2` (ᆢ)

### 종성 (U+11A8-U+11FF)
- ㄱ: `\u11A8` (ᆨ)
- ㄲ: `\u11A9` (ᆩ)
- ㄳ: `\u11AA` (ᆪ)
- ㄴ: `\u11AB` (ᆫ)
- ㄵ: `\u11AC` (ᆬ)
- ㄶ: `\u11AD` (ᆭ)
- ㄷ: `\u11AE` (ᆮ)
- ㄹ: `\u11AF` (ᆯ)
- ㄺ: `\u11B0` (ᆰ)
- ㄻ: `\u11B1` (ᆱ)
- ㄼ: `\u11B2` (ᆲ)
- ㄽ: `\u11B3` (ᆳ)
- ㄾ: `\u11B4` (ᆴ)
- ㄿ: `\u11B5` (ᆵ)
- ㅀ: `\u11B6` (ᆶ)
- ㅁ: `\u11B7` (ᆷ)
- ㅂ: `\u11B8` (ᆸ)
- ㅄ: `\u11B9` (ᆹ)
- ㅅ: `\u11BA` (ᆺ)
- ㅆ: `\u11BB` (ᆻ)
- ㅇ: `\u11BC` (ᆼ)
- ㅈ: `\u11BD` (ᆽ)
- ㅊ: `\u11BE` (ᆾ)
- ㅋ: `\u11BF` (ᆿ)
- ㅌ: `\u11C0` (ᇀ)
- ㅍ: `\u11C1` (ᇁ)
- ㅎ: `\u11C2` (ᇂ)

## 작성 팁

1. **상태 이름**: 실제 한글 자모를 사용 (예: "ㄱ", "ㅏ")
2. **초기 상태**: 빈 문자열 ""로 표현
3. **전이 순서**: 단순한 것부터 복잡한 것 순으로 정의
4. **중간 상태**: 천지인처럼 특수한 중간 상태가 필요한 경우 별도 정의 (예: "ㄴㅅ", "ㄹㅇ")
5. **주석**: YAML 주석(#)을 활용하여 규칙 설명 추가
6. **테스트**: 작성한 YAML로 실제 입력 테스트를 수행하여 의도대로 동작하는지 확인

## 예시 참고

- [표준 두벌식](Sources/MetaHangulIME/Resources/IMEConfigurations/standard-dubeolsik.yaml)
- [천지인](Sources/MetaHangulIME/Resources/IMEConfigurations/cheonjiin.yaml)
- [천지인 플러스](Sources/MetaHangulIME/Resources/IMEConfigurations/cheonjiin-plus.yaml)