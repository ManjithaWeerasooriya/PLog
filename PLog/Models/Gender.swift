//
//  Gender.swift
//  PLog
//
//  The gender field on `UserProfile`.
//

import Foundation

enum Gender: String, Codable, CaseIterable, Identifiable {
    case female
    case male

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .female: return "Female"
        case .male: return "Male"
        }
    }
}
