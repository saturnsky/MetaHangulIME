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
    public let commitUnit: String
    public let displayMode: String
    public let supportStandaloneCluster: Bool
}

/// 키 정의
public struct KeyDefinition: Codable {
    public let identifier: String
    public let label: String
    public let isNonKorean: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case identifier
        case label
        case isNonKorean
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        label = try container.decode(String.self, forKey: .label)
        isNonKorean = try container.decodeIfPresent(Bool.self, forKey: .isNonKorean)
    }
}

/// 오토마타 정의
public struct AutomataDefinition: Codable {
    public let choseong: AutomatonDefinition?
    public let jungseong: AutomatonDefinition?
    public let jongseong: AutomatonDefinition?
    public let dokkaebibul: DokkaebiDefinition?
    public let backspace: BackspaceDefinition?
    public let specialCharacter: SpecialCharacterDefinition?
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
}

/// 도깨비불 오토마타 정의
public struct DokkaebiDefinition: Codable {
    public let transitions: [DokkaebiTransition]
}

/// 도깨비불 전이
public struct DokkaebiTransition: Codable {
    public let jongseong: String
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

/// 특수문자 오토마타 정의
public struct SpecialCharacterDefinition: Codable {
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
        
        guard let commitUnit = CommitUnit.from(string: commitUnit) else {
            throw ConfigurationError.invalidCommitUnit(commitUnit)
        }
        
        guard let displayMode = DisplayMode.from(string: displayMode) else {
            throw ConfigurationError.invalidDisplayMode(displayMode)
        }
        
        return InputProcessorConfig(
            orderMode: orderMode,
            commitUnit: commitUnit,
            displayMode: displayMode,
            supportStandaloneCluster: supportStandaloneCluster
        )
    }
}

// MARK: - 에러 정의

public enum ConfigurationError: LocalizedError {
    case invalidOrderMode(String)
    case invalidCommitUnit(String)
    case invalidDisplayMode(String)
    case invalidYAML
    case fileNotFound(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidOrderMode(let mode):
            return "Invalid order mode: \(mode). Expected: sequential, freeOrder"
        case .invalidCommitUnit(let unit):
            return "Invalid commit unit: \(unit). Expected: syllable, explicitCommit"
        case .invalidDisplayMode(let mode):
            return "Invalid display mode: \(mode). Expected: archaic, modernMultiple, modernPartial"
        case .invalidYAML:
            return "Invalid YAML format"
        case .fileNotFound(let filename):
            return "Configuration file not found: \(filename)"
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

extension CommitUnit {
    static func from(string: String) -> CommitUnit? {
        switch string {
        case "syllable": return .syllable
        case "explicitCommit": return .explicitCommit
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