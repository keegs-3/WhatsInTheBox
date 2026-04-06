import SwiftUI

struct SideMenuView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isOpen: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            // Dimmed background
            if isOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.25)) { isOpen = false } }
            }

            // Drawer
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // Close button
                    HStack {
                        Spacer()
                        Button { withAnimation(.easeInOut(duration: 0.25)) { isOpen = false } } label: {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .padding(12)
                        }
                    }
                    .padding(.top, 8)

                    // Profile
                    VStack(alignment: .leading, spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 56, height: 56)
                            Text(initials)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                        .padding(.bottom, 8)

                        if let family = authManager.currentFamily {
                            Text(family.name)
                                .font(.title3.bold())
                            if let code = family.inviteCode, !code.isEmpty {
                                HStack(spacing: 6) {
                                    Text("Invite: \(code)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Button {
                                        UIPasteboard.general.string = code
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                    Divider().padding(.horizontal, 20)

                    // Menu items
                    VStack(spacing: 0) {
                        menuRow(icon: "gearshape.fill", title: "Settings", color: .secondary) {
                            // TODO: settings
                        }
                        menuRow(icon: "questionmark.circle.fill", title: "Help", color: .secondary) {
                            // TODO: help
                        }
                    }
                    .padding(.top, 16)

                    Spacer()

                    // Sign out
                    VStack(spacing: 12) {
                        Divider().padding(.horizontal, 20)
                        Button(role: .destructive) {
                            Task {
                                await authManager.signOut()
                                withAnimation { isOpen = false }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                            .font(.body)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }

                        Text("WhatsInTheBox v1.0.0")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 16)
                    }
                }
                .frame(width: 280)
                .background(Color(.systemBackground))

                Spacer()
            }
            .offset(x: isOpen ? 0 : -300)
            .animation(.easeInOut(duration: 0.25), value: isOpen)
        }
        .ignoresSafeArea()
    }

    private var initials: String {
        let name = authManager.currentFamily?.name ?? "?"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    @ViewBuilder
    private func menuRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .frame(width: 24)
                Text(title)
                    .font(.body)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}
