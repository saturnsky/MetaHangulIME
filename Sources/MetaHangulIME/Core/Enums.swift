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

    /// 문자열 배열을 JamoPosition 배열로 변환
    public static func parseOrder(from strings: [String]) throws -> [JamoPosition] {
        var result: [JamoPosition] = []
        var seenPositions: Set<JamoPosition> = []

        for string in strings {
            guard let position = JamoPosition.from(string: string) else {
                throw ConfigurationError.invalidJamoPosition(string)
            }

            // 중복 체크
            if seenPositions.contains(position) {
                throw ConfigurationError.invalidJamoPosition("Duplicate position: \(string)")
            }

            result.append(position)
            seenPositions.insert(position)
        }

        // 모든 위치가 포함되어야 함
        if result.count != 3 {
            throw ConfigurationError.invalidJamoPosition(
                "All three positions (choseong, jungseong, jongseong) must be specified"
            )
        }

        return result
    }

    /// 문자열을 JamoPosition으로 변환
    private static func from(string: String) -> JamoPosition? {
        switch string {
        case "choseong": return .choseong
        case "jungseong": return .jungseong
        case "jongseong": return .jongseong
        default: return nil
        }
    }
}

/// OrderMode: 낱자 조합 순서
public enum OrderMode: Int {
    case sequential = 0  // 초성 → 중성 → 종성 순서를 따라야 함
    case freeOrder = 1   // 낱자를 어떤 순서로도 입력 가능
}

/// JamoCommitPolicy: 한글 자모 입력의 커밋 정책
public enum JamoCommitPolicy: Int {
    case syllable = 0       // 완성된 음절을 자동으로 커밋
    case explicitCommit = 1 // 수동 커밋 필요
}

/// NonJamoCommitPolicy: 비자모 문자 입력의 커밋 정책
public enum NonJamoCommitPolicy: Int {
    case character = 0      // 다음 문자로 넘어갈 때 자동으로 커밋
    case explicitCommit = 1 // 수동 커밋 필요
    case onComplete = 2     // 오토마타의 전이가 완료되면 자동 커밋
}

/// TransitionCommitPolicy: 한글↔비한글 전환 시 커밋 정책
public enum TransitionCommitPolicy: Int {
    case never = 0   // 전환 시 커밋하지 않음
    case always = 1  // 전환 시 항상 커밋
}

/// DisplayMode: 불완전한 음절의 표시 모드
public enum DisplayMode: Int {
    case archaic = 0        // 현대 한글로 조합되지 않는 음절은 NFD를 사용해서 표시
    case modernMultiple = 1 // 조합할 수 없는 자모를 별도 음절로 풀어서 표시
    case modernPartial = 2  // 첫 음절에서 표시 가능한 부분까지만 표시
}
