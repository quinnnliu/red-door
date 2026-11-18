//
//  LoginView.swift
//  RedDoor
//
//  Created by Quinn Liu on 11/18/26.
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthSession.self) private var authSession

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isWorking = false
    @FocusState private var isFocused: Bool

    var body: some View {
        @Bindable var authSession = authSession

        VStack(spacing: 16) {
            Image("RedDoor")
                .resizable()
                .scaledToFit()
                .frame(width: 100)

            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)

            PasswordField()

            Button("Sign In") { run { await authSession.signIn(email: email, password: password) } }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(!canSubmit)

            Button("Create Account") { run { await authSession.signUp(email: email, password: password) } }
                .tint(.red)
                .disabled(!canSubmit)
        }
        .padding(24)
        .dismissKeyboardButton(isFocused: $isFocused)
        .alert("Error", isPresented: $authSession.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authSession.alertMessage)
        }
    }

    // MARK: Password Field
    @ViewBuilder
    private func PasswordField() -> some View {
        HStack {
            Group {
                if showPassword {
                    TextField("Password", text: $password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField("Password", text: $password)
                }
            }
            .textContentType(.password)
            .focused($isFocused)

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel(showPassword ? "Hide password" : "Show password")
        }
        .padding(8)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3)))
    }

    private var canSubmit: Bool {
        !isWorking && !email.isEmpty && !password.isEmpty
    }

    private func run(_ action: @escaping () async -> Void) {
        isWorking = true
        Task {
            await action()
            isWorking = false
        }
    }
}
