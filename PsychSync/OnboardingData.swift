//
//  OnboardingData.swift
//  PsychSync
//
//  Created by Dan Feinstein on 8/28/25.
//

import Foundation

// MARK: - Onboarding data model
struct OnboardingData: Codable {
    // Screen 2
    var goals: [String] = []
    var otherGoalText: String?

    // Screen 3 (baseline)
    var moodIndex: Int?          // 0..4 (emoji compass)
    var energyLevel: Int = 3     // 1..5
    var sleepQuality: String?    // "Good" / "Fair" / "Poor"

    // Screen 4 (preferences)
    var checkInFrequency: String?      // Daily / Few times a week / Just when I feel like it
    var notificationsChoice: String?   // Remind / Decide later
    var supportTypes: [String] = []    // multi-select

    // Metadata
    var completedDate: Date?
}
