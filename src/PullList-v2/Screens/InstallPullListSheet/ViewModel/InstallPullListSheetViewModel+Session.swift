//
//  InstallPullListSheetViewModel+Session.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Foundation

// MARK: - Ownership

extension InstallPullListSheetViewModel {

    /// Only the holder of the current lock generation may write. Everyone else
    /// watches live and can take over.
    var isOwner: Bool {
        guard let mine = myGeneration, let session = sessionState else { return false }
        return mine == session.lockGeneration
    }

    var isReadOnly: Bool { !isOwner }
}

// MARK: - Session lifecycle

extension InstallPullListSheetViewModel {

    @MainActor
    func joinOrCreateSession() async {
        do {
            myGeneration = try await sessionRepo.createSession(id: pullListState.id)

            // Seed optimistically when we created it, so ownership reads as true
            // immediately rather than after the first snapshot arrives.
            if let generation = myGeneration, sessionState == nil {
                sessionState = InstallSession(id: pullListState.id, lockGeneration: generation)
            }
        } catch {
            present(error)
        }
    }

    @MainActor
    func takeoverSession() async {
        do {
            myGeneration = try await sessionRepo.takeoverSession(id: pullListState.id)
        } catch {
            present(error)
        }
    }

    @MainActor
    func handleSessionSnapshot(_ result: Result<InstallSession?, Error>) {
        switch result {
        case .success(let session):
            let wasOwner = isOwner

            guard let session else {
                sessionState = nil
                myGeneration = nil

                // Distinguish "not created yet" from "was here and is now gone".
                // Without `didObserveSession` every user would be alerted on
                // open, since the first snapshot precedes session creation.
                if didObserveSession, !didCommit {
                    sessionEndedByOtherUser = true
                    alertText = "This pull list was installed by another user."
                    showAlert = true
                }
                return
            }

            didObserveSession = true
            sessionState = session

            if wasOwner, !isOwner {
                alertText = "Another user took over this install. You are now view-only."
                showAlert = true
            }

        case .failure(let error):
            present(error)
        }
    }
}
