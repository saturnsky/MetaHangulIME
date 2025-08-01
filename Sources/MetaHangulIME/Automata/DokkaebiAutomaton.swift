//
//  DokkaebiAutomaton.swift
//  MetaHangulIME
//
//  Handles the 'dokkaebi' (도깨비불) phenomenon in Korean typing
//

import Foundation

/// Result of dokkaebi processing
public struct DokkaebiResult {
    /// Whether dokkaebi splitting should occur
    public let shouldSplit: Bool
    
    /// Remaining jongseong state in current syllable (nil if completely moved)
    public let remainingJongseongState: String?
    
    /// Choseong state to move to next syllable
    public let movedChoseongState: String
    
    public init(shouldSplit: Bool, 
                remainingJongseongState: String? = nil,
                movedChoseongState: String = "") {
        self.shouldSplit = shouldSplit
        self.remainingJongseongState = remainingJongseongState
        self.movedChoseongState = movedChoseongState
    }
}

/// Handles the 'dokkaebi' (도깨비불) phenomenon in Korean typing
///
/// Dokkaebi phenomenon occurs when a jongseong (final consonant) splits into:
/// 1. A remaining jongseong in the current syllable (or nil)
/// 2. A choseong (initial consonant) for the next syllable
///
/// Example: 갃 + ㅣ -> 각 + 시
/// - ㄳ (jongseong) splits into ㄱ (remains) + ㅅ (moves to next syllable)
public final class DokkaebiAutomaton {
    /// Transition table: jongseong -> (remaining_jong, moved_cho)
    /// Using dictionary for O(1) lookup
    private var transitionTable: [String: (remaining: String?, moved: String)] = [:]
    
    public init() {}
    
    /// Add a dokkaebi transition rule
    /// - Parameters:
    ///   - jongseongState: Jongseong state that triggers dokkaebi
    ///   - remainingJong: Jongseong that remains (nil if completely moves)
    ///   - movedCho: Choseong that moves to next syllable
    public func addTransition(jongseongState: String, 
                            remainingJong: String?, 
                            movedCho: String) {
        transitionTable[jongseongState] = (remainingJong, movedCho)
    }
    
    /// Check if dokkaebi can occur for given jongseong
    /// - Parameter jongseongState: Current jongseong state
    /// - Returns: true if dokkaebi can occur
    @inline(__always)
    public func canSplit(_ jongseongState: String) -> Bool {
        return transitionTable[jongseongState] != nil
    }
    
    /// Process dokkaebi phenomenon
    /// - Parameter jongseongState: Current jongseong state
    /// - Returns: DokkaebiResult with split information
    public func process(_ jongseongState: String) -> DokkaebiResult {
        if let (remaining, moved) = transitionTable[jongseongState] {
            return DokkaebiResult(
                shouldSplit: true,
                remainingJongseongState: remaining,
                movedChoseongState: moved
            )
        }
        
        return DokkaebiResult(
            shouldSplit: false,
            remainingJongseongState: jongseongState,
            movedChoseongState: ""
        )
    }
    
    /// Batch add transitions for performance
    /// - Parameter transitions: Array of (jongseong, remaining, moved) tuples
    public func addTransitions(_ transitions: [(jongseong: String, remaining: String?, moved: String)]) {
        for transition in transitions {
            addTransition(
                jongseongState: transition.jongseong,
                remainingJong: transition.remaining,
                movedCho: transition.moved
            )
        }
    }
}