// AddChildView.swift
// Nafaqati

import SwiftUI
import PhotosUI

struct AddChildView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var childVM = ChildViewModel()

    let childIndex: Int
    let totalChildren: Int

    @State private var childName:       String    = ""
    @State private var age:             String    = ""

    @State private var selectedGender:  String    = ""
    @State private var selectedAvatar:  String    = ""
    @State private var selectedImage:   UIImage?  = nil   // real photo if taken
    @State private var showAvatarSheet: Bool      = false

    var canProceed: Bool {
        !childName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !age.isEmpty &&
        !selectedGender.isEmpty
    }

    var isLastChild: Bool { childIndex == totalChildren }

    var nextButtonLabel: String {
        if totalChildren == 1  { return "Next" }
        else if isLastChild    { return "Done" }
        else                   { return "Next child" }
    }

    var body: some View {
        ZStack {
            Color.nafBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    OnboardingProgressBar(currentStep: 3)
                        .padding(.top, 20)

                    Spacer().frame(height: 32)

                    VStack(alignment: .leading, spacing: 6) {
                        if totalChildren > 1 {
                            Text("Child \(childIndex) of \(totalChildren)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.nafOrange)
                        }
                        Text("Child")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(Color.nafNavy)
                        Text("Fill in your child's details")
                            .font(.system(size: 14))
                            .foregroundColor(Color.nafTextGray)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 28)

                    // ── Avatar row ─────────────────────────
                    Button { showAvatarSheet = true } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.nafLightCard)
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Circle().stroke(Color.nafNavy.opacity(0.15), lineWidth: 2)
                                    )
                                if let img = selectedImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipShape(Circle())
                                } else if selectedAvatar.isEmpty {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color.nafTextGray)
                                } else {
                                    Text(selectedAvatar)
                                        .font(.system(size: 36))
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Child's photo")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color.nafNavy)
                                Text("Tap to take a photo or upload from library")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.nafTextGray)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 20)

                    VStack(spacing: 18) {

                        NafField(
                            label: "Child's name",
                            placeholder: "e.g. Shahad",
                            text: $childName
                        )

                        // ── Gender ─────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gender")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.nafNavy)

                            HStack(spacing: 10) {
                                GenderButton(emoji: "👦", label: "Boy",
                                             isSelected: selectedGender == "Boy")
                                { selectedGender = "Boy" }

                                GenderButton(emoji: "👧", label: "Girl",
                                             isSelected: selectedGender == "Girl")
                                { selectedGender = "Girl" }

                                Spacer()
                            }
                        }

                        NafField(label: "Age", placeholder: "7 – 12",
                                 text: $age, keyboardType: .numberPad)

                        if let error = childVM.errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 13))
                                Text(error).font(.system(size: 13))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 32)

                    VStack(spacing: 12) {
                        Button {
                            Task { await saveAndContinue() }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 27)
                                    .fill(canProceed ? Color.nafNavy : Color.nafTextGray)
                                    .frame(height: 54)
                                if childVM.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(nextButtonLabel)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(!canProceed || childVM.isLoading)

                        if totalChildren > 1 && !isLastChild {
                            Button { navigateNext() } label: {
                                HStack(spacing: 4) {
                                    Text("Skip")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color.nafNavy)
                                    Text("— Add more children later")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color.nafTextGray)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showAvatarSheet) {
            AvatarPickerSheet(
                selectedAvatar: $selectedAvatar,
                selectedImage:  $selectedImage,
                showSheet:      $showAvatarSheet
            )
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
    }

    private func saveAndContinue() async {
        guard let parentId = authVM.currentUserId else { return }
        let success = await childVM.createChildProfile(
            name:     childName.trimmingCharacters(in: .whitespaces),
            age:      Int(age) ?? 0,
            avatar:   selectedAvatar,
            pin:      "",
            parentId: parentId
        )
        if success { navigateNext() }
    }

    private func navigateNext() {
        if isLastChild {
            path.append(OnboardingStep.myChildren)
        } else {
            path.append(OnboardingStep.addChild(
                childIndex: childIndex + 1,
                totalChildren: totalChildren
            ))
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Gender Button
// ─────────────────────────────────────────────

struct GenderButton: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji).font(.system(size: 16))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.nafNavy)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.nafNavy.opacity(0.1) : Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.nafNavy : Color.clear, lineWidth: 2)
            )
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Camera Picker (UIImagePickerController)
// ─────────────────────────────────────────────

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Avatar Picker Sheet
// ─────────────────────────────────────────────

struct AvatarPickerSheet: View {
    @Binding var selectedAvatar: String
    @Binding var selectedImage:  UIImage?
    @Binding var showSheet: Bool

    @State private var showCamera:   Bool = false
    @State private var photosItem:   PhotosPickerItem? = nil

    let avatars = [
        "🦁", "🐨", "🦊", "🦋", "🐬",
        "🐼", "🦄", "🐯", "🦅", "🐸",
        "🦔", "🐙", "👦", "👧"
    ]
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        VStack(spacing: 0) {

            Capsule()
                .fill(Color.nafTextGray.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 16)

            // ── Option 1: Camera ──────────────────────
            Button { showCamera = true } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11)
                            .fill(Color.nafNavy)
                            .frame(width: 42, height: 42)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Take a photo")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.nafNavy)
                        Text("Open camera")
                            .font(.system(size: 12))
                            .foregroundColor(Color.nafTextGray)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.nafLightCard)
                .cornerRadius(14)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            // ── Option 2: Photo Library ───────────────
            PhotosPicker(selection: $photosItem, matching: .images) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11)
                            .fill(Color(hex: "4CAF82"))
                            .frame(width: 42, height: 42)
                        Image(systemName: "photo.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upload from library")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.nafNavy)
                        Text("Choose from your photos")
                            .font(.system(size: 12))
                            .foregroundColor(Color.nafTextGray)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.nafLightCard)
                .cornerRadius(14)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .onChange(of: photosItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage  = image
                        selectedAvatar = ""   // clear emoji if photo chosen
                        showSheet = false
                    }
                }
            }

            // ── Divider ───────────────────────────────
            HStack {
                Rectangle().fill(Color.nafLightCard).frame(height: 1)
                Text("or pick a character")
                    .font(.system(size: 12))
                    .foregroundColor(Color.nafTextGray)
                    .fixedSize()
                    .padding(.horizontal, 8)
                Rectangle().fill(Color.nafLightCard).frame(height: 1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            // ── Emoji grid ────────────────────────────
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(avatars, id: \.self) { avatar in
                    Button {
                        selectedAvatar = avatar
                        selectedImage  = nil   // clear photo if emoji chosen
                    } label: {
                        Text(avatar)
                            .font(.system(size: 26))
                            .frame(width: 52, height: 52)
                            .background(
                                selectedAvatar == avatar
                                ? Color.nafOrange.opacity(0.15)
                                : Color.nafLightCard
                            )
                            .cornerRadius(13)
                            .overlay(
                                RoundedRectangle(cornerRadius: 13)
                                    .stroke(
                                        selectedAvatar == avatar ? Color.nafOrange : Color.clear,
                                        lineWidth: 2.5
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            // ── Confirm button ────────────────────────
            Button { showSheet = false } label: {
                Text("Confirm")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.nafNavy)
                    .cornerRadius(27)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .background(Color.white)
        .presentationDetents([.height(500)])
        .presentationDragIndicator(.hidden)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(selectedImage: $selectedImage, isPresented: $showCamera)
                .ignoresSafeArea()
                .onDisappear {
                    if selectedImage != nil {
                        selectedAvatar = ""   // clear emoji if photo taken
                        showSheet = false
                    }
                }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────

#Preview {
    NavigationStack {
        AddChildView(
            path: .constant(NavigationPath()),
            childIndex: 1,
            totalChildren: 1
        )
        .environmentObject(AuthViewModel())
    }
}

