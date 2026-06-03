// ChildViewModel.swift
// Nafaqati

import Foundation
import Combine
import Supabase

@MainActor
final class ChildViewModel: ObservableObject {

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func createChildProfile(
        name: String,
        age: Int,
        avatar: String,
        pin: String,
        parentId: UUID
    ) async -> Bool {

        isLoading    = true
        errorMessage = nil

        struct ChildRow: Encodable {
            let parent_id:          String
            let name:               String
            let age:                Int
            let avatar_url:         String
            let pin_reset_required: Bool
        }

        do {
            try await supabase
                .from("child_profile")
                .insert(ChildRow(
                    parent_id:          parentId.uuidString,
                    name:               name,
                    age:                age,
                    avatar_url:         avatar,
                    pin_reset_required: true
                ))
                .execute()

            isLoading = false
            return true

        } catch {
            errorMessage = error.localizedDescription
            isLoading    = false
            return false
        }
    }
}
