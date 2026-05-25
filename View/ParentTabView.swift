import SwiftUI

struct ParentTabView: View {

    @StateObject private var parentVM = ParentViewModel()
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            ParentHomeView()
                .environmentObject(parentVM)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            TransfersView()
                .environmentObject(parentVM)
                .tabItem {
                    Label("Transfers", systemImage: "arrow.left.arrow.right")
                }
                .tag(1)

            ChildrenView()
                .environmentObject(parentVM)
                .tabItem {
                    Label("Children", systemImage: "person.2.fill")
                }
                .tag(2)

            SettingsView()
                .environmentObject(parentVM)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(Color(hex: "1B3A6B"))
    }
}