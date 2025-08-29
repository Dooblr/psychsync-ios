//
//  CustomEnergySlider.swift
//  PsychSync
//
//  Created by Dan Feinstein on 8/29/25.
//

import SwiftUI

struct CustomEnergySlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray4))
                        .frame(height: 16)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor)
                        .frame(
                            width: max(0, CGFloat(value - range.lowerBound) / CGFloat(range.upperBound - range.lowerBound) * geometry.size.width),
                            height: 16
                        )
                    
                    // Thumb
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 24)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .offset(
                            x: max(0, min(
                                geometry.size.width - 8,
                                CGFloat(value - range.lowerBound) / CGFloat(range.upperBound - range.lowerBound) * geometry.size.width - 4
                            ))
                        )
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gestureValue in
                            let percent = max(0, min(1, gestureValue.location.x / geometry.size.width))
                            let newValue = range.lowerBound + Int(percent * Double(range.upperBound - range.lowerBound))
                            value = newValue
                        }
                )
            }
            .frame(height: 24)
        }
    }
}

struct CustomEnergySlider_Previews: PreviewProvider {
    @State static var value = 3
    static var previews: some View {
        CustomEnergySlider(value: $value, range: 1...5)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
