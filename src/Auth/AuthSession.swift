//
//  AuthSession.swift
//  RedDoor
//
//  Created by Quinn Liu on 11/18/26.
//

import Firebase
import FirebaseAuth

@Observable
final class AuthSession {
    var currentUser: AppUser?
    var isLoading = true
    var showAlert = false
    var alertMessage = ""

    private let userRepository = GenericRepository<AppUser>()
    private var listenerHandle: AuthStateDidChangeListenerHandle?

    // MARK: - Lifecycle
    init() {
        listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in await self?.handleAuthChange(firebaseUser) }
        }
    }

    deinit {
        if let listenerHandle { Auth.auth().removeStateDidChangeListener(listenerHandle) }
    }

    // MARK: - Actions
    func signIn(email: String, password: String) async {
        do {
            try await Auth.auth().signIn(withEmail: AppUser.normalizeEmail(email), password: password)
        } catch {
            present(error)
        }
    }

    func signUp(email: String, password: String) async {
        let normalized = AppUser.normalizeEmail(email)
        do {
            // Only allowlisted emails may create an account.
            let snapshot = try await userRepository.collectionRef.document(normalized).getDocument()
            guard snapshot.exists else { throw AuthSessionError.notAuthorized }
            try await Auth.auth().createUser(withEmail: normalized, password: password)
        } catch {
            present(error)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            present(error)
        }
    }

    // MARK: - Private
    @MainActor
    private func handleAuthChange(_ firebaseUser: User?) async {
        defer { isLoading = false }
        guard let email = firebaseUser?.email else {
            currentUser = nil
            return
        }
        do {
            currentUser = try await userRepository.get(id: AppUser.normalizeEmail(email))
        } catch {
            // Removed from allowlist (or lookup failed): block access.
            currentUser = nil
            try? Auth.auth().signOut()
            present(AuthSessionError.notAuthorized)
        }
    }

    private func present(_ error: Error) {
        alertMessage = error.localizedDescription
        showAlert = true
    }
}

enum AuthSessionError: LocalizedError {
    case notAuthorized

    var errorDescription: String? {
        "This email isn't authorized. Ask an administrator to add it."
    }
}
