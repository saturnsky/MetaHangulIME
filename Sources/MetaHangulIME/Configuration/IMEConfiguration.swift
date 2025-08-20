//
//  IMEConfiguration.swift
//  MetaHangulIME
//
//  IME 설정을 위한 데이터 모델
//

import Foundation

/// IME 설정의 최상위 구조
public struct IMEConfiguration: Codable {
    public let name: String
    public let identifier: String
    public let config: ProcessorConfig
    public let layout: [String: KeyDefinition]
    public let automata: AutomataDefinition
}

/// 프로세서 설정
public struct ProcessorConfig: Codable {
    public let orderMode: String
    public let jamoCommitPolicy: String
    public let nonJamoCommitPolicy: String
    public let transitionCommitPolicy: String
    public let displayMode: String
    public let supportStandaloneCluster: Bool
    public let newSyllableOrder: [String]?

    private enum CodingKeys: String, CodingKey {
        case orderMode
        case jamoCommitPolicy
        case nonJamoCommitPolicy
        case transitionCommitPolicy
        case displayMode
        case supportStandaloneCluster
        case newSyllableOrder
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        orderMode = try container.decode(String.self, forKey: .orderMode)
        jamoCommitPolicy = try container.decode(String.self, forKey: .jamoCommitPolicy)
        nonJamoCommitPolicy = try container.decode(String.self, forKey: .nonJamoCommitPolicy)
        transitionCommitPolicy = try container.decode(String.self, forKey: .transitionCommitPolicy)
        displayMode = try container.decode(String.self, forKey: .displayMode)
        supportStandaloneCluster = try container.decode(Bool.self, forKey: .supportStandaloneCluster)
        newSyllableOrder = try container.decodeIfPresent([String].self, forKey: .newSyllableOrder)
    }
}

/// 키 정의
public struct KeyDefinition: Codable {
    public let identifier: String
    public let label: String
}

/// 오토마타 정의
public struct AutomataDefinition: Codable {
    public let choseong: AutomatonDefinition?
    public let jungseong: AutomatonDefinition?
    public let jongseong: AutomatonDefinition?
    public let dokkaebibul: DokkaebiDefinition?
    public let backspace: BackspaceDefinition?
    public let nonJamo: NonJamoDefinition?
}

/// 일반 오토마타 정의 (초성, 중성, 종성)
public struct AutomatonDefinition: Codable {
    public let transitions: [TransitionDefinition]
    public let display: [String: String]
}

/// 전이 정의
public struct TransitionDefinition: Codable {
    public let from: String
    public let input: String
    public let to: String
    public let switchTo: String?
}

/// 도깨비불 오토마타 정의
public struct DokkaebiDefinition: Codable {
    /// 중성-도깨비불 전이
    public let jungseongTransitions: [DokkaebiTransition]?
    /// 초성-도깨비불 전이
    public let choseongTransitions: [ChoseongDokkaebiTransition]?
}

/// 중성-도깨비불 전이
public struct DokkaebiTransition: Codable {
    public let jongseong: String
    public let remaining: String?
    public let moved: String
}

/// 초성-도깨비불 전이
public struct ChoseongDokkaebiTransition: Codable {
    public let jongseong: String
    public let inputKey: String
    public let remaining: String?
    public let moved: String
}

/// 백스페이스 오토마타 정의
public struct BackspaceDefinition: Codable {
    public let transitions: [BackspaceTransition]
}

/// 백스페이스 전이
public struct BackspaceTransition: Codable {
    public let from: String
    public let to: String
}

/// 비자모 오토마타 정의
public struct NonJamoDefinition: Codable {
    public let transitions: [TransitionDefinition]
    public let display: [String: String]
}

// MARK: - 검증 확장

extension ProcessorConfig {
    /// 설정 값을 Enum으로 변환
    public func toInputProcessorConfig() throws -> InputProcessorConfig {
        guard let orderMode = OrderMode.from(string: orderMode) else {
            throw ConfigurationError.invalidOrderMode(orderMode)
        }

        guard let jamoCommitPolicy = JamoCommitPolicy.from(string: jamoCommitPolicy) else {
            throw ConfigurationError.invalidJamoCommitPolicy(jamoCommitPolicy)
        }

        guard let nonJamoCommitPolicy = NonJamoCommitPolicy.from(string: nonJamoCommitPolicy) else {
            throw ConfigurationError.invalidNonJamoCommitPolicy(nonJamoCommitPolicy)
        }

        guard let transitionCommitPolicy = TransitionCommitPolicy.from(string: transitionCommitPolicy) else {
            throw ConfigurationError.invalidTransitionCommitPolicy(transitionCommitPolicy)
        }

        guard let displayMode = DisplayMode.from(string: displayMode) else {
            throw ConfigurationError.invalidDisplayMode(displayMode)
        }

        // newSyllableOrder 파싱 - 없으면 기본값 사용
        let syllableOrder: [JamoPosition]
        if let orderStrings = newSyllableOrder {
            syllableOrder = try JamoPosition.parseOrder(from: orderStrings)
        } else {
            // 기본값: 초성-중성-종성
            syllableOrder = [.choseong, .jungseong, .jongseong]
        }

        return InputProcessorConfig(
            orderMode: orderMode,
            jamoCommitPolicy: jamoCommitPolicy,
            nonJamoCommitPolicy: nonJamoCommitPolicy,
            transitionCommitPolicy: transitionCommitPolicy,
            displayMode: displayMode,
            supportStandaloneCluster: supportStandaloneCluster,
            newSyllableOrder: syllableOrder
        )
    }
}

// MARK: - 에러 정의

public enum ConfigurationError: LocalizedError {
    case invalidOrderMode(String)
    case invalidJamoCommitPolicy(String)
    case invalidNonJamoCommitPolicy(String)
    case invalidTransitionCommitPolicy(String)
    case invalidDisplayMode(String)
    case invalidYAML
    case fileNotFound(String)
    case invalidJamoPosition(String)

    public var errorDescription: String? {
        switch self {
        case .invalidOrderMode(let mode):
            return "Invalid order mode: \(mode). Expected: sequential, freeOrder"
        case .invalidJamoCommitPolicy(let policy):
            return "Invalid jamo commit policy: \(policy). Expected: syllable, explicitCommit"
        case .invalidNonJamoCommitPolicy(let policy):
            return "Invalid non-jamo commit policy: \(policy). Expected: character, explicitCommit, onComplete"
        case .invalidTransitionCommitPolicy(let policy):
            return "Invalid transition commit policy: \(policy). Expected: never, always"
        case .invalidDisplayMode(let mode):
            return "Invalid display mode: \(mode). Expected: archaic, modernMultiple, modernPartial"
        case .invalidYAML:
            return "Invalid YAML format"
        case .fileNotFound(let filename):
            return "Configuration file not found: \(filename)"
        case .invalidJamoPosition(let position):
            return "Invalid jamo position: \(position). Expected: choseong, jungseong, jongseong"
        }
    }
}

// MARK: - Enum 문자열 변환 확장

extension OrderMode {
    static func from(string: String) -> OrderMode? {
        switch string {
        case "sequential": return .sequential
        case "freeOrder": return .freeOrder
        default: return nil
        }
    }
}

extension JamoCommitPolicy {
    static func from(string: String) -> JamoCommitPolicy? {
        switch string {
        case "syllable": return .syllable
        case "explicitCommit": return .explicitCommit
        default: return nil
        }
    }
}

extension NonJamoCommitPolicy {
    static func from(string: String) -> NonJamoCommitPolicy? {
        switch string {
        case "character": return .character
        case "explicitCommit": return .explicitCommit
        case "onComplete": return .onComplete
        default: return nil
        }
    }
}

extension TransitionCommitPolicy {
    static func from(string: String) -> TransitionCommitPolicy? {
        switch string {
        case "never": return .never
        case "always": return .always
        default: return nil
        }
    }
}

extension DisplayMode {
    static func from(string: String) -> DisplayMode? {
        switch string {
        case "archaic": return .archaic
        case "modernMultiple": return .modernMultiple
        case "modernPartial": return .modernPartial
        default: return nil
        }
    }
}
