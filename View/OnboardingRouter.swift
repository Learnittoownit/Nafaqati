// OnboardingRouter.swift
// Nafaqati
//
// Defines every possible navigation destination in the app.
// NavigationStack uses this enum to know which view to show.
//
// ✅ Day 1 cases (Rama's work) — kept unchanged
// ✅ Day 2 cases (Yara's work) — new cases added below

import Foundation

enum OnboardingStep: Hashable {

    // ─── Parent Onboarding (Day 1) ────────────────────────────────
    case roleSelection
    case parentInfo
    case createPassword(name: String, email: String)
    case addChild
    case myChildren
    case childPIN
    case allSet
    case login
    case forgotPassword(email: String)

    // ─── Child Onboarding (Day 2 — Yara) ─────────────────────────

    /// Child enters the 6-digit invite code from their parent
    case enterInviteCode

    /// Child fills in their name, age, and picks an avatar
    /// We pass the invite code + parentId forward so we can create the profile
    case setupChildProfile(inviteCode: String, parentId: UUID)

    /// The animated 3-jars welcome screen (shown after profile is created)
    /// We pass the child's name to personalize the greeting
    case childWelcome(childName: String)

    // ─── Child Home (Day 5 — future) ──────────────────────────────
    /// Placeholder so ChildWelcomeView can navigate forward without errors.
    /// Replace with the real ChildHomeView navigation in Day 5.
    case childHome
}

