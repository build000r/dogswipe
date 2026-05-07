import SwiftUI

struct SwipeActionButton: View {
    enum Role {
        case rewind
        case pass
        case like
        case superLike
        case filter

        var iconName: String {
            switch self {
            case .rewind:
                "arrow.counterclockwise"
            case .pass:
                "xmark"
            case .like:
                "heart.fill"
            case .superLike:
                "fork.knife.circle.fill"
            case .filter:
                "slider.horizontal.3"
            }
        }

        var tint: Color {
            switch self {
            case .rewind:
                .dsPrimary
            case .pass:
                .dsAccent
            case .like:
                .dsRelish
            case .superLike:
                .dsSuper
            case .filter:
                .dsMuted
            }
        }

        var background: Color {
            switch self {
            case .superLike:
                .dsSurface
            default:
                .dsSurface
            }
        }

        var size: CGFloat {
            switch self {
            case .superLike:
                72
            default:
                58
            }
        }
    }

    let role: Role
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: role.iconName)
                .font(role == .superLike ? .title.weight(.semibold) : .title3.weight(.bold))
                .foregroundStyle(role.tint)
                .frame(width: role.size, height: role.size)
                .background(role.background)
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(Color.dsDivider)
                }
                .shadow(color: Color.dsShadow, radius: 8, x: 0, y: 5)
                .contentShape(Circle())
                .accessibilityLabel(Text(accessibilityLabel))
        }
        .buttonStyle(.plain)
    }

    private var accessibilityLabel: String {
        switch role {
        case .rewind:
            "Start over"
        case .pass:
            "Pass"
        case .like:
            "Like"
        case .superLike:
            "Super like"
        case .filter:
            "Search menu"
        }
    }
}
