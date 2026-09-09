import Foundation
import XCTest

@testable import hazkey_server

final class ErrorHandlingTests: BaseHazkeyServerTestCase {

  func testInvalidCharacterTypeInGetComposingString() throws {
    // First input some text
    let inputResponse = try sendQuery(QueryBuilder.inputText("あ"))
    XCTAssertEqual(inputResponse.status, .success)

    // Try to get composing string with invalid character type
    var request = Hazkey_RequestEnvelope()
    request.getComposingString.charType = .UNRECOGNIZED(999)  // Invalid char type

    let response = try sendQuery(request)
    XCTAssertEqual(response.status, .failed, "Invalid character type should result in failure")
    XCTAssertFalse(
      response.errorMessage.isEmpty, "Should provide error message for invalid character type")
  }

  func testMultipleComposingTextInstanceCreation() throws {
    // Create first instance
    let firstResponse = try sendQuery(QueryBuilder.newComposingText())
    XCTAssertEqual(firstResponse.status, .success)

    // Add some input
    let inputResponse = try sendQuery(QueryBuilder.inputText("test"))
    XCTAssertEqual(inputResponse.status, .success)

    // Create second instance (should reset the first one)
    let secondResponse = try sendQuery(QueryBuilder.newComposingText())
    XCTAssertEqual(secondResponse.status, .success)

    // Check that composing text is reset
    let stringResponse = try sendQuery(QueryBuilder.getComposingString())
    XCTAssertEqual(stringResponse.status, .success)
    XCTAssertEqual(stringResponse.text, "", "New instance should have empty composing text")
  }

  func testLargeInputString() throws {
    // Test with a very long string
    let largeString = String(repeating: "あ", count: 1000)

    // Note: The server only processes the first Unicode character
    let inputResponse = try sendQuery(QueryBuilder.inputText(largeString))
    XCTAssertEqual(inputResponse.status, .success, "Large input should succeed")

    let stringResponse = try sendQuery(QueryBuilder.getComposingString())
    XCTAssertEqual(stringResponse.status, .success)
    XCTAssertEqual(stringResponse.text, "あ", "Should only process first character")
  }
}
