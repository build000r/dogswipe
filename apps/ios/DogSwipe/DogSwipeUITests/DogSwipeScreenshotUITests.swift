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

        tapTab("Matches", screenIdentifier: "dogswipe.matches.screen")
        XCTAssertTrue(app.staticTexts["Coney Classic"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Garden Snap"].exists)
        attachScreenshot(named: "02-matches")

        tapTab("Vendor", screenIdentifier: "dogswipe.vendor.screen")
        XCTAssertTrue(app.staticTexts["Submit a hotdog"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Your submissions"].exists)
        attachScreenshot(named: "03-vendor")

        tapTab("Review", screenIdentifier: "dogswipe.review.screen")
        XCTAssertTrue(app.staticTexts["Pending vendor hotdogs"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Approve"].exists)
        attachScreenshot(named: "04-review")

        tapTab("Profile", screenIdentifier: "dogswipe.profile.screen")
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

    private func tapTab(_ title: String, screenIdentifier: String) {
        let screen = app.descendants(matching: .any)[screenIdentifier]
        if screen.exists {
            return
        }

        for _ in 0..<3 {
            let tab = app.tabBars.buttons[title]
            XCTAssertTrue(tab.waitForExistence(timeout: 3), "\(title) tab did not appear")
            tab.tap()
            if screen.waitForExistence(timeout: 3) {
                return
            }
            tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            if screen.waitForExistence(timeout: 3) {
                return
            }
        }
        XCTFail("\(title) tab did not open \(screenIdentifier)")
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
