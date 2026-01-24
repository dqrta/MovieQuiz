import XCTest
@testable import MovieQuiz

class ArrayTests: XCTestCase {
    func testGetValueInRange() throws {
        let array = [1, 2, 3, 4, 5]
        
        let value = array[safe: 3]
        
        XCTAssertNotNil(value)
        XCTAssertEqual(value, 4)
    }
    
    func testGetValueOutOfRange() throws {
        let array = [1, 2, 3, 4, 5]
        
        let value = array[safe: 8]
        
        XCTAssertNil(value)
    }
}
