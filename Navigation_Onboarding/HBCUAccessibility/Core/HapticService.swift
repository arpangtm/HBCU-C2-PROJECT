//
//  HapticService.swift
//  HBCUAccessibility
//
//  Haptic feedback for blind users: step change, arrival, caution.
//

import UIKit

enum HapticService {
    /// Light tap when a new navigation step begins — confirms "you're on this step."
    static func stepChanged() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        gen.impactOccurred()
    }

    /// Success pattern when user arrives at destination.
    static func arrived() {
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.success)
    }

    /// Slightly stronger tap for caution (e.g. "watch for stairs").
    static func caution() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.prepare()
        gen.impactOccurred()
    }

    /// Very light tap when navigation starts.
    static func navigationStarted() {
        let gen = UIImpactFeedbackGenerator(style: .soft)
        gen.prepare()
        gen.impactOccurred()
    }
}
