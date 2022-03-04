

import XCTest
@testable import Selfiegram

class DataLoadingTests: XCTestCase {

    override func setUpWithError() throws {
        
        let cacheURL = OverlayManager.cacheDirectoryURL
        
        guard let contents = try?
                FileManager.default.contentsOfDirectory(
                    at: cacheURL,
                    includingPropertiesForKeys: nil,
                    options: []) else {
                        XCTFail("Failed to list contents of directory \(cacheURL)")
                        return
                    }
        var complete = true
        for file in contents {
            do {
                try FileManager.default.removeItem(at: file)
            } catch let error {
                NSLog("Test setup: failed to remove item \(file); \(error)")
                complete = false
            }
        }
        if !complete {
            XCTFail("Failed to delete contents of cache")
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testNoOverlaysAvailable() {
        // Arrange
        
        // Act
        let availableOverlays = OverlayManager.shared.availableOverlays()
        
        // Assert
        XCTAssertEqual(availableOverlays.count, 0)
    }
    
    func testGettingOverlayInfo() {
        // Arrange
        let expectation = self.expectation(description: "Done downloading")
        
        // Act
        var loadedInfo: OverlayManager.OverlayList?
        var loadedError: Error?
        
        OverlayManager.shared.refreshOverlays { info, error in
            loadedInfo = info
            loadedError = error
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
        
        // Assert
        XCTAssertNotNil(loadedInfo)
        XCTAssertNil(loadedError)
    }
    
    func testDownloadingOverlays() {
        // Arrange
        let loadingComplete = self.expectation(description: "Download done")
        var availableOverlays: [Overlay] = []
        
        // Act
        OverlayManager.shared.loadOverlayAssets(refresh: true) {
            availableOverlays = OverlayManager.shared.availableOverlays()
            loadingComplete.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
        
        //Assert
        XCTAssertNotEqual(availableOverlays.count, 0)
    }
    
    func testDownloadedOverlaysAreCached() {
        // Arrange
        let downloadingOverlayManager = OverlayManager()
        let downloadExpectation = self.expectation(description: "Data downloaded")
        downloadingOverlayManager.loadOverlayAssets(refresh: true) {
            downloadExpectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
        
        // Act
        let cacheTestOverlayManager = OverlayManager()
        
        // Assert
        XCTAssertNotEqual(cacheTestOverlayManager.availableOverlays().count, 0)
        XCTAssertEqual(cacheTestOverlayManager.availableOverlays().count, downloadingOverlayManager.availableOverlays().count)
    }
}
