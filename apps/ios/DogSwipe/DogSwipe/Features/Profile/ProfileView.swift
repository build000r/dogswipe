import SwiftUI

struct ProfileView: View {
    @ObservedObject private var preferencesStore: CravingPreferencesStore
    @ObservedObject private var authSessionStore: AuthSessionStore
    @State private var email = ""
    @State private var magicLinkToken = ""
    @State private var advancedToken = ""

    init(
        preferencesStore: CravingPreferencesStore = CravingPreferencesStore(),
        authSessionStore: AuthSessionStore = AuthSessionStore()
    ) {
        self.preferencesStore = preferencesStore
        self.authSessionStore = authSessionStore
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: .dsSpace5) {
                sessionSection

                VStack(alignment: .leading, spacing: .dsSpace2) {
                    Text("Your cravings")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.dsInk)
                    Text("Tune distance and flavor filters for nearby hotdog picks.")
                        .font(.body)
                        .foregroundStyle(Color.dsMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: .dsSpace4) {
                    Toggle(isOn: spicyFriendlyBinding) {
                        preferenceLabel(icon: "flame", title: "Spicy friendly")
                    }
                    Toggle(isOn: classicOnlyBinding) {
                        preferenceLabel(icon: "checkmark.seal", title: "Classic only")
                    }
                    VStack(alignment: .leading, spacing: .dsSpace3) {
                        HStack {
                            preferenceLabel(icon: "location", title: "Search radius")
                            Spacer()
                            Text("\(Int(preferencesStore.maxDistanceMiles)) mi")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(Color.dsMuted)
                        }
                        Slider(
                            value: maxDistanceBinding,
                            in: 1...25,
                            step: 1
                        ) { isEditing in
                            guard !isEditing else {
                                return
                            }
                            Task {
                                await preferencesStore.save()
                            }
                        }
                            .tint(.dsPrimary)
                    }

                    if let syncMessage = preferencesStore.syncMessage {
                        Text(syncMessage)
                            .font(.footnote)
                            .foregroundStyle(Color.dsMuted)
                    }
                }
                .toggleStyle(.switch)
                .tint(.dsPrimary)
                .padding(.dsSpace5)
                .dsCardSurface()

                Spacer()
            }
            .padding(.dsSpace5)
            .navigationTitle("Profile")
            .onAppear {
                advancedToken = authSessionStore.bearerToken
                DogSwipeAnalytics.shared.trackScreenViewed(.profile)
            }
            .onChange(of: authSessionStore.bearerToken) {
                advancedToken = authSessionStore.bearerToken
            }
            .toolbar {
                if preferencesStore.isSyncing || authSessionStore.isAuthenticating {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .dsPageBackground()
            .accessibilityIdentifier("dogswipe.profile.screen")
        }
    }

    private var sessionSection: some View {
        VStack(alignment: .leading, spacing: .dsSpace4) {
            DogSwipeSectionHeader(
                title: "Session",
                subtitle: sessionStatus,
                systemImage: "key.fill"
            )

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()

            SecureField("Magic link token", text: $magicLinkToken)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            ViewThatFits(in: .horizontal) {
                HStack(spacing: .dsSpace3) {
                    sendMagicLinkButton
                    verifyMagicLinkButton
                }

                VStack(alignment: .leading, spacing: .dsSpace3) {
                    sendMagicLinkButton
                    verifyMagicLinkButton
                }
            }

            HStack(spacing: .dsSpace3) {
                if authSessionStore.hasRefreshToken {
                    Button {
                        Task {
                            await authSessionStore.refreshSession()
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(authSessionStore.isAuthenticating)
                }

                Spacer()

                Button(role: .destructive) {
                    authSessionStore.signOut()
                    advancedToken = ""
                    magicLinkToken = ""
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .disabled(!authSessionStore.hasBearerToken && !authSessionStore.hasRefreshToken)
            }

            DisclosureGroup {
                VStack(alignment: .leading, spacing: .dsSpace3) {
                    SecureField("Bearer token", text: $advancedToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button {
                        authSessionStore.save(advancedToken)
                    } label: {
                        Label("Save Token", systemImage: "key")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, .dsSpace2)
            } label: {
                preferenceLabel(icon: "terminal", title: "Advanced")
            }

            if let sessionMessage = authSessionStore.sessionMessage {
                Text(sessionMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.dsMuted)
            }
        }
        .tint(.dsPrimary)
        .padding(.dsSpace5)
        .dsCardSurface()
    }

    private var sendMagicLinkButton: some View {
        Button {
            DogSwipeAnalytics.shared.trackAuthMagicLinkRequested()
            Task {
                await authSessionStore.requestMagicLink(email: email)
            }
        } label: {
            Label("Send Link", systemImage: "envelope")
        }
        .buttonStyle(.borderedProminent)
        .disabled(authSessionStore.isAuthenticating)
    }

    private var verifyMagicLinkButton: some View {
        Button {
            DogSwipeAnalytics.shared.trackAuthMagicLinkVerifySubmitted()
            Task {
                await authSessionStore.verifyMagicLink(token: magicLinkToken)
                magicLinkToken = ""
            }
        } label: {
            Label("Verify", systemImage: "checkmark.seal")
        }
        .disabled(authSessionStore.isAuthenticating)
    }

    private var sessionStatus: String {
        if let sessionEmail = authSessionStore.sessionEmail, !sessionEmail.isEmpty {
            return sessionEmail
        }
        if authSessionStore.hasBearerToken {
            return authSessionStore.hasRefreshToken ? "Connected" : "Token saved"
        }
        return "Signed out"
    }

    private var spicyFriendlyBinding: Binding<Bool> {
        Binding(
            get: { preferencesStore.spicyFriendly },
            set: { value in
                preferencesStore.spicyFriendly = value
                Task {
                    await preferencesStore.save()
                }
            }
        )
    }

    private var classicOnlyBinding: Binding<Bool> {
        Binding(
            get: { preferencesStore.classicOnly },
            set: { value in
                preferencesStore.classicOnly = value
                Task {
                    await preferencesStore.save()
                }
            }
        )
    }

    private var maxDistanceBinding: Binding<Double> {
        Binding(
            get: { preferencesStore.maxDistanceMiles },
            set: { preferencesStore.maxDistanceMiles = $0 }
        )
    }

    private func preferenceLabel(icon: String, title: String) -> some View {
        HStack(spacing: .dsSpace3) {
            Image(systemName: icon)
                .foregroundStyle(Color.dsPrimary)
                .frame(width: .dsSpace6)
            Text(title)
                .foregroundStyle(Color.dsInk)
        }
    }
}

#Preview {
    ProfileView()
}
