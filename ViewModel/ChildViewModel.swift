// ChildViewModel.swift
// Nafaqati

import SwiftUI
import Combine
import Supabase

// FIXED: Removed @MainActor from the class level — it conflicts with @Published.
// Instead, each async function is marked @MainActor individually.

final class ChildViewModel: ObservableObject {

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var childProfile: ChildProfile? = nil
    @Published var jars: [Jar] = []

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Invite Code Validation
    // ─────────────────────────────────────────────────────────────────
    // We use a local struct here to avoid depending on the InviteCode model's
    // exact property names — Supabase returns snake_case JSON.

    @MainActor
    func validateInviteCode(_ code: String) async -> UUID? {

        // Local struct that matches the Supabase JSON response exactly
        struct InviteCodeRow: Decodable {
            let parent_id: String   // snake_case to match Supabase column
        }

        do {
            let results: [InviteCodeRow] = try await supabase
                .from("invite_codes")
                .select("parent_id")
                .eq("code", value: code)
                .eq("is_used", value: false)
                .limit(1)
                .execute()
                .value

            guard let row = results.first,
                  let uuid = UUID(uuidString: row.parent_id) else {
                errorMessage = "This code is invalid or expired. Please try again."
                return nil
            }

            return uuid

        } catch {
            errorMessage = "This code is invalid or expired. Please try again."
            print("❌ validateInviteCode error: \(error)")
            return nil
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Mark Invite Code as Used
    // ─────────────────────────────────────────────────────────────────

    func markCodeAsUsed(_ code: String) async {
        do {
            try await supabase
                .from("invite_codes")
                .update(["is_used": true])
                .eq("code", value: code)
                .execute()
        } catch {
            print("⚠️ Could not mark invite code as used: \(error)")
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Create Child Profile
    // ─────────────────────────────────────────────────────────────────

    @MainActor
    func createChildProfile(
        name: String,
        age: Int,
        avatar: String,
        pin: String,
        parentId: UUID
    ) async -> Bool {

        isLoading = true
        errorMessage = nil

        struct NewChildProfile: Encodable {
            let parent_id: String
            let name: String
            let age: Int
            let avatar_url: String
            let pin: String
            let pin_reset_required: Bool
        }

        let newProfile = NewChildProfile(
            parent_id: parentId.uuidString,
            name: name,
            age: age,
            avatar_url: avatar,
            pin: pin,
            pin_reset_required: false
        )

        do {
            let created: ChildProfile = try await supabase
                .from("child_profile")
                .insert(newProfile)
                .select()
                .single()
                .execute()
                .value

            self.childProfile = created
            isLoading = false
            return true

        } catch {
            isLoading = false
            errorMessage = "Couldn't create profile. Please try again."
            print("❌ createChildProfile error: \(error)")
            return false
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Load Jars
    // ─────────────────────────────────────────────────────────────────

    @MainActor
    func loadJars(for childId: UUID) async {
        do {
            let fetchedJars: [Jar] = try await supabase
                .from("jars")
                .select()
                .eq("child_id", value: childId.uuidString)
                .execute()
                .value

            self.jars = fetchedJars

            if fetchedJars.isEmpty {
                print("⚠️ No jars found. Check that the Supabase trigger is active!")
            } else {
                print("✅ Loaded \(fetchedJars.count) jars for child \(childId)")
            }

        } catch {
            print("❌ loadJars error: \(error)")
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Helpers
    // ─────────────────────────────────────────────────────────────────

    func jar(ofType type: JarType) -> Jar? {
        jars.first { $0.type == type }
    }

    func balance(for type: JarType) -> Double {
        jar(ofType: type)?.balance ?? 0.0
    }
}

