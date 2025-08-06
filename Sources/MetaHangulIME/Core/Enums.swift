//
//  Enums.swift
//  MetaHangulIME
//
//  메타 한글 IME 프레임워크의 Enum 정의
//

import Foundation

/// JamoPosition: 한국어 음절에서 낱자의 위치
public enum JamoPosition: Int, CaseIterable {
    case choseong = 0   // 초성 (초성)
    case jungseong = 1  // 중성 (모음)
    case jongseong = 2  // 종성 (받침)
}

/// OrderMode: 낱자 조합 순서
public enum OrderMode: Int {
    case sequential = 0  // 초성 → 중성 → 종성 순서를 따라야 함
    case freeOrder = 1   // 낱자를 어떤 순서로도 입력 가능
}

/// CommitUnit: 텍스트 입력의 커밋 단위
public enum CommitUnit: Int {
    case syllable = 0       // 완성된 음절을 자동으로 커밋
    case explicitCommit = 1 // 수동 커밋 필요. 특수 문자 입력시는 자동 커밋
}

/// DisplayMode: 불완전한 음절의 표시 모드
public enum DisplayMode: Int {
    case archaic = 0        // 현대 한글로 조합되지 않는 음절은 NFD를 사용해서 표시
    case modernMultiple = 1 // 조합할 수 없는 자모를 별도 음절로 풀어서 표시
    case modernPartial = 2  // 첫 음절에서 표시 가능한 부분까지만 표시
}
