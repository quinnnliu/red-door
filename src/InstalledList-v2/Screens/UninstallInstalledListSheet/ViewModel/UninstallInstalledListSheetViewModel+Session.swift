//
//  UninstallInstalledListSheetViewModel+Session.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Foundation

// MARK: - Ownership

extension UninstallInstalledListSheetViewModel {

    /// Correct from the start, but not yet load-bearing: mutations are ungated
    /// until the collaboration phase wires this into the UI.
    var isOwner: Bool {
        guard let mine = myGeneration, let session = sessionState else { return false }
        return mine == session.lockGeneration
    }

    var isReadOnly: Bool { !isOwner }
}

// MARK: - Session lifecycle

extension UninstallInstalledListSheetViewModel {

    // MARK: joinOrCreateSession

    @MainActor
    func joinOrCreateSession() async {
        do {
            myGeneration = try await sessionRepo.createSession(id: installedListState.id)
            // nil -> a session already existed; we joined it and the listener
            //        will deliver its state.

            // Seed optimistically when we created it, so ownership reads as true
            // immediately rather than after the first snapshot arrives.
            if let generation = myGeneration, sessionState == nil {
                sessionState = UninstallSession(
                    id: installedListState.id,
                    lockGeneration: generation
                )
            }
        } catch {
            present(error)
        }
    }

    // MARK: handleSessionSnapshot

    @MainActor
    func resolveExistingPullList(_ id: String) async {
        do {
            existingPullList = try await pullListRepo.get(id: id)
        } catch {
            existingPullList = nil
        }
    }

    @MainActor
    func handleSessionSnapshot(_ result: Result<UninstallSession?, Error>) {
        switch result {
        case .success(let session):
            let previousExistingId = sessionState?.existingPullListId

            guard let session else {
                sessionState = nil
                myGeneration = nil
                selectedItemIds.removeAll()

                // Distinguish "not created yet" from "was here and is now gone".
                // Without `didObserveSession` every user would be alerted on
                // open, since the first snapshot precedes session creation.
                if didObserveSession, !didCommit {
                    sessionEndedByOtherUser = true
                    alertMessage = "This uninstall was completed by another user."
                    showAlert = true
                }
                return
            }

            didObserveSession = true
            sessionState = session

            if let existingId = session.existingPullListId, existingId != previousExistingId {
                Task { await resolveExistingPullList(existingId) }
            }

        case .failure(let error):
            present(error)
        }
    }
}
