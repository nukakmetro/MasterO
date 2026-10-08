import XCTest

@MainActor
final class CheckTukUITests: XCTestCase {
    func testMainWindowSidebarAndSettingsCanBeOpened() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        app.activate()

        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["sidebar.left"].waitForExistence(timeout: 5))

        app.buttons["slider.horizontal.3"].tap()
        XCTAssertTrue(app.staticTexts["Настройки"].waitForExistence(timeout: 5))
        app.buttons["Закрыть настройки"].tap()
    }

    func testCreateApplicationAndOpenTipsWindow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        app.activate()

        let addButton = app.buttons["Создать первое"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10))
        addButton.tap()

        let nameField = app.textFields["Например, CheckTuk"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("UI тест")
        app.buttons["Создать приложение"].tap()
        XCTAssertTrue(app.staticTexts["UI тест"].waitForExistence(timeout: 5))

        app.buttons["Подсказки"].tap()
        XCTAssertTrue(app.windows["Подсказки"].waitForExistence(timeout: 5))
    }
}
