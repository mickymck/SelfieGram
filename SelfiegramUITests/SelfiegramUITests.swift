

import XCTest

class SelfiegramUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        
        XCUIApplication().activate()
        
        let app = XCUIApplication()
        let currentSelfieCount = app.tables.element(boundBy: 0).cells.count
        
        app.terminate()
        app.launch()
        
        let tables = app.tables.element(boundBy: 0)
        
        XCTAssertEqual(currentSelfieCount, tables.cells.count)
    }
    
    func testPhotos() {
        
        addUIInterruptionMonitor(withDescription: "Camera Permission Dialog") { alert -> Bool in
            alert.buttons["OK"].tap()
            return true
        }
        
        XCUIApplication().activate()
        
        let app = XCUIApplication()
        
        let currentSelfieCount = app.tables.element(boundBy: 0).cells.count
        
        app.navigationBars["Selfies"].buttons["Add"].tap()
        app.windows.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0).tap()
        app.navigationBars["Selfiegram.EditingView"].buttons["Done"].tap()
        
        let tables = app.tables.element(boundBy: 0)
        
        XCTAssertEqual(currentSelfieCount, tables.cells.count + 1)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
