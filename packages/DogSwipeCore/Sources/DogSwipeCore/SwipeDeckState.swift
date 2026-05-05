import Foundation

public struct SwipeDeckState: Equatable, Sendable {
    public private(set) var profiles: [HotdogProfile]
    public private(set) var history: [SwipeEvent]

    public init(profiles: [HotdogProfile], history: [SwipeEvent] = []) {
        self.profiles = profiles.filter { $0.availabilityStatus == .available }
        self.history = history
    }

    public var currentProfile: HotdogProfile? {
        profiles.first
    }

    public var remainingCount: Int {
        profiles.count
    }

    public var isEmpty: Bool {
        profiles.isEmpty
    }

    @discardableResult
    public mutating func record(_ decision: SwipeDecision, now: Date = Date()) -> SwipeEvent? {
        guard let profile = profiles.first else {
            return nil
        }
        profiles.removeFirst()
        let event = SwipeEvent(profileID: profile.id, decision: decision, createdAt: now)
        history.append(event)
        return event
    }

    @discardableResult
    public mutating func undo(from allProfiles: [HotdogProfile]) -> HotdogProfile? {
        guard let event = history.popLast(),
              let profile = allProfiles.first(where: { $0.id == event.profileID }) else {
            return nil
        }
        profiles.insert(profile, at: profiles.startIndex)
        return profile
    }

    public func positiveProfileIDs() -> Set<String> {
        Set(history.filter { $0.decision.isPositive }.map(\.profileID))
    }
}
