import Foundation
import SwiftUI
import Supabase

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentFamily: Family?
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let client = SupabaseService.shared.client

    init() {
        Task {
            await checkSession()
        }
    }

    func checkSession() async {
        isLoading = true
        do {
            let session = try await client.auth.session
            isAuthenticated = true
            await loadFamily()
            _ = session
        } catch {
            isAuthenticated = false
        }
        isLoading = false
    }

    func signUp(email: String, password: String, displayName: String) async {
        do {
            try await client.auth.signUp(
                email: email,
                password: password,
                data: ["display_name": .string(displayName)]
            )
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        do {
            try await client.auth.signIn(email: email, password: password)
            isAuthenticated = true
            await loadFamily()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
            isAuthenticated = false
            currentFamily = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Family

    func createFamily(name: String) async {
        do {
            let userId = try await client.auth.session.user.id
            let family = Family(name: name, createdBy: userId)
            let created: Family = try await client
                .from("families")
                .insert(family)
                .select()
                .single()
                .execute()
                .value

            // Add self as owner
            let member = FamilyMember(
                id: UUID(),
                familyId: created.id,
                userId: userId,
                role: "owner",
                joinedAt: Date()
            )
            try await client
                .from("family_members")
                .insert(member)
                .execute()

            currentFamily = created
        } catch {
            errorMessage = "Failed to create family: \(error.localizedDescription)"
        }
    }

    func joinFamily(inviteCode: String) async {
        do {
            let userId = try await client.auth.session.user.id

            // Look up family by invite code
            let families: [Family] = try await client
                .from("families")
                .select()
                .eq("invite_code", value: inviteCode)
                .execute()
                .value

            guard let family = families.first else {
                errorMessage = "No family found with that code"
                return
            }

            let member = FamilyMember(
                id: UUID(),
                familyId: family.id,
                userId: userId,
                role: "member",
                joinedAt: Date()
            )
            try await client
                .from("family_members")
                .insert(member)
                .execute()

            currentFamily = family
        } catch {
            errorMessage = "Failed to join family: \(error.localizedDescription)"
        }
    }

    func loadFamily() async {
        do {
            let userId = try await client.auth.session.user.id
            let members: [FamilyMember] = try await client
                .from("family_members")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            if let membership = members.first {
                let families: [Family] = try await client
                    .from("families")
                    .select()
                    .eq("id", value: membership.familyId.uuidString)
                    .execute()
                    .value
                currentFamily = families.first
            }
        } catch {
            // No family yet, that's fine
        }
    }
}
