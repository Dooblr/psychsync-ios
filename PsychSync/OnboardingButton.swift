//
//  OnboardingButton.swift
//  PsychSync
//
//  Created by Dan Feinstein on 8/28/25.
//

import SwiftUI

// MARK: - Shared OnboardingButton
struct OnboardingButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}
