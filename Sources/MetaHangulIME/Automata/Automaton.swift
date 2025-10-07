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

    /// Part of a ToPattern
    public enum ToPart {
        case literal(String)
        case captureSlice(start: Int?, end: Int?)
    }

    /// From pattern for matching states with prefix capture
    public struct FromPattern {
        let captureMin: Int
        let captureMax: Int?
        let suffix: String
        let isExact: Bool

        /// Match a state against this pattern
        /// - Parameter state: State to match
        /// - Returns: Captured prefix if matched, nil otherwise
        func match(state: String) -> String? {
            // Suffix matching (most likely to fail early)
            guard state.hasSuffix(suffix) else { return nil }

            // Prefix length validation
            let prefixLength = state.count - suffix.count

            guard prefixLength >= captureMin else { return nil }
            if let max = captureMax, prefixLength > max { return nil }

            // Extract prefix (capture)
            if prefixLength == 0 {
                return ""
            }

            let endIndex = state.index(state.endIndex, offsetBy: -suffix.count)
            return String(state[..<endIndex])
        }
    }

    /// To pattern for generating new states with captured values
    public struct ToPattern {
        let parts: [ToPart]
        let isSimple: Bool

        /// Apply captured value to generate result state
        /// - Parameter captured: Captured prefix from FromPattern
        /// - Returns: Generated state
        func apply(captured: String) -> String {
            // Fast path: simple cases
            if isSimple {
                if case .literal(let lit) = parts[0] {
                    return lit
                }
                if case .captureSlice(nil, nil) = parts[0] {
                    return captured
                }
            }

            // General case
            var result = ""
            for part in parts {
                switch part {
                case .literal(let lit):
                    result += lit
                case .captureSlice(let start, let end):
                    result += captured.pythonSlice(start: start, end: end)
                }
            }
            return result
        }
    }

    /// Compiled transition with pattern matching support
    struct CompiledTransition {
        let from: FromPattern
        let to: ToPattern
        let input: String
        let switchTo: AutomatonType?
    }

    // MARK: - Storage

    /// Tier 1: Exact match transitions for O(1) lookup (hot path)
    private var exactTransitions: [String: [String: TransitionInfo]] = [:]

    /// Tier 2: Pattern match transitions for flexible matching (cold path)
    private var patternTransitions: [CompiledTransition] = []

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
    public func transition(currentState: String?, inputKey: String) -> TransitionInfo? {
        let state = currentState ?? ""

        // Tier 1: Exact match (hot path, O(1))
        if let info = exactTransitions[state]?[inputKey] {
            return info
        }

        // Tier 2: Pattern match (cold path, O(p))
        for pattern in patternTransitions where pattern.input == inputKey {
            if let captured = pattern.from.match(state: state) {
                let newState = pattern.to.apply(captured: captured)
                return TransitionInfo(toState: newState, switchTo: pattern.switchTo)
            }
        }

        return nil
    }

    /// Get display character for a state
    /// - Parameter state: State to display
    /// - Returns: Display character or the state itself if no mapping exists
    @inline(__always)
    public func display(_ state: String) -> String {
        displayTable[state] ?? state
    }

    /// Display with partial matching - all characters (for archaic mode)
    /// Converts all characters using greedy longest match
    /// - Parameter state: State to display
    /// - Returns: Display string with all characters converted
    public func displayPartialAll(_ state: String) -> String {
        // Fast path: exact match
        if let exact = displayTable[state] {
            return exact
        }

        // Partial matching: greedy longest match for all characters
        var result = ""
        var remaining = state

        while !remaining.isEmpty {
            var matched = false

            // Try longest match first
            for len in stride(from: remaining.count, through: 1, by: -1) {
                let prefix = String(remaining.prefix(len))
                if let display = displayTable[prefix] {
                    result += display
                    remaining = String(remaining.dropFirst(len))
                    matched = true
                    break
                }
            }

            if !matched {
                // No match found: keep first character as-is
                result += String(remaining.prefix(1))
                remaining = String(remaining.dropFirst(1))
            }
        }

        return result
    }

    /// Display with partial matching - first match only (for modern modes)
    /// Returns the first longest match and remaining state
    /// - Parameter state: State to display
    /// - Returns: Tuple of (display string, remaining state)
    public func displayFirstMatch(_ state: String) -> (display: String, remainingState: String) {
        // Fast path: exact match
        if let exact = displayTable[state] {
            return (exact, "")
        }

        // Find first longest match
        for len in stride(from: state.count, through: 1, by: -1) {
            let prefix = String(state.prefix(len))
            if let display = displayTable[prefix] {
                let remaining = String(state.dropFirst(len))
                return (display, remaining)
            }
        }

        // No match: return first character as-is
        let first = String(state.prefix(1))
        let remaining = String(state.dropFirst(1))
        return (first, remaining)
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
    ///   - fromState: Source state (empty string for initial state, supports pattern like "{:3}ㅅ")
    ///   - inputKey: Input key that triggers transition
    ///   - toState: Destination state (supports pattern like "{:2}ㅐ")
    ///   - switchTo: Optional target automaton to switch to
    public func addTransition(
        from fromState: String,
        input inputKey: String,
        to toState: String,
        switchTo: AutomatonType? = nil
    ) {
        // Parse patterns
        let fromPattern = parseFromPattern(fromState)
        let toPattern = parseToPattern(toState)

        // Decide tier based on pattern type
        if fromPattern.isExact && toPattern.parts.count == 1,
           case .literal = toPattern.parts[0] {
            // Tier 1: Exact match
            if exactTransitions[fromState] == nil {
                exactTransitions[fromState] = [:]
            }
            exactTransitions[fromState]![inputKey] = TransitionInfo(
                toState: toState,
                switchTo: switchTo
            )
        } else {
            // Tier 2: Pattern match
            patternTransitions.append(CompiledTransition(
                from: fromPattern,
                to: toPattern,
                input: inputKey,
                switchTo: switchTo
            ))
        }

        // Track valid states (use original strings)
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
    public func canTransition(from fromState: String?) -> Bool {
        let state = fromState ?? ""

        // Check exact transitions
        if let transitions = exactTransitions[state], !transitions.isEmpty {
            return true
        }

        // Check pattern transitions
        for pattern in patternTransitions {
            if pattern.from.match(state: state) != nil {
                return true
            }
        }

        return false
    }

    // MARK: - Pattern Parsing (Internal)

    /// Parse from pattern string into FromPattern
    /// - Parameter pattern: Pattern string (e.g., "{:3}ㅅ", "ㅏ")
    /// - Returns: Parsed FromPattern
    func parseFromPattern(_ pattern: String) -> FromPattern {
        // Check for capture pattern
        guard let braceStart = pattern.firstIndex(of: "{"),
              let braceEnd = pattern.firstIndex(of: "}"),
              braceStart < braceEnd else {
            // No capture → exact match
            return FromPattern(
                captureMin: 0,
                captureMax: 0,
                suffix: pattern,
                isExact: true
            )
        }

        // Extract slice {start:end}
        let sliceStart = pattern.index(after: braceStart)
        let sliceStr = String(pattern[sliceStart..<braceEnd])
        let components = sliceStr.split(separator: ":", omittingEmptySubsequences: false)

        let min = components[0].isEmpty ? 0 : Int(components[0])!
        let max = components.count > 1 && !components[1].isEmpty ? Int(components[1])! : nil

        // Extract suffix
        let suffixStart = pattern.index(after: braceEnd)
        let suffix = String(pattern[suffixStart...])

        return FromPattern(
            captureMin: min,
            captureMax: max,
            suffix: suffix,
            isExact: false
        )
    }

    /// Parse to pattern string into ToPattern
    /// - Parameter pattern: Pattern string (e.g., "{:2}ㅐ", "{0:-2}", "ㅅ")
    /// - Returns: Parsed ToPattern
    func parseToPattern(_ pattern: String) -> ToPattern {
        var parts: [ToPart] = []
        var i = pattern.startIndex
        var currentLiteral = ""

        while i < pattern.endIndex {
            if pattern[i] == "{" {
                // Check if there's a closing brace
                if let closeIdx = pattern[i...].firstIndex(of: "}") {
                    // Save accumulated literal
                    if !currentLiteral.isEmpty {
                        parts.append(.literal(currentLiteral))
                        currentLiteral = ""
                    }

                    // Parse {start:end}
                    let sliceStart = pattern.index(after: i)
                    let sliceStr = String(pattern[sliceStart..<closeIdx])
                    let (start, end) = parseSlice(sliceStr)
                    parts.append(.captureSlice(start: start, end: end))

                    i = pattern.index(after: closeIdx)
                } else {
                    // No closing brace → treat as literal
                    currentLiteral.append(pattern[i])
                    i = pattern.index(after: i)
                }
            } else {
                currentLiteral.append(pattern[i])
                i = pattern.index(after: i)
            }
        }

        // Save remaining literal
        if !currentLiteral.isEmpty {
            parts.append(.literal(currentLiteral))
        }

        // Optimization flag
        let isSimple = parts.count == 1

        return ToPattern(parts: parts, isSimple: isSimple)
    }

    /// Parse slice notation into start and end indices
    /// - Parameter sliceStr: Slice string (e.g., ":3", "0:-2", "-1")
    /// - Returns: Tuple of (start, end) indices
    private func parseSlice(_ sliceStr: String) -> (start: Int?, end: Int?) {
        let components = sliceStr.split(separator: ":", omittingEmptySubsequences: false)

        if components.count == 1 {
            // "{-1}" form → single index
            let idx = Int(components[0])!
            // Python semantics: negative index from end
            if idx < 0 {
                return (idx, nil)
            } else {
                return (idx, idx + 1)
            }
        } else {
            // "{0:-2}" form → slice
            let start = components[0].isEmpty ? nil : Int(components[0])!
            let end = components[1].isEmpty ? nil : Int(components[1])!
            return (start, end)
        }
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
