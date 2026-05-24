// nafaqatiApp_Day2_additions.swift
// Nafaqati
//
// ⚠️  DO NOT add this as a new file.
// This file shows ONLY the new navigationDestination blocks you need to
// ADD inside your existing nafaqatiApp.swift.
//
// Find the section in nafaqatiApp.swift where the other
// .navigationDestination(for: OnboardingStep.self) calls live,
// and paste these cases inside the same switch statement.
//
// ─────────────────────────────────────────────────────────────────
// PASTE THESE CASES inside the switch statement in nafaqatiApp.swift:
// ─────────────────────────────────────────────────────────────────
//
//  case .enterInviteCode:
//      EnterInviteCodeView(path: $path)
//
//  case .setupChildProfile(let inviteCode, let parentId):
//      SetupChildProfileView(
//          inviteCode: inviteCode,
//          parentId: parentId,
//          path: $path
//      )
//      // Note: SetupChildProfileView is a Day 3 task.
//      // For now, add a placeholder view (see below).
//
//  case .childWelcome(let childName):
//      ChildWelcomeView(childName: childName, path: $path)
//
//  case .childHome:
//      // Placeholder — replace with real ChildHomeView in Day 5
//      ChildHomePlaceholderView()
//
// ─────────────────────────────────────────────────────────────────
// PLACEHOLDER VIEWS (add anywhere in nafaqatiApp.swift or a new file)
// until the real views are built in later days:
// ─────────────────────────────────────────────────────────────────

import SwiftUI

/// Temporary placeholder for SetupChildProfileView (Day 3 task)
struct SetupChildProfileView: View {
    let inviteCode: String
    let parentId: UUID
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            Color.nafBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("👤")
                    .font(.system(size: 60))
                Text("Setup Child Profile")
                    .font(.title2.bold())
                    .foregroundColor(.nafNavy)
                Text("Parent ID: \(parentId.uuidString.prefix(8))...")
                    .font(.caption)
                    .foregroundColor(.nafTextGray)

                // Demo: skip to welcome screen
                Button("Continue (Demo)") {
                    path.append(OnboardingStep.childWelcome(childName: "Sara"))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.nafblue)
            }
        }
        .navigationTitle("Child Profile")
    }
}

/// Temporary placeholder for ChildHomeView (Day 5 task)
struct ChildHomePlaceholderView: View {
    var body: some View {
        ZStack {
            Color.nafBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🏠")
                    .font(.system(size: 60))
                Text("Child Home")
                    .font(.title2.bold())
                    .foregroundColor(.nafNavy)
                Text("Coming in Day 5!")
                    .foregroundColor(.nafTextGray)
            }
        }
        .navigationTitle("Home")
    }
}
