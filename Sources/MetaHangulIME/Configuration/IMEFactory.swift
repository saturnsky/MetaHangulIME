//
//  IMEFactory.swift
//  MetaHangulIME
//
//  설정으로부터 IME 인스턴스를 생성하는 팩토리 클래스
//

import Foundation

/// IME 팩토리
public enum IMEFactory {
    /// 설정으로부터 IME 생성
    /// - Parameter configuration: IME 설정
    /// - Returns: 생성된 KoreanIME 인스턴스
    /// - Throws: 설정 변환 에러
    public static func create(from configuration: IMEConfiguration) throws -> KoreanIME {
        // 프로세서 설정 변환
        let processorConfig = try configuration.config.toInputProcessorConfig()

        // 레이아웃 생성
        let layout = createLayout(from: configuration.layout)

        // 오토마타 생성 - 필수 오토마타는 반드시 있어야 함
        guard let choseongDef = configuration.automata.choseong,
              let jungseongDef = configuration.automata.jungseong,
              let jongseongDef = configuration.automata.jongseong else {
            throw ConfigurationError.invalidYAML
        }

        let choseongAutomaton = createChoseongAutomaton(from: choseongDef)
        let jungseongAutomaton = createJungseongAutomaton(from: jungseongDef)
        let jongseongAutomaton = createJongseongAutomaton(from: jongseongDef)

        // 옵셔널 오토마타
        let dokkaebiAutomaton = configuration.automata.dokkaebibul.map { createDokkaebiAutomaton(from: $0) }
        let backspaceAutomaton = configuration.automata.backspace.map { createBackspaceAutomaton(from: $0) }
        let nonJamoAutomaton = configuration.automata.nonJamo.map { createNonJamoAutomaton(from: $0) }

        // InputProcessor 생성
        let processor = InputProcessor(
            choseongAutomaton: choseongAutomaton,
            jungseongAutomaton: jungseongAutomaton,
            jongseongAutomaton: jongseongAutomaton,
            nonJamoAutomaton: nonJamoAutomaton,
            dokkaebiAutomaton: dokkaebiAutomaton,
            backspaceAutomaton: backspaceAutomaton,
            config: processorConfig
        )

        // 동적 IME 클래스 생성
        return ConfigurableKoreanIME(
            processor: processor,
            layout: layout,
            name: configuration.name,
            identifier: configuration.identifier
        )
    }

    /// 파일로부터 IME 생성
    /// - Parameter url: YAML 파일 URL
    /// - Returns: 생성된 KoreanIME 인스턴스
    /// - Throws: 파일 읽기, 파싱 또는 설정 변환 에러
    public static func createFromFile(at url: URL) throws -> KoreanIME {
        let configuration = try IMEConfigurationLoader.load(from: url)
        return try create(from: configuration)
    }

    /// 번들 리소스로부터 IME 생성
    /// - Parameter name: 리소스 파일 이름 (확장자 제외)
    /// - Returns: 생성된 KoreanIME 인스턴스
    /// - Throws: 파일 찾기, 파싱 또는 설정 변환 에러
    public static func createFromBundled(named name: String) throws -> KoreanIME {
        let configuration = try IMEConfigurationLoader.loadBundled(named: name)
        return try create(from: configuration)
    }

    /// 프리셋으로부터 IME 생성
    /// - Parameter preset: 프리셋 타입
    /// - Returns: 생성된 KoreanIME 인스턴스
    /// - Throws: 파일 찾기, 파싱 또는 설정 변환 에러
    public static func createFromPreset(_ preset: IMEConfigurationLoader.Preset) throws -> KoreanIME {
        let configuration = try IMEConfigurationLoader.loadPreset(preset)
        return try create(from: configuration)
    }
}

// MARK: - Private Helper Methods

private extension IMEFactory {
    static func createLayout(from definitions: [String: KeyDefinition]) -> [String: VirtualKey] {
        var layout: [String: VirtualKey] = [:]

        for (key, definition) in definitions {
            layout[key] = VirtualKey(
                keyIdentifier: definition.identifier,
                label: definition.label,
                isNonJamo: definition.isNonJamo ?? false
            )
        }

        return layout
    }

    static func createChoseongAutomaton(from definition: AutomatonDefinition) -> ChoseongAutomaton {
        let automaton = ChoseongAutomaton()

        // 전이 추가
        for transition in definition.transitions {
            automaton.addTransition(
                from: transition.from,
                input: transition.input,
                to: transition.to
            )
        }

        // 표시 매핑 추가
        for (state, display) in definition.display {
            automaton.addDisplay(state: state, display: display)
        }

        return automaton
    }

    static func createJungseongAutomaton(from definition: AutomatonDefinition) -> JungseongAutomaton {
        let automaton = JungseongAutomaton()

        for transition in definition.transitions {
            automaton.addTransition(
                from: transition.from,
                input: transition.input,
                to: transition.to
            )
        }

        for (state, display) in definition.display {
            automaton.addDisplay(state: state, display: display)
        }

        return automaton
    }

    static func createJongseongAutomaton(from definition: AutomatonDefinition) -> JongseongAutomaton {
        let automaton = JongseongAutomaton()

        for transition in definition.transitions {
            automaton.addTransition(
                from: transition.from,
                input: transition.input,
                to: transition.to
            )
        }

        for (state, display) in definition.display {
            automaton.addDisplay(state: state, display: display)
        }

        return automaton
    }

    static func createDokkaebiAutomaton(from definition: DokkaebiDefinition) -> DokkaebiAutomaton {
        let automaton = DokkaebiAutomaton()

        // 중성-도깨비불 전이 로드
        if let jungseongTransitions = definition.jungseongTransitions {
            for transition in jungseongTransitions {
                automaton.addJungseongTransition(
                    jongseongState: transition.jongseong,
                    remainingJong: transition.remaining,
                    movedCho: transition.moved
                )
            }
        }

        // 초성-도깨비불 전이 로드
        if let choseongTransitions = definition.choseongTransitions {
            for transition in choseongTransitions {
                automaton.addChoseongTransition(
                    jongseongState: transition.jongseong,
                    inputKey: transition.inputKey,
                    remainingJong: transition.remaining,
                    movedCho: transition.moved
                )
            }
        }

        return automaton
    }

    static func createBackspaceAutomaton(from definition: BackspaceDefinition) -> BackspaceAutomaton {
        let automaton = BackspaceAutomaton()

        for transition in definition.transitions {
            automaton.addTransition(from: transition.from, to: transition.to)
        }

        return automaton
    }

    static func createNonJamoAutomaton(from definition: NonJamoDefinition) -> NonJamoAutomaton {
        let automaton = NonJamoAutomaton()

        for transition in definition.transitions {
            automaton.addTransition(
                from: transition.from,
                input: transition.input,
                to: transition.to
            )
        }

        for (state, display) in definition.display {
            automaton.addDisplay(state: state, display: display)
        }

        return automaton
    }
}

// MARK: - 설정 기반 IME 클래스

/// 설정으로부터 생성된 IME
public class ConfigurableKoreanIME: KoreanIME {
    public let name: String
    public let identifier: String

    public init(processor: InputProcessor, layout: [String: VirtualKey], name: String, identifier: String) {
        self.name = name
        self.identifier = identifier
        super.init(processor: processor, layout: layout)
    }
}
