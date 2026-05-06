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
                .staticText("DogSwipe"),
                .staticText("Chicago Classic")
            ],
            screenshotName: "01-discover"
        )
    }

    func test02MatchesScreenshot() {
        captureScreenshot(
            tab: "matches",
            screenIdentifier: "dogswipe.matches.screen",
            requiredElements: [
                .staticText("It's a Match!"),
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

    private func waitFor(
        _ requiredElement: RequiredElement,
        timeout: TimeInterval,
        screenshotName: String
    ) {
        let element = requiredElement.resolve(in: app)
        if !element.waitForExistence(timeout: timeout) {
            attachScreenshot(named: "\(screenshotName)-failure")
            XCTFail("\(requiredElement.name) did not appear")
        }
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
