import SwiftUI

struct ProfileView: View {
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

                VStack(spacing: .dsSpace4) {
                    preferenceRow(icon: "flame", title: "Spicy friendly", value: "On")
                    preferenceRow(icon: "checkmark.seal", title: "Classic only", value: "Off")
                    preferenceRow(icon: "location", title: "Search radius", value: "10 mi")
                }
                .padding(.dsSpace5)
                .dsCardSurface()

                Spacer()
            }
            .padding(.dsSpace5)
            .navigationTitle("Profile")
            .dsPageBackground()
        }
    }

    private func preferenceRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: .dsSpace3) {
            Image(systemName: icon)
                .foregroundStyle(Color.dsPrimary)
                .frame(width: .dsSpace6)
            Text(title)
                .foregroundStyle(Color.dsInk)
            Spacer()
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(Color.dsMuted)
        }
    }
}

#Preview {
    ProfileView()
}
