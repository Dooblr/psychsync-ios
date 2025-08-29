//
//  CardBackground.swift
//  PsychSync
//
//  Created by Dan Feinstein on 8/28/25.
//

import SwiftUI

/// A reusable view modifier that applies a card-like background with gradient and shadow
struct CardBackground: ViewModifier {
    // Use dynamic system colors for dark/light compatibility
    var colors: [Color] = [Color(.secondarySystemBackground), Color(.systemBackground)]
    
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: colors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 6)
    }
}

// MARK: - View Extension for Convenience
extension View {
    /// Applies the card background modifier with default colors
    func cardBackground() -> some View {
        self.modifier(CardBackground())
    }
    
    /// Applies the card background modifier with custom colors
    func cardBackground(colors: [Color]) -> some View {
        self.modifier(CardBackground(colors: colors))
    }
}
