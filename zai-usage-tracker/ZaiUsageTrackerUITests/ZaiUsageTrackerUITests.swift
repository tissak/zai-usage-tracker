//
//  ZaiUsageTrackerUITests.swift
//  ZaiUsageTrackerUITests
//
//  Created by Tony Issakov on 2/18/26.
//

import XCTest

final class ZaiUsageTrackerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTakeScreenshot() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Ensure app is active
        app.activate()
        
        // Wait for app launch
        sleep(2)
        
        // Find the status item
        let statusItem = app.statusItems.firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 10), "Menu bar item not found")
        
        // Click using coordinate to avoid "not hittable" issues
        statusItem.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        
        // Wait for the popover window
        // Note: MenuBarExtra windows might appear as standard windows, sheets, or dialogs
        // Strategy: Find the dialog/window that contains the "Z.ai Usage Tracker" text
        // Based on debug output, it appears as a "Dialog"
        let popover = app.dialogs.containing(.staticText, identifier: "Z.ai Usage Tracker").firstMatch
        
        if popover.waitForExistence(timeout: 5) {
            let screenshot = popover.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "PopoverScreenshot"
            attachment.lifetime = .keepAlways
            add(attachment)
        } else {
            // Fallback: Try windows if dialogs fail
            let window = app.windows.containing(.staticText, identifier: "Z.ai Usage Tracker").firstMatch
            if window.waitForExistence(timeout: 2) {
                 let screenshot = window.screenshot()
                 let attachment = XCTAttachment(screenshot: screenshot)
                 attachment.name = "PopoverScreenshot"
                 attachment.lifetime = .keepAlways
                 add(attachment)
            } else {
                // Fallback: Take screenshot of the app itself
                let appScreenshot = app.screenshot()
                let attachment = XCTAttachment(screenshot: appScreenshot)
                attachment.name = "PopoverScreenshot"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }
}
