import SwiftUI

struct ParentTabView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var parentVM = ParentViewModel()
    @State private var selectedTab: Int = 0

    init() {
        let inactiveColor = UIColor(red: 0.373, green: 0.369, blue: 0.353, alpha: 1.0)
        let activeColor   = UIColor(red: 0.094, green: 0.373, blue: 0.647, alpha: 1.0)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.stackedLayoutAppearance.normal.iconColor = inactiveColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: inactiveColor]
        appearance.stackedLayoutAppearance.selected.iconColor = activeColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: activeColor]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            ParentHomeView()
                .environmentObject(parentVM)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            TransfersView()
                .environmentObject(parentVM)
                .tabItem { Label("Transfers", systemImage: "arrow.left.arrow.right") }
                .tag(1)

            ChildrenView()
                .environmentObject(parentVM)
                .environmentObject(authVM)
                .tabItem { Label("Children", systemImage: "person.2.fill") }
                .tag(2)

            SettingsView()
                .environmentObject(parentVM)
                .environmentObject(authVM)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(3)
        }
    }
}
