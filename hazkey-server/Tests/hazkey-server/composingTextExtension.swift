import Foundation
import XCTest

@testable import hazkey_server

final class TextInputTests: BaseHazkeyServerTestCase {

  func testBasicHiraganaInput() throws {
    let inputResponse = try sendQuery(QueryBuilder.inputText("あ"))
    XCTAssertEqual(inputResponse.status, .success, "Hiragana input should succeed")

    let stringResponse = try sendQuery(QueryBuilder.getComposingString(charType: .hiragana))
    XCTAssertEqual(stringResponse.status, .success)
    XCTAssertEqual(stringResponse.text, "あ", "Should return the input hiragana character")
  }

  func testMultipleCharacterInput() throws {
    let characters = ["あ", "い", "う"]

    for char in characters {
      let response = try sendQuery(QueryBuilder.inputText(char))
      XCTAssertEqual(response.status, .success, "Input of '\(char)' should succeed")
    }

    let stringResponse = try sendQuery(QueryBuilder.getComposingString(charType: .hiragana))
    XCTAssertEqual(stringResponse.status, .success)
    XCTAssertEqual(stringResponse.text, "あいう", "Should concatenate multiple hiragana characters")
  }

  func testDirectInput() throws {
    let shiftPressResponse = try sendQuery(QueryBuilder.shiftKeyEvent(isRelease: false))
    XCTAssertEqual(shiftPressResponse.status, .success)

    let inputResponse = try sendQuery(QueryBuilder.inputText("A"))
    XCTAssertEqual(inputResponse.status, .success, "Direct input should succeed")

    let stringResponse = try sendQuery(QueryBuilder.getComposingString(charType: .hiragana))
    XCTAssertEqual(stringResponse.status, .success)
    XCTAssertEqual(
      stringResponse.text, "A", "Direct input should preserve the original character")
  }

  func testEmptyStringInput() throws {
    let inputResponse = try sendQuery(QueryBuilder.inputText(""))
    // This should fail because empty string doesn't have a first unicode character
    XCTAssertEqual(inputResponse.status, .failed, "Empty string input should fail")
    XCTAssertFalse(
      inputResponse.errorMessage.isEmpty, "Should provide error message for empty input")
  }

  func testNumericInputWithFullwidthConfiguration() throws {
    // Enable the "Fullwidth Number" built-in keymap for this profile
    let configResponse = try sendQuery(QueryBuilder.getConfig())
    XCTAssertEqual(configResponse.status, .success)
    guard var profile = configResponse.currentConfig.profiles.first else {
      XCTFail("No profile returned")
      return
    }
    profile = ProfileMutation.withKeymap(profile, name: "Fullwidth Number", enabled: true)
    let setResponse = try sendQuery(QueryBuilder.setConfig(profiles: [profile]))
    XCTAssertEqual(setResponse.status, .success)

    // Create new instance to apply config
    let instanceResponse = try sendQuery(QueryBuilder.newComposingText())
    XCTAssertEqual(instanceResponse.status, .success)

    let inputResponse = try sendQuery(QueryBuilder.inputText("123"))
    XCTAssertEqual(inputResponse.status, .success)

    let stringResponse = try sendQuery(QueryBuilder.getComposingString(charType: .hiragana))
    XCTAssertEqual(stringResponse.status, .success)
    XCTAssertEqual(stringResponse.text, "１", "Only first character should be processed")
  }

  func testCharacterTypeConversion() throws {
    let inputResponse = try sendQuery(QueryBuilder.inputText("あ"))
    XCTAssertEqual(inputResponse.status, .success)

    // Test different character type outputs
    let testCases: [(Hazkey_Commands_GetComposingString.CharType, String)] = [
      (.hiragana, "あ"),
      (.katakanaFull, "ア"),
      (.katakanaHalf, "ｱ"),
    ]

    for (charType, expected) in testCases {
      let stringResponse = try sendQuery(QueryBuilder.getComposingString(charType: charType))
      XCTAssertEqual(stringResponse.status, .success)
      XCTAssertEqual(
        stringResponse.text, expected,
        "Character type \(charType) should return \(expected)")
    }
  }
}
