import DogSwipeCore
import SwiftUI

private enum RootTab: String, Hashable {
    case discover
    case matches
    case vendor
    case review
    case profile

    static var initial: RootTab {
        guard AppEnvironment.isScreenshotMode,
              let value = ProcessInfo.processInfo.environment["DOGSWIPE_INITIAL_TAB"] else {
            return .discover
        }
        return RootTab(rawValue: value) ?? .discover
    }
}

struct RootView: View {
    @State private var selectedTab: RootTab
    @StateObject private var authSessionStore: AuthSessionStore
    @StateObject private var preferencesStore: CravingPreferencesStore
    @StateObject private var vendorSubmissionStore: VendorSubmissionStore
    @StateObject private var adminReviewStore: AdminReviewStore
    @StateObject private var orderStore: OrderStore
    private let apiClient: DogSwipeAPIClient

    init(
        accessTokenStore: BearerTokenStoring = AppEnvironment.accessTokenStore(),
        refreshTokenStore: BearerTokenStoring = AppEnvironment.refreshTokenStore(),
        authClient: SPAPSAuthClient = AppEnvironment.spapsAuthClient()
    ) {
        let apiClient = AppEnvironment.apiClient(tokenStore: accessTokenStore)
        self.apiClient = apiClient
        _selectedTab = State(initialValue: RootTab.initial)
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
        _adminReviewStore = StateObject(
            wrappedValue: AdminReviewStore(apiClient: apiClient)
        )
        _orderStore = StateObject(wrappedValue: OrderStore())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverView(
                orderStore: orderStore,
                preferencesStore: preferencesStore,
                viewModel: DiscoverViewModel(
                    apiClient: apiClient,
                    preferencesStore: preferencesStore
                )
            )
                .tabItem {
                    Label("Discover", systemImage: "fork.knife.circle.fill")
                }
                .tag(RootTab.discover)

            MatchesView(
                orderStore: orderStore,
                preferencesStore: preferencesStore,
                viewModel: MatchesViewModel(
                    apiClient: apiClient,
                    preferencesStore: preferencesStore
                ),
                onKeepSwiping: {
                    selectedTab = .discover
                }
            )
                .tabItem {
                    Label("Matches", systemImage: "heart.fill")
                }
                .tag(RootTab.matches)

            VendorView(store: vendorSubmissionStore)
                .tabItem {
                    Label("Vendor", systemImage: "storefront")
                }
                .tag(RootTab.vendor)

            AdminReviewView(store: adminReviewStore)
                .tabItem {
                    Label("Review", systemImage: "checkmark.seal.fill")
                }
                .tag(RootTab.review)

            ProfileView(
                preferencesStore: preferencesStore,
                authSessionStore: authSessionStore
            )
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(RootTab.profile)
        }
        .tint(.dsPrimary)
        .accessibilityIdentifier("dogswipe.root")
        .task {
            authSessionStore.load()
            await preferencesStore.load()
        }
        .onOpenURL { url in
            Task {
                await authSessionStore.handleDeepLink(url)
            }
        }
    }
}

#Preview {
    RootView()
}
