import SwiftUI

struct RootView: View {
    @StateObject private var preferencesStore = CravingPreferencesStore()

    var body: some View {
        TabView {
            DiscoverView(preferencesStore: preferencesStore)
                .tabItem {
                    Label("Discover", systemImage: "fork.knife.circle.fill")
                }

            MatchesView(preferencesStore: preferencesStore)
                .tabItem {
                    Label("Matches", systemImage: "heart.fill")
                }

            ProfileView(preferencesStore: preferencesStore)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(.dsPrimary)
        .task {
            await preferencesStore.load()
        }
    }
}

#Preview {
    RootView()
}
