import Foundation
import XCTest

@testable import hazkey_server

final class IntegrationTests: BaseHazkeyServerTestCase {

  func testCompleteInputWorkflow() throws {
    // 1. Create composing text instance
    let instanceResponse = try sendQuery(QueryBuilder.newComposingText())
    XCTAssertEqual(instanceResponse.status, .success)

    // 2. Input multiple characters
    let inputChars = ["こ", "ん", "に", "ち", "は"]
    for char in inputChars {
      let inputResponse = try sendQuery(QueryBuilder.inputText(char))
      XCTAssertEqual(inputResponse.status, .success, "Input of '\(char)' should succeed")
    }

    // 3. Get composing string
    let stringResponse = try sendQuery(QueryBuilder.getComposingString(charType: .hiragana))
    XCTAssertEqual(stringResponse.status, .success)
    XCTAssertEqual(stringResponse.text, "こんにちは", "Should compose complete hiragana string")

    // 4. Get candidates
    let candidatesResponse = try sendQuery(QueryBuilder.getCandidates())
    XCTAssertEqual(candidatesResponse.status, .success)

    if case .candidates(let candidatesResult) = candidatesResponse.payload {
      XCTAssertFalse(candidatesResult.candidates.isEmpty, "Should return candidates for 'こんにちは'")

      // Check if we get "こんにちは" or "今日は" as candidates
      let candidateTexts = candidatesResult.candidates.map { $0.text }
      XCTAssertTrue(
        candidateTexts.contains("こんにちは") || candidateTexts.contains("今日は"),
        "Should contain greeting candidates")
    } else {
      XCTFail("Should receive candidates")
    }
  }

  func testNumberAndSymbolConversion() throws {
    // Configure for fullwidth conversion
    let configResponse = try sendQuery(QueryBuilder.getConfig())
    XCTAssertEqual(configResponse.status, .success)
    guard var profile = configResponse.currentConfig.profiles.first else {
      XCTFail("No profile returned")
      return
    }
    profile = ProfileMutation.withKeymap(profile, name: "Fullwidth Number", enabled: true)
    profile = ProfileMutation.withKeymap(profile, name: "Fullwidth Symbol", enabled: true)
    let setResponse = try sendQuery(QueryBuilder.setConfig(profiles: [profile]))
    XCTAssertEqual(setResponse.status, .success)

    let instanceResponse = try sendQuery(QueryBuilder.newComposingText())
    XCTAssertEqual(instanceResponse.status, .success)

    // Test number conversion
    let numberResponse = try sendQuery(QueryBuilder.inputText("5"))
    XCTAssertEqual(numberResponse.status, .success)

    let numberStringResponse = try sendQuery(QueryBuilder.getComposingString())
    XCTAssertEqual(numberStringResponse.status, .success)
    XCTAssertEqual(numberStringResponse.text, "５", "Number should be converted to fullwidth")
  }

  func testMultipleSessionsSequentially() throws {
    // Session 1
    let session1Response = try sendQuery(QueryBuilder.newComposingText())
    XCTAssertEqual(session1Response.status, .success)

    let session1InputResponse = try sendQuery(QueryBuilder.inputText("あ"))
    XCTAssertEqual(session1InputResponse.status, .success)

    // Session 2 (new instance)
    let session2Response = try sendQuery(QueryBuilder.newComposingText())
    XCTAssertEqual(session2Response.status, .success)

    // Session 2 should have clean state
    let session2StringResponse = try sendQuery(QueryBuilder.getComposingString())
    XCTAssertEqual(session2StringResponse.status, .success)
    XCTAssertEqual(session2StringResponse.text, "", "New session should start with empty state")
  }
}
