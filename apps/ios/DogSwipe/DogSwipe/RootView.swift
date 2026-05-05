import DogSwipeCore
import SwiftUI

struct RootView: View {
    @StateObject private var authSessionStore: AuthSessionStore
    @StateObject private var preferencesStore: CravingPreferencesStore
    @StateObject private var vendorSubmissionStore: VendorSubmissionStore
    private let apiClient: DogSwipeAPIClient

    init(
        accessTokenStore: BearerTokenStoring = KeychainBearerTokenStore(),
        refreshTokenStore: BearerTokenStoring = KeychainBearerTokenStore(
            account: "spaps-refresh-token"
        ),
        authClient: SPAPSAuthClient = AppEnvironment.spapsAuthClient()
    ) {
        let apiClient = AppEnvironment.apiClient(tokenStore: accessTokenStore)
        self.apiClient = apiClient
        _authSessionStore = StateObject(
            wrappedValue: AuthSessionStore(
                accessTokenStore: accessTokenStore,
                refreshTokenStore: refreshTokenStore,
                authClient: authClient
            )
        )
        _preferencesStore = StateObject(
            wrappedValue: CravingPreferencesStore(apiClient: apiClient)
        )
        _vendorSubmissionStore = StateObject(
            wrappedValue: VendorSubmissionStore(apiClient: apiClient)
        )
    }

    var body: some View {
        TabView {
            DiscoverView(
                preferencesStore: preferencesStore,
                viewModel: DiscoverViewModel(
                    apiClient: apiClient,
                    preferencesStore: preferencesStore
                )
            )
                .tabItem {
                    Label("Discover", systemImage: "fork.knife.circle.fill")
                }

            MatchesView(
                preferencesStore: preferencesStore,
                viewModel: MatchesViewModel(
                    apiClient: apiClient,
                    preferencesStore: preferencesStore
                )
            )
                .tabItem {
                    Label("Matches", systemImage: "heart.fill")
                }

            VendorView(store: vendorSubmissionStore)
                .tabItem {
                    Label("Vendor", systemImage: "storefront")
                }

            ProfileView(
                preferencesStore: preferencesStore,
                authSessionStore: authSessionStore
            )
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(.dsPrimary)
        .task {
            authSessionStore.load()
            await preferencesStore.load()
        }
    }
}

#Preview {
    RootView()
}
