import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Onboarding Steps
// ─────────────────────────────────────────────
enum OnboardingStep: Hashable {
    case roleSelection
    case parentInfo
    case createPassword(name: String, email: String, numberOfChildren: Int)
    case addChild(childIndex: Int, totalChildren: Int)
    case myChildren
    case childPIN
    case parentSetPIN
    case allSet
    case login
    case forgotPassword(email: String)
}

// ─────────────────────────────────────────────
// MARK: - Router
// ─────────────────────────────────────────────
struct OnboardingRouter: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(path: $path)
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {

                    case .roleSelection:
                        RoleSelectionView(path: $path)

                    case .parentInfo:
                        ParentInfoView(path: $path)

                    case .createPassword(let name, let email, let numberOfChildren):
                        CreatePasswordView(
                            path: $path,
                            name: name,
                            email: email,
                            numberOfChildren: numberOfChildren
                        )

                    case .addChild(let childIndex, let totalChildren):
                        AddChildView(
                            path: $path,
                            childIndex: childIndex,
                            totalChildren: totalChildren
                        )

                    case .myChildren:
                        MyChildrenView(path: $path)

                    case .childPIN:
                        ChildPINView(
                            path: $path,
                            isLoginMode: true)
                            .environmentObject(authVM)

                    case .parentSetPIN:
                        ChildPINView(
                            path: $path,
                            isLoginMode: false)
                            .environmentObject(authVM)
                        
                    case .allSet:
                        AllSetView(path: $path)

                    case .login:
                        LoginView(path: $path)

                    case .forgotPassword:
                        ForgotPasswordView(path: $path)
                    }
                }
        }
    }
}
