import XCTest

final class DogSwipeScreenshotUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        app = XCUIApplication()
        app.launchArguments = [
            AppLaunchArguments.screenshotMode,
            "-AppleLanguages",
            "(en)",
            "-AppleLocale",
            "en_US"
        ]
        app.launchEnvironment["DOGSWIPE_SCREENSHOT_MODE"] = "1"
        app.launch()
    }

    func testHotdogWorkflowScreenshots() {
        waitFor(identifier: "dogswipe.discover.screen")
        XCTAssertTrue(app.staticTexts["Best nearby bite"].exists)
        XCTAssertTrue(app.staticTexts["Coney Classic"].waitForExistence(timeout: 3))
        attachScreenshot(named: "01-discover")

        tapTab("Matches")
        waitFor(identifier: "dogswipe.matches.screen")
        XCTAssertTrue(app.staticTexts["Coney Classic"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Garden Snap"].exists)
        attachScreenshot(named: "02-matches")

        tapTab("Vendor")
        waitFor(identifier: "dogswipe.vendor.screen")
        XCTAssertTrue(app.staticTexts["Submit a hotdog"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Your submissions"].exists)
        attachScreenshot(named: "03-vendor")

        tapTab("Review")
        waitFor(identifier: "dogswipe.review.screen")
        XCTAssertTrue(app.staticTexts["Pending vendor hotdogs"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Approve"].exists)
        attachScreenshot(named: "04-review")

        tapTab("Profile")
        waitFor(identifier: "dogswipe.profile.screen")
        XCTAssertTrue(app.staticTexts["Your cravings"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Signed out"].exists)
        attachScreenshot(named: "05-profile")
    }

    @discardableResult
    private func waitFor(identifier: String, timeout: TimeInterval = 5) -> XCUIElement {
        let element = app.descendants(matching: .any)[identifier]
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "\(identifier) did not appear")
        return element
    }

    private func tapTab(_ title: String) {
        let tab = app.tabBars.buttons[title]
        XCTAssertTrue(tab.waitForExistence(timeout: 3), "\(title) tab did not appear")
        tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
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
