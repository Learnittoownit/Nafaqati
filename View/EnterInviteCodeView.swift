// EnterInviteCodeView.swift
// Nafaqati
//
// The child enters the 6-digit invite code that the parent shared.
// Each digit lives in its own box. Typing auto-advances to the next box.
// When all 6 are filled, it validates against Supabase automatically.
//
// Pattern: Same as ChildPINView (4 boxes) but extended to 6 boxes.

import SwiftUI

struct EnterInviteCodeView: View {

    // Passed in from the navigation — we need it to go forward
    @Binding var path: NavigationPath

    // The ViewModel that will validate the code with Supabase
    @StateObject private var childVM = ChildViewModel()

    // ─── 6 individual digit strings ───────────────────────────────
    // Each box has its own @State so SwiftUI can track changes separately.
    @State private var digits: [String] = Array(repeating: "", count: 6)

    // ─── Focus tracking ───────────────────────────────────────────
    // FocusState lets us move the cursor (keyboard) between boxes.
    // When you type in box 0, we auto-move focus to box 1, etc.
    @FocusState private var focusedIndex: Int?

    // ─── UI State ─────────────────────────────────────────────────
    @State private var showError: Bool = false
    @State private var isShaking: Bool = false  // shake animation on wrong code

    // Combine all digits into one string (e.g. "1" "2" "3" "4" "5" "6" → "123456")
    private var fullCode: String {
        digits.joined()
    }

    // True when all 6 boxes are filled
    private var isCodeComplete: Bool {
        fullCode.count == 6
    }

    var body: some View {
        ZStack {
            Color.nafBackground.ignoresSafeArea()

            VStack(spacing: 32) {

                // ── Header ────────────────────────────────────────
                VStack(spacing: 8) {
                    Text("Enter Invite Code")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.nafNavy)

                    Text("Ask your parent for the 6-digit code")
                        .font(.system(size: 15))
                        .foregroundColor(.nafTextGray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)

                Spacer()

                // ── 6 Digit Boxes ─────────────────────────────────
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { index in
                        CodeDigitBox(
                            digit: digits[index],
                            isFocused: focusedIndex == index
                        )
                        // Invisible TextField overlaid — handles actual typing
                        .overlay(
                            TextField("", text: Binding(
                                get: { digits[index] },
                                set: { handleInput($0, at: index) }
                            ))
                            .keyboardType(.numberPad)
                            .focused($focusedIndex, equals: index)
                            .opacity(0.01)  // invisible but tappable
                        )
                        .onTapGesture {
                            // Tapping any box focuses the first empty box
                            let firstEmpty = digits.firstIndex(where: { $0.isEmpty }) ?? 5
                            focusedIndex = firstEmpty
                        }
                    }
                }
                .offset(x: isShaking ? -10 : 0)
                .animation(
                    isShaking ? .easeInOut(duration: 0.07).repeatCount(4, autoreverses: true) : .default,
                    value: isShaking
                )

                // ── Error message ──────────────────────────────────
                if showError {
                    Text(childVM.errorMessage ?? "Invalid code. Please try again.")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .transition(.opacity)
                }

                Spacer()

                // ── Continue Button ────────────────────────────────
                Button {
                    Task { await validateCode() }
                } label: {
                    ZStack {
                        if childVM.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Continue")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        isCodeComplete
                            ? Color.nafblue
                            : Color.nafTextGray.opacity(0.4)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!isCodeComplete || childVM.isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        // Auto-focus first box when screen appears
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedIndex = 0
            }
        }
        .navigationBarBackButtonHidden(false)
        .animation(.easeInOut(duration: 0.2), value: showError)
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Input Handling
    // ─────────────────────────────────────────────────────────────────
    // Called every time the user types something into a box.

    private func handleInput(_ value: String, at index: Int) {
        // Only keep the last character typed (in case of paste)
        let newDigit = value.last.map(String.init) ?? ""

        // Only accept digits 0–9
        guard newDigit.isEmpty || newDigit.first?.isNumber == true else { return }

        digits[index] = newDigit

        if newDigit.isEmpty {
            // User deleted — stay on this box (or go back if needed)
            // This handles backspace: move focus back one box
            if index > 0 && digits[index].isEmpty {
                focusedIndex = index - 1
            }
        } else {
            // User typed a digit — advance to next box
            if index < 5 {
                focusedIndex = index + 1
            } else {
                // Last box filled — dismiss keyboard
                focusedIndex = nil
            }
        }

        // Clear error when user starts editing again
        if showError {
            showError = false
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Validate Code
    // ─────────────────────────────────────────────────────────────────

    private func validateCode() async {
        guard isCodeComplete else { return }
        focusedIndex = nil  // hide keyboard

        // Ask ChildViewModel to check the code in Supabase
        if let parentId = await childVM.validateInviteCode(fullCode) {
            // ✅ Code is valid — navigate to child profile setup
            // We pass the parentId forward so SetupChildProfileView can use it
            path.append(OnboardingStep.setupChildProfile(
                inviteCode: fullCode,
                parentId: parentId
            ))
        } else {
            // ❌ Code invalid — shake the boxes and show error
            withAnimation {
                isShaking = true
                showError = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isShaking = false
            }
            // Reset all boxes so child can try again
            digits = Array(repeating: "", count: 6)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedIndex = 0
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - CodeDigitBox
// ─────────────────────────────────────────────
// One individual box for a digit. Shows a filled digit or an empty placeholder.

struct CodeDigitBox: View {
    let digit: String
    let isFocused: Bool

    var body: some View {
        ZStack {
            // Box background
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.nafCardWhite)
                .frame(width: 48, height: 58)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isFocused ? Color.nafblue : Color.nafLightCard,
                            lineWidth: isFocused ? 2 : 1.5
                        )
                )
                .shadow(
                    color: isFocused ? Color.nafblue.opacity(0.15) : Color.black.opacity(0.04),
                    radius: isFocused ? 6 : 3,
                    x: 0, y: 2
                )

            // Digit text (or blinking cursor if focused and empty)
            if digit.isEmpty {
                if isFocused {
                    // Blinking cursor
                    Rectangle()
                        .fill(Color.nafblue)
                        .frame(width: 2, height: 24)
                        .opacity(0.8)
                }
            } else {
                Text(digit)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.nafNavy)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .animation(.easeInOut(duration: 0.1), value: digit)
    }
}

// ─────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────

#Preview {
    NavigationStack {
        EnterInviteCodeView(path: .constant(NavigationPath()))
    }
}
