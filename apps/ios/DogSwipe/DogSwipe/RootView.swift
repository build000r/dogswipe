import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "pawprint.fill")
                }

            MatchesView()
                .tabItem {
                    Label("Matches", systemImage: "heart.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(.dsPrimary)
    }
}

#Preview {
    RootView()
}
