import XCTest

final class DogSwipeScreenshotUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func test01DiscoverScreenshot() {
        captureScreenshot(
            tab: "discover",
            screenIdentifier: "dogswipe.discover.screen",
            requiredElements: [
                .staticText("Tonight's craving"),
                .staticText("Chicago Classic"),
                .button("Live walk"),
                .button("Directions")
            ],
            screenshotName: "01-discover"
        )
    }

    func test02MatchesScreenshot() {
        captureScreenshot(
            tab: "matches",
            screenIdentifier: "dogswipe.matches.screen",
            requiredElements: [
                .staticText("Build the order"),
                .staticText("Garden Snap")
            ],
            screenshotName: "02-matches"
        )
    }

    func test03VendorScreenshot() {
        captureScreenshot(
            tab: "vendor",
            screenIdentifier: "dogswipe.vendor.screen",
            requiredElements: [
                .staticText("Submit a hotdog"),
                .staticText("Your submissions")
            ],
            screenshotName: "03-vendor"
        )
    }

    func test04ReviewScreenshot() {
        captureScreenshot(
            tab: "review",
            screenIdentifier: "dogswipe.review.screen",
            requiredElements: [
                .staticText("Pending vendor hotdogs"),
                .button("Approve")
            ],
            screenshotName: "04-review"
        )
    }

    func test05ProfileScreenshot() {
        captureScreenshot(
            tab: "profile",
            screenIdentifier: "dogswipe.profile.screen",
            requiredElements: [
                .staticText("Your cravings"),
                .staticText("Signed out")
            ],
            screenshotName: "05-profile"
        )
    }

    func test05WalletScreenshot() {
        captureScreenshot(
            tab: "wallet",
            screenIdentifier: "dogswipe.wallet.screen",
            requiredElements: [
                .staticText("Wallet"),
                .staticText("Balance")
            ],
            screenshotName: "05-wallet"
        )
    }

    func test06DiscoverCardSwipesAdvanceDeck() {
        launch(tab: "discover")
        waitFor(identifier: "dogswipe.discover.screen", timeout: 20, screenshotName: "06-discover-swipe")
        waitFor(.staticText("Chicago Classic"), timeout: 20, screenshotName: "06-discover-swipe")

        swipe(from: CGVector(dx: 0.25, dy: 0.48), to: CGVector(dx: 0.90, dy: 0.44))
        waitFor(.staticText("Kimchi Crunch"), timeout: 8, screenshotName: "06-discover-swipe-right")

        swipe(from: CGVector(dx: 0.75, dy: 0.48), to: CGVector(dx: 0.10, dy: 0.44))
        waitFor(.staticText("Garden Snap"), timeout: 8, screenshotName: "06-discover-swipe-left")
    }

    func test07DiscoverExhaustedDeckHidesSwipeControls() {
        launch(tab: "discover")
        waitFor(identifier: "dogswipe.discover.screen", timeout: 20, screenshotName: "07-discover-complete")
        waitFor(.staticText("Chicago Classic"), timeout: 20, screenshotName: "07-discover-complete")

        for _ in 0..<4 {
            swipe(from: CGVector(dx: 0.25, dy: 0.48), to: CGVector(dx: 0.90, dy: 0.44))
            Thread.sleep(forTimeInterval: 0.35)
        }

        waitFor(.staticText("You reviewed every hotdog"), timeout: 8, screenshotName: "07-discover-complete")
        XCTAssertFalse(app.staticTexts["Swipe right for hotdogs"].exists)
        XCTAssertFalse(app.buttons["Pass"].exists)
        XCTAssertFalse(app.buttons["Like"].exists)
        XCTAssertTrue(app.buttons["Restart deck"].isEnabled)
        attachScreenshot(named: "07-discover-complete")
    }

    func test08MatchAddToOrderUpdatesCTA() {
        launch(tab: "matches")
        waitFor(identifier: "dogswipe.matches.screen", timeout: 20, screenshotName: "08-match-order")
        waitFor(.button("Bacon"), timeout: 20, screenshotName: "08-match-order").tap()
        waitFor(.button("Add to Order"), timeout: 20, screenshotName: "08-match-order").tap()
        waitFor(.button("Added to Order"), timeout: 8, screenshotName: "08-match-order")
        waitFor(identifier: "dogswipe.order.confirmation", timeout: 8, screenshotName: "08-match-order")
    }

    func test09OrdersScreenshot() {
        captureScreenshot(
            tab: "orders",
            screenIdentifier: "dogswipe.orders.screen",
            requiredElements: [
                .staticText("My Orders"),
                .staticText("Chicago Classic"),
                .staticText("9 credits")
            ],
            screenshotName: "08-orders"
        )
    }

    private func captureScreenshot(
        tab: String,
        screenIdentifier: String,
        requiredElements: [RequiredElement],
        screenshotName: String
    ) {
        launch(tab: tab)
        waitFor(identifier: screenIdentifier, timeout: 20, screenshotName: screenshotName)
        for element in requiredElements {
            waitFor(element, timeout: 20, screenshotName: screenshotName)
        }
        attachScreenshot(named: screenshotName)
    }

    @discardableResult
    private func waitFor(
        identifier: String,
        timeout: TimeInterval,
        screenshotName: String
    ) -> XCUIElement {
        let element = app.descendants(matching: .any)[identifier]
        if !element.waitForExistence(timeout: timeout) {
            attachScreenshot(named: "\(screenshotName)-failure")
            XCTFail("\(identifier) did not appear")
        }
        return element
    }

    @discardableResult
    private func waitFor(
        _ requiredElement: RequiredElement,
        timeout: TimeInterval,
        screenshotName: String
    ) -> XCUIElement {
        let element = requiredElement.resolve(in: app)
        if !element.waitForExistence(timeout: timeout) {
            attachScreenshot(named: "\(screenshotName)-failure")
            XCTFail("\(requiredElement.name) did not appear")
        }
        return element
    }

    private func launch(tab: String) {
        if let runningApp = app, runningApp.state != .notRunning {
            runningApp.terminate()
        }
        app = XCUIApplication()
        app.launchArguments = [
            AppLaunchArguments.screenshotMode,
            "-AppleLanguages",
            "(en)",
            "-AppleLocale",
            "en_US"
        ]
        app.launchEnvironment["DOGSWIPE_SCREENSHOT_MODE"] = "1"
        app.launchEnvironment["DOGSWIPE_INITIAL_TAB"] = tab
        app.launch()
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func swipe(from start: CGVector, to end: CGVector) {
        let startCoordinate = app.coordinate(withNormalizedOffset: start)
        let endCoordinate = app.coordinate(withNormalizedOffset: end)
        startCoordinate.press(forDuration: 0.05, thenDragTo: endCoordinate)
    }
}

private enum AppLaunchArguments {
    static let screenshotMode = "--dogswipe-screenshot-mode"
}

private enum RequiredElement {
    case staticText(String)
    case button(String)

    var name: String {
        switch self {
        case .staticText(let label):
            return "static text \"\(label)\""
        case .button(let label):
            return "button \"\(label)\""
        }
    }

    func resolve(in app: XCUIApplication) -> XCUIElement {
        switch self {
        case .staticText(let label):
            return app.staticTexts[label]
        case .button(let label):
            return app.buttons[label]
        }
    }
}
