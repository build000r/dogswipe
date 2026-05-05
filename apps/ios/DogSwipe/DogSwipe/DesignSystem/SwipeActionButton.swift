import SwiftUI

struct SwipeActionButton: View {
    enum Role {
        case pass
        case like
        case superLike

        var iconName: String {
            switch self {
            case .pass:
                "xmark"
            case .like:
                "heart.fill"
            case .superLike:
                "star.fill"
            }
        }

        var tint: Color {
            switch self {
            case .pass:
                .dsMuted
            case .like:
                .dsPrimary
            case .superLike:
                .dsAccent
            }
        }
    }

    let role: Role
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: role.iconName)
                .font(.headline)
                .foregroundStyle(role.tint)
                .frame(width: .dsSpace8, height: .dsSpace8)
                .background(Color.dsSurface)
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(Color.dsDivider)
                }
                .contentShape(Circle())
                .accessibilityLabel(Text(accessibilityLabel))
        }
        .buttonStyle(.plain)
    }

    private var accessibilityLabel: String {
        switch role {
        case .pass:
            "Pass"
        case .like:
            "Like"
        case .superLike:
            "Super like"
        }
    }
}
