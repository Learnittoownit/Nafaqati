import SwiftUI
import Supabase

struct AllSetView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var authVM:   AuthViewModel
    @EnvironmentObject var parentVM: ParentViewModel

    var body: some View {
        ZStack {
            Color.nafBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.nafLightCard)
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark")
                        .font(.system(
                            size: 32, weight: .bold))
                        .foregroundColor(Color.nafNavy)
                }

                Spacer().frame(height: 32)

                Group {
                    Text("You're all ")
                        .font(.system(
                            size: 30, weight: .bold))
                        .foregroundColor(Color.nafNavy)
                    + Text("set!")
                        .font(.system(
                            size: 30, weight: .bold))
                        .foregroundColor(Color.nafOrange)
                }

                Spacer().frame(height: 12)

                Text("Children added successfully.\nYour financial literacy journey starts now.")
                    .font(.system(size: 15))
                    .foregroundColor(Color.nafTextGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer().frame(height: 24)

                // Hint to find codes
                HStack(spacing: 10) {
                    Image(systemName:
                        "person.2.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.nafNavy)
                    Text("Go to the Children tab to find each child's login code")
                        .font(.system(
                            size: 13,
                            design: .rounded))
                        .foregroundColor(Color.nafNavy)
                }
                .padding(16)
                .background(Color(hex: "EBF4FF"))
                .cornerRadius(14)
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    Task {
                        if let parentId =
                            authVM.currentUserId {
                            do {
                                let children: [ChildProfile] =
                                    try await supabase
                                    .from("child_profile")
                                    .select()
                                    .eq("parent_id",
                                        value: parentId
                                            .uuidString)
                                    .execute()
                                    .value
                                await MainActor.run {
                                    parentVM.activeChildren =
                                        children.count
                                    authVM.isLoggedIn = true
                                }
                            } catch {
                                await MainActor.run {
                                    authVM.isLoggedIn = true
                                }
                            }
                        } else {
                            authVM.isLoggedIn = true
                        }
                    }
                } label: {
                    Text("Go to dashboard")
                        .font(.system(
                            size: 16,
                            weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.nafNavy)
                        .cornerRadius(27)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
}
