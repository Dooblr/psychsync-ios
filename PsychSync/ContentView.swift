//
//  ContentView.swift
//  PsychSync
//
//  Created by Dan Feinstein on 8/28/25.
//

import SwiftUI

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

// MARK: - ViewModel (simple local state holder)
final class OnboardingViewModel: ObservableObject {
    @Published var data = OnboardingData()
    @Published var currentPage: Int = 0
    @Published var showJSON: Bool = false

    // convenience: encode to pretty JSON
    var jsonString: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let d = try encoder.encode(data)
            return String(data: d, encoding: .utf8) ?? "{}"
        } catch {
            return "{\"error\":\"\(error.localizedDescription)\"}"
        }
    }

    func goToNext() {
        withAnimation { currentPage = min(currentPage + 1, 4) }
    }

    func finishOnboarding() {
        data.completedDate = Date()
        showJSON = true
    }
    
    func restartOnboarding() {
        data = OnboardingData()
        currentPage = 0
        showJSON = false
    }
}

// MARK: - Custom Energy Slider Component
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
                    
                    // Thumb (rectangular playhead)
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

// MARK: - Reusable Styles
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
                        LinearGradient(gradient: Gradient(colors: colors),
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
            )
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 6)
    }
}

// MARK: - Main ContentView
struct ContentView: View {
    @StateObject private var vm = OnboardingViewModel()
    @AppStorage("isOnboarding") var isOnboarding: Bool = true

    var body: some View {
        Group {
            if isOnboarding && !vm.showJSON {
                onboardingFlow
            } else if vm.showJSON {
                resultsView
            } else {
                // Main app content with restart button
                mainAppContent
            }
        }
        // iOS 17 onChange two-parameter variant to avoid deprecation
        .onChange(of: vm.showJSON) { previous, current in
            if current {
                // persist flag so onboarding won't show automatically next launch
                withAnimation { isOnboarding = false }
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    // MARK: - Onboarding Flow (TabView with animated paging)
    var onboardingFlow: some View {
        TabView(selection: $vm.currentPage) {
            // Screen 1 - Welcome
            ScreenWelcome {
                vm.goToNext()
            }
            .tag(0)

            // Screen 2 - Your Goal (fixed: pass selectedGoals binding)
            ScreenGoal(
                selectedGoals: Binding(
                    get: { vm.data.goals },
                    set: { vm.data.goals = $0 }
                ),
                otherText: Binding(
                    get: { vm.data.otherGoalText ?? "" },
                    set: { vm.data.otherGoalText = $0 }
                ),
                continueAction: {
                    vm.goToNext()
                }
            )
            .tag(1)

            // Screen 3 - Current State
            ScreenBaseline(
                moodIndex: Binding(
                    get: { vm.data.moodIndex ?? 2 },
                    set: { vm.data.moodIndex = $0 }
                ),
                energy: Binding(
                    get: { vm.data.energyLevel },
                    set: { vm.data.energyLevel = $0 }
                ),
                sleepQuality: Binding(
                    get: { vm.data.sleepQuality ?? "Fair" },
                    set: { vm.data.sleepQuality = $0 }
                ),
                nextAction: {
                    vm.goToNext()
                }
            )
            .tag(2)

            // Screen 4 - Preferences
            ScreenPreferences(
                frequency: Binding(
                    get: { vm.data.checkInFrequency ?? "Daily" },
                    set: { vm.data.checkInFrequency = $0 }
                ),
                notifications: Binding(
                    get: { vm.data.notificationsChoice ?? "Remind" },
                    set: { vm.data.notificationsChoice = $0 }
                ),
                supportTypes: Binding(
                    get: { vm.data.supportTypes },
                    set: { vm.data.supportTypes = $0 }
                ),
                continueAction: {
                    vm.goToNext()
                }
            )
            .tag(3)

            // Screen 5 - Gentle Start
            ScreenGentleStart {
                vm.finishOnboarding()
            }
            .tag(4)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .padding(.bottom, 84) // Updated: 64pt above progress indicator + ~20pt for indicator itself
        .animation(.easeInOut, value: vm.currentPage)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }


    // MARK: - Results View (JSON)
    var resultsView: some View {
        VStack(spacing: 16) {
            Text("Onboarding Complete")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color.primary)

            Text("Here's the data you provided (JSON):")
                .foregroundColor(.secondary)

            ScrollView {
                Text(vm.jsonString)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                    .padding(.horizontal)
            }

            // Use the same OnboardingButton for uniformity
            OnboardingButton(title: "Done") {
                // dismiss JSON and show main app content
                withAnimation {
                    vm.showJSON = false
                }
            }

            Spacer()
        }
        .padding(.top, 24)
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    // MARK: - Main app content with restart button
    var mainAppContent: some View {
        VStack(spacing: 20) {
            Text("PsychSync")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.primary)

            Text("Main app content goes here.")
                .foregroundColor(.secondary)

            Spacer()
            
            // Restart onboarding button
            OnboardingButton(title: "Restart Onboarding") {
                withAnimation {
                    vm.restartOnboarding()
                    isOnboarding = true
                }
            }
            .padding(.bottom, 40)
        }
        .padding()
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}

// MARK: - Individual screen views

// Screen 1: Welcome
struct ScreenWelcome: View {
    var getStarted: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            VStack(spacing: 8) {
                Text("PsychSync")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.primary)

                Text("This is your space to understand your mood, your body, and the patterns between them. Ready to begin?")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .modifier(CardBackground(colors: [Color(.systemTeal).opacity(0.14), Color(.systemBackground)]))

            // CTA is now the shared OnboardingButton
            OnboardingButton(title: "Get Started", action: getStarted)
                .padding(.bottom, 64) // 64pt spacing above progress indicator

            Spacer()
        }
        .padding()
    }
}

// Screen 2: Your Goal (vertical, full-width multi-select; no layout shifts)
struct ScreenGoal: View {
    @Binding var selectedGoals: [String]   // now multi-select
    @Binding var otherText: String
    var continueAction: () -> Void

    let options = [
        "Reduce stress",
        "Understand mood & body patterns",
        "Build healthier habits",
        "Track symptoms",
        "Other"
    ]

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What brings you here?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.primary)

                Text("Choose the option(s) that best fit your goal.")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            // Vertical full-width options
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { opt in
                    Button {
                        toggle(opt)
                    } label: {
                        HStack(spacing: 12) {
                            // Left text expands to take available space
                            Text(opt)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(Color.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Right-aligned checkmark placeholder — fixed width to avoid shifts
                            if selectedGoals.contains(opt) {
                                Image(systemName: "checkmark.circle.fill")
                                    .imageScale(.large)
                                    .foregroundColor(Color.accentColor)
                                    .frame(width: 28, height: 28, alignment: .center)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                // reserve the same space so everything stays anchored
                                Image(systemName: "checkmark.circle.fill")
                                    .imageScale(.large)
                                    .foregroundColor(Color.clear)
                                    .frame(width: 28, height: 28, alignment: .center)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        // constant stroke width — color toggles but stroke width remains same
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedGoals.contains(opt) ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        // subtle overlay color when selected (no layout shift)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedGoals.contains(opt) ? Color.accentColor.opacity(0.08) : Color.clear)
                                .cornerRadius(12)
                        )
                    }
                    .accentColor(.primary)
                    .padding(.horizontal) // consistent inset so buttons stretch uniformly
                    .animation(.easeInOut(duration: 0.16), value: selectedGoals)
                }
            }
            .padding(.top, 4)

            // 'Other' free-text entry displayed when Other is selected
            if selectedGoals.contains("Other") {
                TextField("Tell us what brings you here...", text: $otherText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .foregroundColor(Color.primary)
            }

            Spacer()

            OnboardingButton(title: "Continue") {
                // if nothing selected, choose a sensible default (optional)
                if selectedGoals.isEmpty {
                    selectedGoals = [options.first ?? ""]
                }
                continueAction()
            }
            .padding(.bottom, 64) // 64pt spacing above progress indicator
        }
        .padding(.top)
    }

    private func toggle(_ opt: String) {
        if opt == "Other" {
            // toggling Other should leave otherText intact
        }

        if let index = selectedGoals.firstIndex(of: opt) {
            selectedGoals.remove(at: index)
        } else {
            selectedGoals.append(opt)
        }
    }
}



// Screen 3: Current State (Baseline)
struct ScreenBaseline: View {
    @Binding var moodIndex: Int
    @Binding var energy: Int
    @Binding var sleepQuality: String

    var nextAction: () -> Void

    let moods = ["😔","😕","😐","🙂","😄"] // compass from low -> high

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Let's get a snapshot of how you're doing today.")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.primary)
                Text("This helps us build your baseline.")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // Mood compass / emoji slider
            VStack(spacing: 8) {
                Text("Mood")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .foregroundColor(Color.primary)
                HStack(spacing: 12) {
                    ForEach(0..<moods.count, id: \.self) { i in
                        Text(moods[i])
                            .font(.largeTitle)
                            .padding(12)
                            .background(Circle().fill(moodIndex == i ? Color.accentColor.opacity(0.18) : Color.clear))
                            .overlay(Circle().stroke(moodIndex == i ? Color.accentColor : Color.clear, lineWidth: 2))
                            .onTapGesture {
                                withAnimation { moodIndex = i }
                            }
                    }
                }
            }

            // Energy slider 0-4 (5 steps)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Energy")
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primary)
                    Spacer()
                    Text("\(energy)")
                        .foregroundColor(.secondary)
                }
                CustomEnergySlider(value: $energy, range: 1...5)
            }
            .padding(.horizontal)

            // Sleep quality segmented
            VStack(alignment: .leading, spacing: 8) {
                Text("Sleep quality")
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primary)
                Picker("Sleep", selection: $sleepQuality) {
                    Text("Poor").tag("Poor")
                    Text("Fair").tag("Fair")
                    Text("Good").tag("Good")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)

            Spacer()

            OnboardingButton(title: "Continue") {
                if sleepQuality.isEmpty { sleepQuality = "Fair" }
                nextAction()
            }
            .padding(.bottom, 64) // 64pt spacing above progress indicator
        }
        .padding(.top)
    }
}

// Screen 4: Preferences
struct ScreenPreferences: View {
    @Binding var frequency: String
    @Binding var notifications: String
    @Binding var supportTypes: [String]
    var continueAction: () -> Void

    let frequencies = ["Daily", "A few times a week", "Just when I feel like it"]
    let notificationOptions = ["Remind", "Decide later"]
    let supports = ["Quick calming tools", "Journaling & reflection", "Data insights & patterns"]

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How would you like to use the app?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.primary)

                Text("Choose the settings that feel right for you.")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // Frequency
            VStack(alignment: .leading, spacing: 6) {
                Text("Check-in frequency")
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primary)
                Picker("Frequency", selection: $frequency) {
                    ForEach(frequencies, id: \.self) { f in
                        Text(f).tag(f)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.vertical, 4)
            }
            .padding(.horizontal)

            // Notifications
            VStack(alignment: .leading, spacing: 6) {
                Text("Notifications")
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primary)
                Picker("Notifications", selection: $notifications) {
                    ForEach(notificationOptions, id: \.self) { n in
                        Text(n == "Remind" ? "Yes, send me reminders" : "I'll decide later")
                            .tag(n)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)

            // Support type multi-select
            VStack(alignment: .leading, spacing: 6) {
                Text("Support type")
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primary)

                ForEach(supports, id: \.self) { s in
                    Button {
                        toggleSupport(s)
                    } label: {
                        HStack {
                            Text(s)
                                .foregroundColor(Color.primary)
                            Spacer()
                            if supportTypes.contains(s) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.accentColor)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(supportTypes.contains(s) ? Color.accentColor : Color.clear, lineWidth: supportTypes.contains(s) ? 2 : 0))
                    }
                    .accentColor(.primary)
                }
            }
            .padding(.horizontal)

            Spacer()

            OnboardingButton(title: "Continue") {
                // ensure defaults
                if frequency.isEmpty { frequency = frequencies[0] }
                if notifications.isEmpty { notifications = notificationOptions[0] }
                continueAction()
            }
            .padding(.bottom, 64) // 64pt spacing above progress indicator
        }
        .padding(.top)
    }

    func toggleSupport(_ name: String) {
        if let idx = supportTypes.firstIndex(of: name) {
            supportTypes.remove(at: idx)
        } else {
            supportTypes.append(name)
        }
    }
}

// Screen 5: Gentle Start
struct ScreenGentleStart: View {
    var finishAction: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            VStack(spacing: 12) {
                Text("You're all set 🌿")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.primary)

                Text("We'll guide you through your first check-in now. The more you log, the more insights you'll discover about your unique mind-body patterns.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .modifier(CardBackground(colors: [Color(.systemGreen).opacity(0.12), Color(.systemBackground)]))

            OnboardingButton(title: "Start First Check-In", action: finishAction)
                .padding(.bottom, 64) // 64pt spacing above progress indicator

            Spacer()
        }
        .padding()
    }
}

// MARK: - Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDevice("iPhone 14")
                .preferredColorScheme(.light)

            ContentView()
                .previewDevice("iPhone 14")
                .preferredColorScheme(.dark)
        }
    }
}
