import SwiftUI
import Supabase

struct ChildPINView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var authVM: AuthViewModel

    var isLoginMode: Bool = false

    @State private var code:         [String] = ["","","","","",""]
    @State private var confirmCode:  [String] = ["","","","","",""]
    @State private var isConfirming  = false
    @State private var isLoading     = false
    @State private var errorMessage: String?
    @FocusState private var focusedIndex: Int?

    @AppStorage("isChildLoggedIn") var isChildLoggedIn = false

    var codeString:    String { code.joined() }
    var confirmString: String { confirmCode.joined() }
    var codesMatch:    Bool   { codeString == confirmString }

    var body: some View {
        ZStack {
            Color.nafBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image("AppLogoFull")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .cornerRadius(22)

                Spacer().frame(height: 32)

                Text(isLoginMode
                     ? "Enter your code"
                     : isConfirming
                        ? "Confirm your code"
                        : "Create a PIN")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color.nafNavy)
                    .multilineTextAlignment(.center)

                Text(isLoginMode
                     ? "Ask your parent for your 6-digit code"
                     : isConfirming
                        ? "Enter it again to confirm"
                        : "Your child will use this to log in")
                    .font(.system(size: 14))
                    .foregroundColor(Color.nafTextGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)

                Spacer().frame(height: 40)

                // 6 boxes for login mode
                // 4 boxes for PIN creation mode
                if isLoginMode {
                    HStack(spacing: 10) {
                        ForEach(0..<6, id: \.self) { index in
                            codeBox(
                                text: isConfirming
                                ? $confirmCode[index]
                                : $code[index],
                                index: index,
                                total: 6)
                        }
                    }
                } else {
                    HStack(spacing: 16) {
                        ForEach(0..<4, id: \.self) { index in
                            codeBox(
                                text: isConfirming
                                ? $confirmCode[index]
                                : $code[index],
                                index: index,
                                total: 4)
                        }
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .padding(.top, 16)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                Button {
                    if isLoginMode {
                        Task { await loginWithCode() }
                    } else if !isConfirming {
                        isConfirming = true
                        focusedIndex = 0
                        confirmCode  = ["","","","","",""]
                    } else {
                        if codesMatch {
                            Task { await savePIN() }
                        } else {
                            errorMessage = "Codes do not match. Try again."
                            confirmCode  = ["","","","","",""]
                            focusedIndex = 0
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 27)
                            .fill(Color.nafNavy)
                            .frame(height: 54)
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(isLoginMode
                                 ? "Log in"
                                 : isConfirming
                                    ? "Confirm"
                                    : "Next")
                                .font(.system(
                                    size: 16,
                                    weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(isLoading
                          || (isLoginMode
                              && codeString.count < 6)
                          || (!isLoginMode
                              && codeString.count < 4)
                          || (isConfirming
                              && confirmString.count < 4))
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { path.removeLast() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(Color.nafNavy)
                }
            }
        }
        .onAppear { focusedIndex = 0 }
    }

    // ── Reusable code box ─────────────────
    func codeBox(text: Binding<String>,
                 index: Int,
                 total: Int) -> some View {
        SecureField("", text: text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .foregroundColor(Color.nafNavy)
            .font(.system(size: 22, weight: .bold))
            .frame(width: total == 6 ? 48 : 64,
                   height: 56)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        text.wrappedValue.isEmpty
                        ? Color.nafLightCard
                        : Color.nafNavy,
                        lineWidth: 2))
            .focused($focusedIndex, equals: index)
            .onChange(of: text.wrappedValue) { _, newValue in
                let filtered = newValue
                    .filter { $0.isNumber }
                let limited  = String(filtered.prefix(1))
                text.wrappedValue = limited
                if limited.count == 1 && index < total - 1 {
                    focusedIndex = index + 1
                }
            }
    }

    // ── LOGIN MODE — child enters 6-digit code ──
    func loginWithCode() async {
        isLoading    = true
        errorMessage = nil

        do {
            let children: [ChildProfile] = try await supabase
                .from("child_profile")
                .select()
                .eq("invite_code", value: codeString)
                .execute()
                .value

            if let child = children.first {
                UserDefaults.standard.set(
                    child.id.uuidString,
                    forKey: "childId")
                UserDefaults.standard.set(
                    child.parentId.uuidString,
                    forKey: "parentId")
                UserDefaults.standard.set(
                    child.name,
                    forKey: "childName")
                UserDefaults.standard.set(
                    child.avatarUrl ?? "🦁",
                    forKey: "childAvatar")

                await MainActor.run {
                    isLoading       = false
                    isChildLoggedIn = true
                }
            } else {
                await MainActor.run {
                    errorMessage = "Wrong code. Ask your parent for the correct 6-digit code."
                    code         = ["","","","","",""]
                    focusedIndex = 0
                    isLoading    = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Connection error. Please try again."
                isLoading    = false
            }
        }
    }

    // ── CREATE MODE — parent saves PIN ────
    func savePIN() async {
        guard let parentId = authVM.currentUserId else {
            errorMessage = "Session expired. Please log in again."
            return
        }

        isLoading    = true
        errorMessage = nil

        do {
            let children: [ChildProfile] = try await supabase
                .from("child_profile")
                .select()
                .eq("parent_id", value: parentId.uuidString)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            guard let child = children.first else {
                errorMessage = "No child found. Please go back and add a child first."
                isLoading    = false
                return
            }

            try await supabase
                .from("child_profile")
                .update(["pin": codeString])
                .eq("id", value: child.id.uuidString)
                .execute()

            await MainActor.run {
                isLoading = false
                path.append(OnboardingStep.allSet)
            }

        } catch {
            await MainActor.run {
                errorMessage = "Failed to save. Please try again."
                isLoading    = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChildPINView(
            path: .constant(NavigationPath()),
            isLoginMode: true
        )
        .environmentObject(AuthViewModel())
    }
}

