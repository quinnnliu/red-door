//
//  UserManagementSection.swift
//  RedDoor
//
//  Created by Quinn Liu on 11/18/26.
//

import SwiftUI

struct UserManagementSection: View {
    @Environment(AuthSession.self) private var authSession
    @State private var viewModel = UserManagementViewModel()
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Users")
                    .font(.headline)
                Spacer()
            }

            HStack {
                TextField("Add email", text: $viewModel.newEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)

                Button("Add") { Task { await viewModel.addUser() } }
                    .buttonStyle(.bordered)
                    .tint(.red)
            }

            ForEach(viewModel.users) { user in
                let isSelf = user.id == authSession.currentUser?.id
                HStack {
                    Text(user.email)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                    Toggle("Admin", isOn: Binding(
                        get: { user.isAdmin },
                        set: { value in Task { await viewModel.setAdmin(user, isAdmin: value) } }
                    ))
                    .labelsHidden()
                    .tint(.red)
                    .disabled(isSelf)

                    Button(role: .destructive) {
                        Task { await viewModel.remove(user) }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(isSelf)
                }
            }
        }
        .dismissKeyboardButton(isFocused: $isFocused)
        .task { await viewModel.loadUsers() }
        .alert("Error", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}
