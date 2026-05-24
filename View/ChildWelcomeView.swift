// ChildWelcomeView.swift
// Nafaqati
//
// The very first screen a child sees after their profile is created.
// The 3 jars animate in one by one, then a welcome message appears,
// and finally the "Let's Go!" button shows up.
//
// Animation sequence:
//   0.3s → Saving jar appears (scales up from 0)
//   0.6s → Spending jar appears
//   0.9s → Giving jar appears
//   1.3s → Welcome text fades in
//   1.7s → Button fades in

import SwiftUI

struct ChildWelcomeView: View {

    // The child's name so we can say "Welcome, Sara! 🎉"
    let childName: String

    // Navigation binding to go to the next screen
    @Binding var path: NavigationPath

    // ─── Animation State ──────────────────────────────────────────
    // Each jar and the text/button has its own animation flag.
    @State private var showSavingJar   = false
    @State private var showSpendingJar = false
    @State private var showGivingJar   = false
    @State private var showText        = false
    @State private var showButton      = false

    // Small bounce on tap
    @State private var jarScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.nafBackground.ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // ── Greeting ──────────────────────────────────────
                if showText {
                    VStack(spacing: 8) {
                        Text("Welcome, \(childName)! 🎉")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.nafNavy)

                        Text("These are your money jars.\nThey'll help you save, spend wisely, and give.")
                            .font(.system(size: 16))
                            .foregroundColor(.nafTextGray)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer().frame(height: 48)

                // ── Three Jars ────────────────────────────────────
                HStack(alignment: .bottom, spacing: 20) {

                    // Saving Jar — appears first
                    if showSavingJar {
                        AnimatedJarCard(
                            jarType: .saving,
                            balance: 0.0,
                            label: "Saving",
                            scale: jarScale
                        )
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                    }

                    // Spending Jar — appears second (slightly bigger = center spotlight)
                    if showSpendingJar {
                        AnimatedJarCard(
                            jarType: .spending,
                            balance: 0.0,
                            label: "Spending",
                            scale: jarScale,
                            isCenter: true
                        )
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                    }

                    // Giving Jar — appears last
                    if showGivingJar {
                        AnimatedJarCard(
                            jarType: .giving,
                            balance: 0.0,
                            label: "Giving",
                            scale: jarScale
                        )
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity)

                Spacer()

                // ── Let's Go Button ───────────────────────────────
                if showButton {
                    Button {
                        // Navigate to child home screen
                        // (ChildHomeView — that's a later day's task)
                        path.append(OnboardingStep.childHome)
                    } label: {
                        HStack(spacing: 10) {
                            Text("Let's Go!")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(Color.nafblue)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color.nafblue.opacity(0.35), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 44)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .navigationBarHidden(true) // No back button on this welcome screen
        .onAppear {
            startAnimationSequence()
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Animation Sequence
    // ─────────────────────────────────────────────────────────────────
    // Each jar pops in with a spring animation, staggered 0.3s apart.
    // The text and button fade in after all jars are visible.

    private func startAnimationSequence() {
        // Jar 1: Saving
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showSavingJar = true
            }
        }

        // Jar 2: Spending
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showSpendingJar = true
            }
        }

        // Jar 3: Giving
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showGivingJar = true
            }
        }

        // Welcome text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.4)) {
                showText = true
            }
        }

        // Let's Go button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.4)) {
                showButton = true
            }
        }

        // Small bounce on all jars together after they're all visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                jarScale = 1.08
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    jarScale = 1.0
                }
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - AnimatedJarCard
// ─────────────────────────────────────────────
// A version of JarCardView designed for the welcome screen.
// The center jar (Spending) is slightly larger.

struct AnimatedJarCard: View {
    let jarType: JarType
    let balance: Double
    let label: String
    var scale: CGFloat = 1.0
    var isCenter: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            // Jar illustration (from JarCardView)
            JarIllustration(jarType: jarType, compact: !isCenter)
                .scaleEffect(isCenter ? 1.15 : 1.0)

            Text(label)
                .font(.system(size: isCenter ? 15 : 13, weight: .semibold))
                .foregroundColor(.nafNavy)
        }
        .padding(.vertical, isCenter ? 22 : 18)
        .padding(.horizontal, isCenter ? 18 : 14)
        .background(Color.nafCardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(
            color: jarType.jarColor.opacity(0.2),
            radius: isCenter ? 14 : 8,
            x: 0, y: isCenter ? 8 : 4
        )
        .scaleEffect(scale)
    }
}

// ─────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────

#Preview {
    NavigationStack {
        ChildWelcomeView(
            childName: "Sara",
            path: .constant(NavigationPath())
        )
    }
}
