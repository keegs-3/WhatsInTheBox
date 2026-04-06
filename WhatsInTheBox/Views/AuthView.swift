import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)

                Text("What's In The Box?")
                    .font(.largeTitle.bold())

                Text("Track everything in your storage unit")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                VStack(spacing: 16) {
                    if isSignUp {
                        TextField("Name", text: $displayName)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                    }

                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(isSignUp ? .newPassword : .password)

                    Button {
                        Task {
                            if isSignUp {
                                await authManager.signUp(email: email, password: password, displayName: displayName)
                            } else {
                                await authManager.signIn(email: email, password: password)
                            }
                        }
                    } label: {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || password.isEmpty || (isSignUp && displayName.isEmpty))

                    Button(isSignUp ? "Already have an account? Sign in" : "Don't have an account? Sign up") {
                        isSignUp.toggle()
                    }
                    .font(.footnote)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .alert("Error", isPresented: .init(
                get: { authManager.errorMessage != nil },
                set: { if !$0 { authManager.errorMessage = nil } }
            )) {
                Button("OK") { authManager.errorMessage = nil }
            } message: {
                Text(authManager.errorMessage ?? "")
            }
        }
    }
}
