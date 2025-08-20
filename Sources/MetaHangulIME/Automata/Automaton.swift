//
//  Automaton.swift
//  MetaHangulIME
//
//  Base automaton class for state transitions and character mapping
//

import Foundation

/// Type of automaton to switch to
public enum AutomatonType: String, CaseIterable {
    case choseong
    case jungseong
    case jongseong
    case nonJamo
}

/// Base class for all automata used in the Meta Hangul IME framework
/// An automaton manages state transitions and display mappings for jamo (Korean letters)
open class Automaton {
    /// Transition information including target state and optional switchTo automaton
    public struct TransitionInfo {
        let toState: String
        let switchTo: AutomatonType?

        public init(toState: String, switchTo: AutomatonType? = nil) {
            self.toState = toState
            self.switchTo = switchTo
        }
    }

    /// Transition table: Maps (current_state, input_key) -> TransitionInfo
    /// Using nested dictionary for O(1) lookup performance
    private var transitionTable: [String: [String: TransitionInfo]] = [:]

    /// Display table: Maps state -> Unicode character for display
    private var displayTable: [String: String] = [:]

    /// Set of all valid states for quick validation
    private var validStates: Set<String> = [""]

    public init() {}

    /// Perform state transition
    /// - Parameters:
    ///   - currentState: Current state (nil represents empty state)
    ///   - inputKey: Input key identifier
    /// - Returns: TransitionInfo if transition exists, nil otherwise
    @inline(__always)
    public func transition(currentState: String?, inputKey: String) -> TransitionInfo? {
        let state = currentState ?? ""
        return transitionTable[state]?[inputKey]
    }

    /// Get display character for a state
    /// - Parameter state: State to display
    /// - Returns: Display character or the state itself if no mapping exists
    @inline(__always)
    public func display(_ state: String) -> String {
        displayTable[state] ?? state
    }

    /// Check if a state exists in this automaton
    /// - Parameter state: State to check
    /// - Returns: true if state exists
    @inline(__always)
    public func hasState(_ state: String) -> Bool {
        validStates.contains(state)
    }

    /// Add a state transition
    /// - Parameters:
    ///   - fromState: Source state (empty string for initial state)
    ///   - inputKey: Input key that triggers transition
    ///   - toState: Destination state
    ///   - switchTo: Optional target automaton to switch to
    public func addTransition(
        from fromState: String,
        input inputKey: String,
        to toState: String,
        switchTo: AutomatonType? = nil,
    ) {
        if transitionTable[fromState] == nil {
            transitionTable[fromState] = [:]
        }
        transitionTable[fromState]?[inputKey] = TransitionInfo(toState: toState, switchTo: switchTo)

        // Track valid states
        validStates.insert(fromState)
        validStates.insert(toState)
    }

    /// Add a display mapping
    /// - Parameters:
    ///   - state: State to map
    ///   - display: Display character
    public func addDisplay(state: String, display: String) {
        displayTable[state] = display
        validStates.insert(state)
    }

    /// Batch add display mappings for performance
    /// - Parameter displays: Dictionary of state -> display mappings
    public func addDisplays(_ displays: [String: String]) {
        for (state, display) in displays {
            addDisplay(state: state, display: display)
        }
    }

    /// Check if any transition is possible from the given state
    /// - Parameter fromState: State to check transitions from
    /// - Returns: true if at least one transition exists from this state
    @inline(__always)
    public func canTransition(from fromState: String?) -> Bool {
        let state = fromState ?? ""
        guard let transitions = transitionTable[state] else { return false }
        return !transitions.isEmpty
    }
}

/// Choseong (initial consonant) automaton
public final class ChoseongAutomaton: Automaton {}

/// Jungseong (vowel) automaton
public final class JungseongAutomaton: Automaton {}

/// Jongseong (final consonant) automaton
public final class JongseongAutomaton: Automaton {}

/// Non-jamo character automaton
public final class NonJamoAutomaton: Automaton {}
