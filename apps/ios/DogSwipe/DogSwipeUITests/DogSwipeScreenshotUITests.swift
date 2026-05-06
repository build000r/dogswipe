import XCTest

final class DogSwipeScreenshotUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testHotdogWorkflowScreenshots() {
        launch(tab: "discover")
        waitFor(identifier: "dogswipe.discover.screen")
        XCTAssertTrue(app.staticTexts["Best nearby bite"].exists)
        XCTAssertTrue(app.staticTexts["Coney Classic"].waitForExistence(timeout: 3))
        attachScreenshot(named: "01-discover")

        launch(tab: "matches")
        waitFor(identifier: "dogswipe.matches.screen")
        XCTAssertTrue(app.staticTexts["Coney Classic"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Garden Snap"].exists)
        attachScreenshot(named: "02-matches")

        launch(tab: "vendor")
        waitFor(identifier: "dogswipe.vendor.screen")
        XCTAssertTrue(app.staticTexts["Submit a hotdog"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Your submissions"].exists)
        attachScreenshot(named: "03-vendor")

        launch(tab: "review")
        waitFor(identifier: "dogswipe.review.screen")
        XCTAssertTrue(app.staticTexts["Pending vendor hotdogs"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Approve"].exists)
        attachScreenshot(named: "04-review")

        launch(tab: "profile")
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
