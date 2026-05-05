import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "fork.knife.circle.fill")
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
