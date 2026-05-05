import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: .dsSpace5) {
                VStack(alignment: .leading, spacing: .dsSpace2) {
                    Text("Your preferences")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.dsInk)
                    Text("Tune the matching signal before the backend starts personalizing recommendations.")
                        .font(.body)
                        .foregroundStyle(Color.dsMuted)
                }

                VStack(spacing: .dsSpace4) {
                    preferenceRow(icon: "figure.run", title: "Active lifestyle", value: "On")
                    preferenceRow(icon: "building.2", title: "Apartment friendly", value: "Off")
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
