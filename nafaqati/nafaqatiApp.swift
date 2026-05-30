import SwiftUI

@main
struct nafaqatiApp: App {
    @StateObject private var authVM   = AuthViewModel()
    @StateObject private var parentVM = ParentViewModel()
    @State private var showSplash     = true
    @State private var path           = NavigationPath()
    @AppStorage("isChildLoggedIn") var isChildLoggedIn = false

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashView(showSplash: $showSplash)

            } else if isChildLoggedIn {
                ChildTabView()

            } else if authVM.isLoggedIn {
                ParentTabView()
                    .environmentObject(authVM)
                    .environmentObject(parentVM)

            } else {
                NavigationStack(path: $path) {
                    WelcomeView(path: $path)
                        .navigationDestination(
                            for: OnboardingStep.self
                        ) { step in
                            switch step {

                            case .roleSelection:
                                RoleSelectionView(path: $path)

                            case .parentInfo:
                                ParentInfoView(path: $path)
                                    .environmentObject(authVM)

                            case .createPassword(
                                let name,
                                let email,
                                let numberOfChildren):
                                CreatePasswordView(
                                    path: $path,
                                    name: name,
                                    email: email,
                                    numberOfChildren:
                                        numberOfChildren)
                                .environmentObject(authVM)

                            case .addChild(
                                let childIndex,
                                let totalChildren):
                                AddChildView(
                                    path: $path,
                                    childIndex: childIndex,
                                    totalChildren: totalChildren)
                                .environmentObject(authVM)

                            case .myChildren:
                                MyChildrenView(path: $path)
                                    .environmentObject(authVM)

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
                                    .environmentObject(authVM)
                                    .environmentObject(parentVM)

                            case .login:
                                LoginView(path: $path)
                                    .environmentObject(authVM)

                            case .forgotPassword:
                                ForgotPasswordView(path: $path)
                                    .environmentObject(authVM)
                            }
                        }
                }
                .environmentObject(authVM)
                .onAppear { path = NavigationPath() }
                .task { await authVM.checkSession() }
            }
        }
    }
}
