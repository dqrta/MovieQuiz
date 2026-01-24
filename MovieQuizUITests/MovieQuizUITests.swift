//
//  MovieQuizUITests.swift
//  MovieQuizUITests
//
//  Created by Kirill Pfisyazhnyuk on 24.01.2026.
//

import XCTest

final class MovieQuizUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        
        app = XCUIApplication()
        app.launch()
        continueAfterFailure = false
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }
    
    func testYesButton() throws {
        sleep(5)
        
        let firstPoster = app.images["Poster"]
        let firstPosterData = firstPoster.screenshot().pngRepresentation
        
        app.buttons["Yes"].tap()
        sleep(5)
        
        let secondPoster = app.images["Poster"]
        let secondPosterData = secondPoster.screenshot().pngRepresentation
        
        let indexLabel = app.staticTexts["Index"]
        
        XCTAssertEqual(indexLabel.label, "2/10")
        XCTAssertNotEqual(firstPosterData, secondPosterData)
    }
    
    func testNoButton() throws {
        sleep(5)
        
        let firstPoster = app.images["Poster"]
        let firstPosterData = firstPoster.screenshot().pngRepresentation
        
        app.buttons["No"].tap()
        sleep(5)
        
        let secondPoster = app.images["Poster"]
        let secondPosterData = secondPoster.screenshot().pngRepresentation
        
        let indexLabel = app.staticTexts["Index"]
        
        XCTAssertNotEqual(firstPosterData, secondPosterData)
        XCTAssertEqual(indexLabel.label, "2/10")
    }
    
    func testAlertFinish() throws {
        sleep(5)
        for _ in 1...10 {
            app.buttons["Yes"].tap()
            sleep(5)
        }
        
        let alert = app.alerts.firstMatch

        XCTAssertTrue(alert.exists)
        XCTAssertTrue(alert.label == "Раунд окончен")
        XCTAssertTrue(alert.buttons.firstMatch.label == "Сыграть еще раз!")
    }
    
    func testRestartGame() throws {
        sleep(5)
        for _ in 1...10 {
            app.buttons["Yes"].tap()
            sleep(5)
        }
        
        let alert = app.alerts.firstMatch
        alert.buttons.firstMatch.tap()
        
        sleep(5)
        
        let indexLabel = app.staticTexts["Index"]
        
        XCTAssertFalse(alert.exists)
        XCTAssert(indexLabel.label == "1/10")
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
    }
}
