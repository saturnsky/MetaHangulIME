//
//  VirtualKey.swift
//  MetaHangulIME
//
//  입력 처리를 위한 가상 키 표현
//

import Foundation

/// 가상 키 입력을 나타냄
/// 값 의미론과 성능을 위해 struct 사용
public struct VirtualKey: Equatable, Hashable {
    /// 처리를 위한 내부 키 식별자
    public let keyIdentifier: String

    /// 키의 표시 레이블
    public let label: String

    /// 자모가 아닌 키 여부
    public let isNonJamo: Bool

    /// 성능을 위한 캐시된 해시 값
    private let cachedHash: Int

    public init(keyIdentifier: String, label: String = "", isNonJamo: Bool = false) {
        self.keyIdentifier = keyIdentifier
        self.label = label.isEmpty ? keyIdentifier : label
        self.isNonJamo = isNonJamo

        // 성능을 위해 해시를 미리 계산 (keyIdentifier만 사용, 고유하므로)
        self.cachedHash = keyIdentifier.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cachedHash)
    }
}
