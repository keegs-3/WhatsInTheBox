import SwiftUI

struct FamilySetupView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var familyName = ""
    @State private var inviteCode = ""
    @State private var mode: Mode = .choose

    enum Mode {
        case choose, create, join
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.2.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.accent)

                Text("Set Up Your Family")
                    .font(.title.bold())

                Text("Share storage spaces with your household")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                switch mode {
                case .choose:
                    VStack(spacing: 16) {
                        Button {
                            mode = .create
                        } label: {
                            Label("Create a Family", systemImage: "plus.circle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            mode = .join
                        } label: {
                            Label("Join with Code", systemImage: "ticket")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                    }

                case .create:
                    VStack(spacing: 16) {
                        TextField("Family Name (e.g. \"The Dolans\")", text: $familyName)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            Task { await authManager.createFamily(name: familyName) }
                        } label: {
                            Text("Create")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(familyName.isEmpty)

                        Button("Back") { mode = .choose }
                            .font(.footnote)
                    }

                case .join:
                    VStack(spacing: 16) {
                        TextField("Enter invite code", text: $inviteCode)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Button {
                            Task { await authManager.joinFamily(inviteCode: inviteCode) }
                        } label: {
                            Text("Join")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(inviteCode.isEmpty)

                        Button("Back") { mode = .choose }
                            .font(.footnote)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 32)
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
