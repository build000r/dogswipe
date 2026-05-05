import SwiftUI

struct ProfileView: View {
    @ObservedObject private var preferencesStore: CravingPreferencesStore

    init(preferencesStore: CravingPreferencesStore = CravingPreferencesStore()) {
        self.preferencesStore = preferencesStore
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: .dsSpace5) {
                VStack(alignment: .leading, spacing: .dsSpace2) {
                    Text("Your cravings")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.dsInk)
                    Text("Tune the bite signal before the backend starts personalizing local picks.")
                        .font(.body)
                        .foregroundStyle(Color.dsMuted)
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
            .toolbar {
                if preferencesStore.isSyncing {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .dsPageBackground()
        }
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
