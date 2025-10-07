//
//  BackspaceAutomaton.swift
//  MetaHangulIME
//
//  Handles backspace processing for jamo decomposition
//

import Foundation

/// Result of backspace processing
public struct BackspaceResult {
    /// New state after backspace (nil means complete deletion)
    public let newState: String?

    public init(newState: String?) {
        self.newState = newState
    }
}

/// Handles backspace processing for jamo decomposition
///
/// This automaton defines how compound jamo (like ㄲ, ㅘ, ㄳ) decompose
/// when backspace is pressed, or whether they should be deleted entirely.
public class BackspaceAutomaton {
    // MARK: - Pattern Support

    /// Compiled backspace pattern
    private struct BackspacePattern {
        let fromPattern: Automaton.FromPattern
        let toPattern: Automaton.ToPattern?  // nil = complete deletion
    }

    // MARK: - Storage

    /// Tier 1: Exact match transition table: current_state -> new_state (nil for deletion)
    private var exactTransitions: [String: String?] = [:]

    /// Tier 2: Pattern match transitions
    private var patterns: [BackspacePattern] = []

    /// Temporary automaton instance for pattern parsing
    private let patternParser = Automaton()

    public init() {}

    /// Add a backspace transition
    /// - Parameters:
    ///   - fromState: Current state (supports pattern like "{:3}ㅅ")
    ///   - toState: State after backspace (nil for complete deletion, supports pattern like "{:2}")
    public func addTransition(from fromState: String, to toState: String?) {
        // Parse patterns
        let fromPattern = patternParser.parseFromPattern(fromState)
        let toPattern = toState.map { patternParser.parseToPattern($0) }

        // Check if exact match
        if fromPattern.isExact {
            // Tier 1: Exact match
            exactTransitions[fromState] = toState
        } else {
            // Tier 2: Pattern match
            patterns.append(BackspacePattern(
                fromPattern: fromPattern,
                toPattern: toPattern
            ))
        }
    }

    /// Process backspace for given state
    /// - Parameter currentState: Current jamo state
    /// - Returns: BackspaceResult with new state
    public func process(_ currentState: String) -> BackspaceResult {
        // Tier 1: Exact match
        if let transition = exactTransitions[currentState] {
            return BackspaceResult(newState: transition)
        }

        // Tier 2: Pattern match
        for pattern in patterns {
            if let captured = pattern.fromPattern.match(state: currentState) {
                let newState = pattern.toPattern?.apply(captured: captured)
                return BackspaceResult(newState: newState)
            }
        }

        // Default: complete deletion
        return BackspaceResult(newState: nil)
    }

    /// Check if state has a backspace transition
    /// - Parameter state: State to check
    /// - Returns: true if state has a defined transition
    public func hasTransition(for state: String) -> Bool {
        // Tier 1: Exact match
        if exactTransitions[state] != nil {
            return true
        }

        // Tier 2: Pattern match
        for pattern in patterns {
            if pattern.fromPattern.match(state: state) != nil {
                return true
            }
        }

        return false
    }

    /// Batch add transitions for performance
    /// - Parameter transitions: Dictionary of from_state -> to_state mappings
    public func addTransitions(_ transitions: [String: String?]) {
        for (from, to) in transitions {
            addTransition(from: from, to: to)
        }
    }
}

/// Default backspace automaton with standard Korean jamo decomposition rules
public final class DefaultBackspaceAutomaton: BackspaceAutomaton {
    override public init() {
        super.init()
        setupDefaultTransitions()
    }

    private func setupDefaultTransitions() {
        // Double consonants decompose to single
        addTransitions([
            "ㄲ": "ㄱ",
            "ㄸ": "ㄷ",
            "ㅃ": "ㅂ",
            "ㅆ": "ㅅ",
            "ㅉ": "ㅈ",
        ])

        // Compound final consonants decompose
        addTransitions([
            "ㄳ": "ㄱ",
            "ㄵ": "ㄴ",
            "ㄶ": "ㄴ",
            "ㄺ": "ㄹ",
            "ㄻ": "ㄹ",
            "ㄼ": "ㄹ",
            "ㄽ": "ㄹ",
            "ㄾ": "ㄹ",
            "ㄿ": "ㄹ",
            "ㅀ": "ㄹ",
            "ㅄ": "ㅂ",
        ])

        // Compound vowels decompose
        addTransitions([
            "ㅘ": "ㅗ",
            "ㅙ": "ㅘ",
            "ㅚ": "ㅗ",
            "ㅝ": "ㅜ",
            "ㅞ": "ㅝ",
            "ㅟ": "ㅜ",
            "ㅢ": "ㅡ",
        ])

        // Note: Single jamo without entries will return nil (complete deletion)
    }
}
