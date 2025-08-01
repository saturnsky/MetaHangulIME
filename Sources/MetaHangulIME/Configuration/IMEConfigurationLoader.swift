//
//  IMEConfigurationLoader.swift
//  MetaHangulIME
//
//  YAML 파일로부터 IME 설정을 로드하는 클래스
//

import Foundation
import Yams

/// IME 설정 로더
public class IMEConfigurationLoader {
    
    /// 파일 URL로부터 IME 설정 로드
    /// - Parameter fileURL: YAML 파일의 URL
    /// - Returns: 파싱된 IME 설정
    /// - Throws: 파일 읽기 또는 파싱 에러
    public static func load(from fileURL: URL) throws -> IMEConfiguration {
        let yamlString = try String(contentsOf: fileURL, encoding: .utf8)
        return try load(from: yamlString)
    }
    
    /// YAML 문자열로부터 IME 설정 로드
    /// - Parameter yamlString: YAML 형식의 문자열
    /// - Returns: 파싱된 IME 설정
    /// - Throws: 파싱 에러
    public static func load(from yamlString: String) throws -> IMEConfiguration {
        do {
            let decoder = YAMLDecoder()
            return try decoder.decode(IMEConfiguration.self, from: yamlString)
        } catch {
            throw ConfigurationError.invalidYAML
        }
    }
    
    /// 번들에 포함된 IME 설정 로드
    /// - Parameter name: 파일 이름 (확장자 제외)
    /// - Returns: 파싱된 IME 설정
    /// - Throws: 파일을 찾을 수 없거나 파싱 에러
    public static func loadBundled(named name: String) throws -> IMEConfiguration {
        #if SWIFT_PACKAGE
        // SPM을 통해 설치된 경우
        guard let url = Bundle.module.url(forResource: name, withExtension: "yaml", subdirectory: "IMEConfigurations") else {
            throw ConfigurationError.fileNotFound("\(name).yaml")
        }
        #else
        // 프레임워크나 직접 통합된 경우
        let bundle = Bundle(for: Self.self)
        guard let url = bundle.url(forResource: name, withExtension: "yaml", subdirectory: "IMEConfigurations") else {
            throw ConfigurationError.fileNotFound("\(name).yaml")
        }
        #endif
        
        return try load(from: url)
    }
    
    /// 메인 번들에서 IME 설정 로드 (앱에서 사용)
    /// - Parameter name: 파일 이름 (확장자 제외)
    /// - Returns: 파싱된 IME 설정
    /// - Throws: 파일을 찾을 수 없거나 파싱 에러
    public static func loadFromMainBundle(named name: String) throws -> IMEConfiguration {
        guard let url = Bundle.main.url(forResource: name, withExtension: "yaml") else {
            throw ConfigurationError.fileNotFound("\(name).yaml")
        }
        
        return try load(from: url)
    }
    
    /// 설정 검증
    /// - Parameter configuration: 검증할 IME 설정
    /// - Returns: 검증 성공 여부
    public static func validate(_ configuration: IMEConfiguration) -> Bool {
        // 기본 검증 로직
        
        // 필수 필드 검증
        guard !configuration.name.isEmpty,
              !configuration.identifier.isEmpty else {
            return false
        }
        
        // 레이아웃 검증
        guard !configuration.layout.isEmpty else {
            return false
        }
        
        // 프로세서 설정 검증
        do {
            _ = try configuration.config.toInputProcessorConfig()
        } catch {
            return false
        }
        
        // 오토마타 검증 (최소한 하나의 오토마타는 있어야 함)
        let hasAutomata = configuration.automata.choseong != nil ||
                         configuration.automata.jungseong != nil ||
                         configuration.automata.jongseong != nil
        
        return hasAutomata
    }
}

// MARK: - 프리셋 설정

extension IMEConfigurationLoader {
    /// 사용 가능한 프리셋 IME
    public enum Preset: String, CaseIterable {
        case standardDubeolsik = "standard-dubeolsik"
        case sebeolsikFinal = "sebeolsik-final"
        case cheonJiIn = "cheonjiin"
        case cheonJiInPlus = "cheonjiin-plus"
        
        public var displayName: String {
            switch self {
            case .standardDubeolsik: return "표준 두벌식"
            case .sebeolsikFinal: return "세벌식 최종"
            case .cheonJiIn: return "천지인"
            case .cheonJiInPlus: return "천지인 플러스"
            }
        }
    }
    
    /// 프리셋 IME 설정 로드
    /// - Parameter preset: 프리셋 타입
    /// - Returns: 파싱된 IME 설정
    /// - Throws: 파일을 찾을 수 없거나 파싱 에러
    public static func loadPreset(_ preset: Preset) throws -> IMEConfiguration {
        return try loadBundled(named: preset.rawValue)
    }
}