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
    /// Transition table: current_state -> new_state (nil for deletion)
    /// Using dictionary for O(1) lookup
    private var transitionTable: [String: String?] = [:]

    public init() {}

    /// Add a backspace transition
    /// - Parameters:
    ///   - fromState: Current state
    ///   - toState: State after backspace (nil for complete deletion)
    public func addTransition(from fromState: String, to toState: String?) {
        transitionTable[fromState] = toState
    }

    /// Process backspace for given state
    /// - Parameter currentState: Current jamo state
    /// - Returns: BackspaceResult with new state
    public func process(_ currentState: String) -> BackspaceResult {
        // If not in transition table, default to complete deletion
        // Using if-let to properly handle String?? type from dictionary
        if let transition = transitionTable[currentState] {
            return BackspaceResult(newState: transition)
        } else {
            return BackspaceResult(newState: nil)
        }
    }

    /// Check if state has a backspace transition
    /// - Parameter state: State to check
    /// - Returns: true if state has a defined transition
    @inline(__always)
    public func hasTransition(for state: String) -> Bool {
        transitionTable[state] != nil
    }

    /// Batch add transitions for performance
    /// - Parameter transitions: Dictionary of from_state -> to_state mappings
    public func addTransitions(_ transitions: [String: String?]) {
        for (from, to) in transitions {
            transitionTable[from] = to
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
