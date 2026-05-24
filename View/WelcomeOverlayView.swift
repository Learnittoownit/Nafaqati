// WelcomeOverlayView.swift
// Nafaqati
//
// Shown to the PARENT the first time they open the app after signup.
// A 3-step carousel that explains the main features.
// Appears as a semi-transparent overlay ON TOP of the parent home screen.
//
// HOW TO USE:
// In your ParentHomeView (or wherever the parent lands), add:
//
//   @State private var showWelcomeOverlay = true   // show first time only
//
//   .overlay {
//       if showWelcomeOverlay {
//           WelcomeOverlayView(isPresented: $showWelcomeOverlay)
//       }
//   }

import SwiftUI

struct WelcomeOverlayView: View {

    // When this becomes false, the overlay disappears
    @Binding var isPresented: Bool

    // Which card we're currently showing (0, 1, or 2)
    @State private var currentStep: Int = 0

    // Controls the whole overlay fading in/out
    @State private var overlayOpacity: Double = 0

    // Controls each card sliding in/out
    @State private var cardOffset: CGFloat = 60
    @State private var cardOpacity: Double = 0

    // The 3 welcome cards content
    private let steps: [WelcomeStep] = [
        WelcomeStep(
            emoji: "🏦",
            title: "Three Jars System",
            description: "Your child has 3 jars: Saving, Spending, and Giving. Each allowance is split between them automatically.",
            accentColor: Color(hex: "F5A623")  // orange
        ),
        WelcomeStep(
            emoji: "🎯",
            title: "Set Goals Together",
            description: "Your child can create saving goals. You can track their progress and send encouragement from the parent dashboard.",
            accentColor: Color(hex: "185FA5")  // blue
        ),
        WelcomeStep(
            emoji: "💌",
            title: "Send Allowance & Messages",
            description: "Send weekly allowance with a voice note or message. Your child gets notified instantly.",
            accentColor: Color(hex: "4CAF82")  // green
        )
    ]

    var body: some View {
        ZStack {
            // ── Dimmed background ──────────────────────────────────
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    // Tapping outside dismisses (optional UX choice)
                    dismissOverlay()
                }

            // ── Card ──────────────────────────────────────────────
            VStack(spacing: 0) {
                Spacer()

                // The card itself
                VStack(spacing: 28) {

                    // Progress dots at the top
                    WelcomeDots(total: steps.count, current: currentStep)

                    // Content for current step
                    WelcomeCardContent(step: steps[currentStep])

                    // Navigation buttons
                    WelcomeCardButtons(
                        currentStep: currentStep,
                        totalSteps: steps.count,
                        onNext: { goToNextStep() },
                        onSkip: { dismissOverlay() },
                        onDone: { dismissOverlay() }
                    )
                }
                .padding(.top, 32)
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
                .background(Color.nafCardWhite)
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: -10)
                .padding(.horizontal, 20)
                .offset(y: cardOffset)
                .opacity(cardOpacity)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .opacity(overlayOpacity)
        .onAppear {
            // Fade in the whole overlay
            withAnimation(.easeOut(duration: 0.3)) {
                overlayOpacity = 1
            }
            // Slide up the card
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) {
                cardOffset = 0
                cardOpacity = 1
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Navigation
    // ─────────────────────────────────────────────────────────────────

    private func goToNextStep() {
        guard currentStep < steps.count - 1 else { return }

        // Slide out current card to the left, then slide in next card from right
        withAnimation(.easeIn(duration: 0.2)) {
            cardOffset = -30
            cardOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentStep += 1
            cardOffset = 30  // start from the right side
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                cardOffset = 0
                cardOpacity = 1
            }
        }
    }

    private func dismissOverlay() {
        withAnimation(.easeIn(duration: 0.25)) {
            overlayOpacity = 0
            cardOffset = 80
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - WelcomeStep Model
// ─────────────────────────────────────────────

struct WelcomeStep {
    let emoji: String
    let title: String
    let description: String
    let accentColor: Color
}

// ─────────────────────────────────────────────
// MARK: - WelcomeDots
// ─────────────────────────────────────────────
// Progress indicator: three dots, current one is larger and filled

struct WelcomeDots: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                if index == current {
                    // Active dot — orange and wider
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.nafOrange)
                        .frame(width: 24, height: 8)
                } else {
                    // Inactive dot — gray circle
                    Circle()
                        .fill(Color.nafLightCard)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .animation(.spring(response: 0.3), value: current)
    }
}

// ─────────────────────────────────────────────
// MARK: - WelcomeCardContent
// ─────────────────────────────────────────────

struct WelcomeCardContent: View {
    let step: WelcomeStep

    var body: some View {
        VStack(spacing: 20) {

            // Big emoji in a colored circle
            ZStack {
                Circle()
                    .fill(step.accentColor.opacity(0.12))
                    .frame(width: 90, height: 90)
                Text(step.emoji)
                    .font(.system(size: 44))
            }

            // Title
            Text(step.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.nafNavy)
                .multilineTextAlignment(.center)

            // Description
            Text(step.description)
                .font(.system(size: 15))
                .foregroundColor(.nafTextGray)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - WelcomeCardButtons
// ─────────────────────────────────────────────

struct WelcomeCardButtons: View {
    let currentStep: Int
    let totalSteps: Int
    let onNext: () -> Void
    let onSkip: () -> Void
    let onDone: () -> Void

    private var isLastStep: Bool { currentStep == totalSteps - 1 }

    var body: some View {
        VStack(spacing: 12) {

            // Main action button
            Button {
                if isLastStep { onDone() } else { onNext() }
            } label: {
                Text(isLastStep ? "Get Started!" : "Next")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.nafblue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Skip button (only shown before last step)
            if !isLastStep {
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: 15))
                        .foregroundColor(.nafTextGray)
                }
                .frame(height: 36)
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────
// The preview shows the overlay on top of a mock background

#Preview {
    ZStack {
        // Simulated parent home screen background
        Color.nafBackground.ignoresSafeArea()
        VStack {
            Text("Parent Home Screen")
                .font(.title2)
                .foregroundColor(.nafNavy)
        }

        // The overlay on top
        WelcomeOverlayView(isPresented: .constant(true))
    }
}
