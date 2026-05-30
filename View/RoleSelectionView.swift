import SwiftUI

struct RoleSelectionView: View {
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            Color.nafBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                OnboardingProgressBar(currentStep: 1)
                    .padding(.top, 20)

                Spacer().frame(height: 32)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Who are you?")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Color.nafNavy)
                    Text("This helps us set up the right experience for you.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(Color.nafTextGray)
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 32)

                VStack(spacing: 16) {
                    RoleCard(
                        icon: "person.2.fill",
                        title: "I'm a Parent",
                        subtitle: "Set up my child's account"
                    ) {
                        path.append(OnboardingStep.parentInfo)
                    }

                    RoleCard(
                        icon: "person.fill",
                        title: "I'm a Kid",
                        subtitle: "Log in with my 6-digit code"                    ) {
                        path.append(OnboardingStep.childPIN)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { path.removeLast() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                            .font(.system(size: 15, design: .rounded))
                    }
                    .foregroundColor(Color.nafNavy)
                }
            }
        }
    }
}

// ── Role card component ──────────────────
struct RoleCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.nafLightCard)
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(Color.nafNavy)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.nafNavy)
                    Text(subtitle)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(Color.nafTextGray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(Color.nafTextGray)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
        }
    }
}
