//
//  SyllableState.swift
//  MetaHangulIME
//
//  조합 중인 한국어 음절의 상태를 나타냄
//

import Foundation

/// 조합 중인 한국어 음절의 상태를 나타냄
/// 참조 의미론을 위해 class 사용 (가변 상태 관리)
public final class SyllableState {
    /// 현재 초성 상태
    public var choseongState: String?
    
    /// 현재 중성 상태
    public var jungseongState: String?
    
    /// 현재 종성 상태
    public var jongseongState: String?
    
    /// 한글이 아닌 입력을 위한 특수문자 상태
    public var specialCharacterState: String?
    
    /// 자모가 입력된 순서를 추적 (FREE_ORDER 모드용)
    /// 성능을 위해 배열 사용 (append는 평균 O(1))
    public var compositionOrder: [JamoPosition] = []
    
    public init(choseongState: String? = nil,
                jungseongState: String? = nil,
                jongseongState: String? = nil,
                specialCharacterState: String? = nil,
                compositionOrder: [JamoPosition] = []) {
        self.choseongState = choseongState
        self.jungseongState = jungseongState
        self.jongseongState = jongseongState
        self.specialCharacterState = specialCharacterState
        self.compositionOrder = compositionOrder
    }
    
    /// 상태가 완전히 비어있는지 여부
    @inline(__always)
    public var isEmpty: Bool {
        return choseongState == nil &&
               jungseongState == nil &&
               jongseongState == nil &&
               specialCharacterState == nil
    }
    
    /// 상태가 한글 자모를 포함하고 있는지 여부
    @inline(__always)
    public var hasHangul: Bool {
        return choseongState != nil ||
               jungseongState != nil ||
               jongseongState != nil
    }
    
    /// 순서 모드에 따라 자모 위치를 추가할 수 있는지 확인
    public func canAddJamo(position: JamoPosition, orderMode: OrderMode) -> Bool {
        switch orderMode {
        case .sequential:
            // 순차 모드: 엄격한 순서 적용
            switch position {
            case .choseong:
                return jungseongState == nil && jongseongState == nil
            case .jungseong:
                return jongseongState == nil
            case .jongseong:
                return true
            }
            
        case .freeOrder:
            // 자유 순서 모드: 분할 조합 확인
            if let lastIndex = compositionOrder.lastIndex(of: position) {
                // 이 위치 이후에 다른 위치가 추가되었는지 확인
                for i in (lastIndex + 1)..<compositionOrder.count {
                    if compositionOrder[i] != position {
                        return false
                    }
                }
            }
            return true
        }
    }
    
    /// 상태에 자모 추가
    public func addJamo(position: JamoPosition, state: String) {
        let isUpdate: Bool
        
        switch position {
        case .choseong:
            isUpdate = choseongState != nil
            choseongState = state
        case .jungseong:
            isUpdate = jungseongState != nil
            jungseongState = state
        case .jongseong:
            isUpdate = jongseongState != nil
            jongseongState = state
        }
        
        // 새로운 위치인 경우에만 조합 순서에 추가
        if !isUpdate {
            compositionOrder.append(position)
        }
    }
    
    /// 위치별 자모 상태 가져오기
    @inline(__always)
    public func getJamoState(for position: JamoPosition) -> String? {
        switch position {
        case .choseong: return choseongState
        case .jungseong: return jungseongState
        case .jongseong: return jongseongState
        }
    }
    
    /// 위치별 자모 상태 설정
    @inline(__always)
    public func setJamoState(for position: JamoPosition, state: String?) {
        switch position {
        case .choseong: choseongState = state
        case .jungseong: jungseongState = state
        case .jongseong: jongseongState = state
        }
    }
    
    /// 상태의 깊은 복사본 생성
    public func copy() -> SyllableState {
        return SyllableState(
            choseongState: choseongState,
            jungseongState: jungseongState,
            jongseongState: jongseongState,
            specialCharacterState: specialCharacterState,
            compositionOrder: compositionOrder
        )
    }
    
    /// 모든 상태 초기화
    public func clear() {
        choseongState = nil
        jungseongState = nil
        jongseongState = nil
        specialCharacterState = nil
        compositionOrder.removeAll(keepingCapacity: true)
    }
}


/// 디스플레이 과정에서 조합되지 않고 남은 낱자를 전달하기 위한 클래스
/// 이 클래스는 SyllableState와 달리 상태 이름이 아닌 표시 문자열을 포함
public final class SyllableDisplayState {
    /// 남은 초성
    public var remainingChoseong: String?
    /// 남은 중성
    public var remainingJungseong: String?
    /// 남은 종성
    public var remainingJongseong: String?
}