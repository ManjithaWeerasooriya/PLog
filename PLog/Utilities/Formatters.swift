//
//  Formatters.swift
//  PLog
//
//  Small, shared formatting helpers so numbers and dates read consistently everywhere.
//

import Foundation

enum WeightFormatter {
    /// Formats a weight, dropping the decimal for whole numbers (60 not 60.0, but 62.5 kept).
    static func string(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

extension Date {
    /// e.g. "Mon, Sep 16"
    var mediumDayLabel: String {
        formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    /// e.g. "September 16, 2026"
    var longDateLabel: String {
        formatted(.dateTime.month(.wide).day().year())
    }
}
