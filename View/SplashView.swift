// SplashView.swift
// Nafaqati
//
// Animated splash screen:
//   1. Money roll drops in smoothly from top (no bounce)
//   2. App name fades in below
//   3. Tagline fades in
//   4. Auto-advances after 5 seconds

import SwiftUI

struct SplashView: View {
    @Binding var showSplash: Bool

    // ── Animation states ──────────────────────────────────────
    @State private var moneyOffsetY: CGFloat = -400   // starts above screen
    @State private var moneyScale:   CGFloat = 0.6
    @State private var textOpacity:  Double  = 0.0
    @State private var taglineOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // ── Background ────────────────────────────────────
            Color(hex: "2D6DAB").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── Logo ──────────────────────────────────────
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 350)
                    .scaleEffect(moneyScale)
                    .offset(y: moneyOffsetY)

                Spacer().frame(height: 32)

                // ── App name ──────────────────────────────────
                VStack(spacing: 8) {
                    Text("Nafaqati")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    Text("نفقتي")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                }
                .opacity(textOpacity)

                Spacer()

                // ── Tagline ───────────────────────────────────
                Text("Trusted by Saudi families")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 50)
                    .opacity(taglineOpacity)
            }
        }
        .onAppear {
            runAnimationSequence()
        }
    }

    // ─────────────────────────────────────────────────────────
    // MARK: - Animation Sequence
    // ─────────────────────────────────────────────────────────

    private func runAnimationSequence() {

        // Step 1: Money drops in smoothly (no bounce)
        withAnimation(.easeOut(duration: 1.5)) {
            moneyOffsetY = 0
            moneyScale   = 1.0
        }

        // Step 2: App name fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.5)) {
                textOpacity = 1.0
            }
        }

        // Step 3: Tagline fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            withAnimation(.easeOut(duration: 0.4)) {
                taglineOpacity = 1.0
            }
        }

        // Step 4: Auto-advance to next screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showSplash = false
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────

#Preview {
    SplashView(showSplash: .constant(true))
}

