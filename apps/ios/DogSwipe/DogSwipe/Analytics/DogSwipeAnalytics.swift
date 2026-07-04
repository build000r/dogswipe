import Foundation
import OSLog

struct DogSwipeAnalyticsEvent: Equatable {
    let name: String
    let parameters: [String: String]
}

protocol DogSwipeAnalyticsSink {
    func record(_ event: DogSwipeAnalyticsEvent)
}

struct DogSwipeLoggerAnalyticsSink: DogSwipeAnalyticsSink {
    private let logger = Logger(subsystem: "com.build000r.dogswipe", category: "analytics")

    func record(_ event: DogSwipeAnalyticsEvent) {
        logger.info("analytics_event name=\(event.name, privacy: .public)")
    }
}

@MainActor
final class DogSwipeAnalytics {
    enum Screen: String {
        case discover
        case matches
        case orders
        case vendor
        case review
        case wallet
        case profile
    }

    static let shared = DogSwipeAnalytics()

    private var sink: DogSwipeAnalyticsSink

    init(sink: DogSwipeAnalyticsSink = DogSwipeLoggerAnalyticsSink()) {
        self.sink = sink
    }

    func replaceSinkForTesting(_ sink: DogSwipeAnalyticsSink) {
        self.sink = sink
    }

    func trackScreenViewed(_ screen: Screen) {
        emit(
            name: "ios_screen_viewed",
            parameters: [
                "screen": screen.rawValue
            ]
        )
    }

    func trackDiscoverySwipe(decision: String, profileID: String) {
        emit(
            name: "ios_discovery_swipe",
            parameters: [
                "decision": decision,
                "profile_id": profileID
            ]
        )
    }

    func trackAuthMagicLinkRequested() {
        emit(
            name: "ios_auth_magic_link_requested",
            parameters: [
                "method": "email_magic_link"
            ]
        )
    }

    func trackAuthMagicLinkVerifySubmitted() {
        emit(
            name: "ios_auth_magic_link_verify_submitted",
            parameters: [
                "method": "email_magic_link"
            ]
        )
    }

    func trackOrderCTA(profileID: String) {
        emit(
            name: "ios_order_cta_tapped",
            parameters: [
                "profile_id": profileID
            ]
        )
    }

    func trackMatchKeepSwiping(profileID: String) {
        emit(
            name: "ios_match_keep_swiping_tapped",
            parameters: [
                "profile_id": profileID
            ]
        )
    }

    private func emit(name: String, parameters: [String: String]) {
        sink.record(DogSwipeAnalyticsEvent(name: name, parameters: parameters))
    }
}
