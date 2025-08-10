//
//  ConfigurationTests.swift
//  MetaHangulIME
//
//  IME 설정 로딩 테스트
//

import XCTest
@testable import MetaHangulIME

final class ConfigurationTests: XCTestCase {
    // MARK: - Model Tests

    func testIMEConfigurationDecoding() throws {
        let yamlString = """
        name: "Test IME"
        identifier: "test-ime"
        config:
          orderMode: "sequential"
          jamoCommitPolicy: "syllable"
          nonJamoCommitPolicy: "onComplete"
          transitionCommitPolicy: "always"
          displayMode: "modernMultiple"
          supportStandaloneCluster: false
        layout:
          a: { identifier: "ㄱ", label: "ㄱ" }
          b: { identifier: "ㄴ", label: "ㄴ", isNonJamo: true }
        automata:
          choseong:
            transitions:
            - { from: "", input: "ㄱ", to: "ㄱ" }
            display:
              "ㄱ": "\\u1100"
        """

        let configuration = try IMEConfigurationLoader.load(from: yamlString)

        XCTAssertEqual(configuration.name, "Test IME")
        XCTAssertEqual(configuration.identifier, "test-ime")
        XCTAssertEqual(configuration.config.orderMode, "sequential")
        XCTAssertEqual(configuration.layout.count, 2)
        XCTAssertEqual(configuration.layout["a"]?.identifier, "ㄱ")
        XCTAssertEqual(configuration.layout["b"]?.isNonJamo, true)
        XCTAssertNotNil(configuration.automata.choseong)
        XCTAssertEqual(configuration.automata.choseong?.transitions.count, 1)
    }

    func testProcessorConfigConversion() throws {
        let config = ProcessorConfig(
          orderMode: "sequential",
          jamoCommitPolicy: "syllable",
          nonJamoCommitPolicy: "onComplete",
          transitionCommitPolicy: "always",
          displayMode: "modernMultiple",
          supportStandaloneCluster: false
        )

        let processorConfig = try config.toInputProcessorConfig()

        XCTAssertEqual(processorConfig.orderMode, .sequential)
        XCTAssertEqual(processorConfig.jamoCommitPolicy, .syllable)
        XCTAssertEqual(processorConfig.nonJamoCommitPolicy, .onComplete)
        XCTAssertEqual(processorConfig.transitionCommitPolicy, .always)
        XCTAssertEqual(processorConfig.displayMode, .modernMultiple)
        XCTAssertFalse(processorConfig.supportStandaloneCluster)
    }

    func testInvalidProcessorConfig() {
        let invalidConfigs = [
            ProcessorConfig(
                orderMode: "invalid",
                jamoCommitPolicy: "syllable",
                nonJamoCommitPolicy: "onComplete",
                transitionCommitPolicy: "always",
                displayMode: "modernMultiple",
                supportStandaloneCluster: false
            ),
            ProcessorConfig(
                orderMode: "sequential",
                jamoCommitPolicy: "invalid",
                nonJamoCommitPolicy: "onComplete",
                transitionCommitPolicy: "always",
                displayMode: "modernMultiple",
                supportStandaloneCluster: false
            ),
            ProcessorConfig(
                orderMode: "sequential",
                jamoCommitPolicy: "syllable",
                nonJamoCommitPolicy: "onComplete",
                transitionCommitPolicy: "always",
                displayMode: "invalid",
                supportStandaloneCluster: false
            ),
        ]

        for config in invalidConfigs {
          XCTAssertThrowsError(try config.toInputProcessorConfig())
        }
    }

    // MARK: - Loader Tests

    func testLoadFromValidYAML() throws {
        let yamlString = """
        name: "Test"
        identifier: "test"
        config:
          orderMode: "sequential"
          jamoCommitPolicy: "syllable"
          nonJamoCommitPolicy: "onComplete"
          transitionCommitPolicy: "always"
          displayMode: "modernMultiple"
          supportStandaloneCluster: false
        layout:
          a: { identifier: "ㄱ", label: "ㄱ" }
        automata:
          choseong:
            transitions: []
            display: {}
        """

        let configuration = try IMEConfigurationLoader.load(from: yamlString)
        XCTAssertEqual(configuration.name, "Test")
    }

    func testLoadFromInvalidYAML() {
        let invalidYAML = "{ invalid yaml content"

        XCTAssertThrowsError(try IMEConfigurationLoader.load(from: invalidYAML)) { error in
          XCTAssertTrue(error is ConfigurationError)
          if let configError = error as? ConfigurationError {
            XCTAssertEqual(configError.localizedDescription, "Invalid YAML format")
          }
        }
    }

    func testConfigurationValidation() {
        // Valid configuration
        let validYAML = """
        name: "Valid IME"
        identifier: "valid-ime"
        config:
          orderMode: "sequential"
          jamoCommitPolicy: "syllable"
          nonJamoCommitPolicy: "onComplete"
          transitionCommitPolicy: "always"
          displayMode: "modernMultiple"
          supportStandaloneCluster: false
        layout:
          a: { identifier: "ㄱ", label: "ㄱ" }
        automata:
          choseong:
            transitions: []
            display: {}
        """

        if let validConfig = try? IMEConfigurationLoader.load(from: validYAML) {
          XCTAssertTrue(IMEConfigurationLoader.validate(validConfig))
        }

        // Invalid configurations
        let invalidConfigs = [
          // Missing name
          """
          name: ""
          identifier: "test"
          config:
            orderMode: "sequential"
            jamoCommitPolicy: "syllable"
          nonJamoCommitPolicy: "onComplete"
          transitionCommitPolicy: "always"
            displayMode: "modernMultiple"
            supportStandaloneCluster: false
          layout:
            a: { identifier: "ㄱ", label: "ㄱ" }
          automata:
            choseong:
              transitions: []
              display: {}
          """,
          // Empty layout
          """
          name: "Test"
          identifier: "test"
          config:
            orderMode: "sequential"
            jamoCommitPolicy: "syllable"
          nonJamoCommitPolicy: "onComplete"
          transitionCommitPolicy: "always"
            displayMode: "modernMultiple"
            supportStandaloneCluster: false
          layout: {}
          automata:
            choseong:
              transitions: []
              display: {}
          """,
          // No automata
          """
          name: "Test"
          identifier: "test"
          config:
            orderMode: "sequential"
            jamoCommitPolicy: "syllable"
          nonJamoCommitPolicy: "onComplete"
          transitionCommitPolicy: "always"
            displayMode: "modernMultiple"
            supportStandaloneCluster: false
          layout:
            a: { identifier: "ㄱ", label: "ㄱ" }
          automata: {}
          """,
        ]

        for yamlString in invalidConfigs {
          if let config = try? IMEConfigurationLoader.load(from: yamlString) {
            XCTAssertFalse(IMEConfigurationLoader.validate(config))
          }
        }
    }

    // MARK: - Factory Tests

    func testFactoryCreateFromConfiguration() throws {
        let yamlString = """
        name: "Test IME"
        identifier: "test-ime"
        config:
          orderMode: "sequential"
          jamoCommitPolicy: "syllable"
          nonJamoCommitPolicy: "onComplete"
          transitionCommitPolicy: "always"
          displayMode: "modernMultiple"
          supportStandaloneCluster: false
        layout:
          a: { identifier: "ㄱ", label: "ㄱ" }
          b: { identifier: "ㅏ", label: "ㅏ" }
        automata:
          choseong:
            transitions:
            - { from: "", input: "ㄱ", to: "ㄱ" }
            display:
              "ㄱ": "\\u1100"
          jungseong:
            transitions:
            - { from: "", input: "ㅏ", to: "ㅏ" }
            display:
              "ㅏ": "\\u1161"
          jongseong:
            transitions: []
            display: {}
        """

        let configuration = try IMEConfigurationLoader.load(from: yamlString)
        let ime = try IMEFactory.create(from: configuration)

        XCTAssertNotNil(ime)
        XCTAssertTrue(ime is ConfigurableKoreanIME)

        if let configurableIME = ime as? ConfigurableKoreanIME {
          XCTAssertEqual(configurableIME.name, "Test IME")
          XCTAssertEqual(configurableIME.identifier, "test-ime")
        }

        // Test that the layout was created correctly
        XCTAssertEqual(ime.layout.count, 2)
        XCTAssertEqual(ime.layout["a"]?.keyIdentifier, "ㄱ")
        XCTAssertEqual(ime.layout["b"]?.keyIdentifier, "ㅏ")
    }

    func testFactoryWithComplexAutomata() throws {
        let yamlString = """
        name: "Complex IME"
        identifier: "complex-ime"
        config:
          orderMode: "sequential"
          jamoCommitPolicy: "explicitCommit"
          nonJamoCommitPolicy: "onComplete"
          transitionCommitPolicy: "always"
          displayMode: "modernMultiple"
          supportStandaloneCluster: true
        layout:
          a: { identifier: "ㄱ", label: "ㄱ" }
          b: { identifier: "ㅏ", label: "ㅏ" }
          c: { identifier: ".", label: ".", isNonJamo: true }
        automata:
          choseong:
            transitions:
            - { from: "", input: "ㄱ", to: "ㄱ" }
            - { from: "ㄱ", input: "ㄱ", to: "ㄲ" }
            display:
              "ㄱ": "\\u1100"
              "ㄲ": "\\u1101"
          jungseong:
            transitions:
            - { from: "", input: "ㅏ", to: "ㅏ" }
            display:
              "ㅏ": "\\u1161"
          jongseong:
            transitions:
            - { from: "", input: "ㄱ", to: "ㄱ" }
            display:
              "ㄱ": "\\u11A8"
          dokkaebibul:
            transitions:
            - { jongseong: "ㄱ", remaining: null, moved: "ㄱ" }
          backspace:
            transitions:
            - { from: "ㄲ", to: "ㄱ" }
          specialCharacter:
            transitions:
            - { from: "", input: ".", to: "." }
            display:
              ".": "."
        """

        let configuration = try IMEConfigurationLoader.load(from: yamlString)
        let ime = try IMEFactory.create(from: configuration)

        // Test basic functionality
        _ = ime.input("a")  // ㄱ
        _ = ime.input("b")  // ㅏ
        let output = ime.forceCommit()
        XCTAssertEqual(output, "가")
    }
}

// MARK: - Integration Tests

extension ConfigurationTests {
    func testCheonJiInConfiguration() throws {
        // Since we can't access bundle resources in tests, we'll create a minimal CheonJiIn config
        let minimalCheonJiIn = """
        name: "천지인"
        identifier: "cheonjiin"
        config:
          orderMode: "sequential"
          jamoCommitPolicy: "explicitCommit"
          nonJamoCommitPolicy: "onComplete"
          transitionCommitPolicy: "always"
          displayMode: "modernMultiple"
          supportStandaloneCluster: true
        layout:
          q: { identifier: "ㄱ", label: "ㄱ" }
          "1": { identifier: "ㅣ", label: "ㅣ" }
        automata:
          choseong:
            transitions:
            - { from: "", input: "ㄱ", to: "ㄱ" }
            display:
              "ㄱ": "\\u1100"
          jungseong:
            transitions:
            - { from: "", input: "ㅣ", to: "ㅣ" }
            display:
              "ㅣ": "\\u1175"
          jongseong:
            transitions: []
            display: {}
        """

        let configuration = try IMEConfigurationLoader.load(from: minimalCheonJiIn)
        let ime = try IMEFactory.create(from: configuration)

        // Test basic input
        _ = ime.input("q")  // ㄱ
        _ = ime.input("1")  // ㅣ
        let output = ime.forceCommit()
        XCTAssertEqual(output, "기")
    }
}
