//
//  UserManagementViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 11/18/26.
//

import Firebase

@Observable
final class UserManagementViewModel {
    var users: [AppUser] = []
    var newEmail = ""
    var showAlert = false
    var alertMessage = ""

    private let userRepository = GenericRepository<AppUser>()

    // MARK: - Loading
    func loadUsers() async {
        do {
            users = try await userRepository.getAll()
        } catch {
            present(error)
        }
    }

    // MARK: - Actions
    func addUser() async {
        let email = AppUser.normalizeEmail(newEmail)
        guard email.contains("@"), !users.contains(where: { $0.id == email }) else { return }
        do {
            try userRepository.set(document: AppUser(email: email))
            newEmail = ""
            await loadUsers()
        } catch {
            present(error)
        }
    }

    func remove(_ user: AppUser) async {
        do {
            try await userRepository.delete(id: user.id)
            await loadUsers()
        } catch {
            present(error)
        }
    }

    func setAdmin(_ user: AppUser, isAdmin: Bool) async {
        do {
            try await userRepository.update(id: user.id, fields: ["is_admin": isAdmin])
            await loadUsers()
        } catch {
            present(error)
        }
    }

    private func present(_ error: Error) {
        alertMessage = error.localizedDescription
        showAlert = true
    }
}
