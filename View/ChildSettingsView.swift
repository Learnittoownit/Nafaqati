import SwiftUI

struct ChildSettingsView: View {

    @AppStorage("isChildLoggedIn") var isChildLoggedIn = false
    @State private var showConfirm = false

    var body: some View {
        ZStack {
            Color(hex: "EEF2F8").ignoresSafeArea()

            VStack(spacing: 20) {

                Text("Settings")
                    .font(.system(
                        size: 22,
                        weight: .bold,
                        design: .rounded))
                    .foregroundColor(Color(hex: "1B3A6B"))
                    .frame(maxWidth: .infinity,
                           alignment: .center)
                    .padding(.top, 20)

                Spacer()

                // Sign out button
                Button {
                    showConfirm = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName:
                            "arrow.right.square")
                            .font(.system(size: 18))
                        Text("Sign out")
                            .font(.system(
                                size: 16,
                                weight: .semibold,
                                design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(hex: "E05555"))
                    .cornerRadius(27)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .confirmationDialog(
            "Are you sure you want to sign out?",
            isPresented: $showConfirm,
            titleVisibility: .visible) {
            Button("Sign out", role: .destructive) {
                // Clear all child session data
                UserDefaults.standard.removeObject(
                    forKey: "childId")
                UserDefaults.standard.removeObject(
                    forKey: "parentId")
                UserDefaults.standard.removeObject(
                    forKey: "childName")
                UserDefaults.standard.removeObject(
                    forKey: "childAvatar")
                UserDefaults.standard.removeObject(
                    forKey: "savedGoals")
                UserDefaults.standard.removeObject(
                    forKey: "savedChildActivity")
                isChildLoggedIn = false
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
