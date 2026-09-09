import Foundation
import XCTest

@testable import hazkey_server

final class ConfigurationTests: BaseHazkeyServerTestCase {

  func testSetCustomConfiguration() throws {
    let configResponse = try sendQuery(QueryBuilder.getConfig())
    XCTAssertEqual(configResponse.status, .success)
    guard var profile = configResponse.currentConfig.profiles.first else {
      XCTFail("No profile returned")
      return
    }

    profile = ProfileMutation.withKeymap(profile, name: "Fullwidth Comma", enabled: true)
    profile = ProfileMutation.withKeymap(profile, name: "Fullwidth Number", enabled: true)
    profile = ProfileMutation.withKeymap(profile, name: "Fullwidth Period", enabled: true)
    profile = ProfileMutation.withKeymap(profile, name: "Fullwidth Space", enabled: true)
    profile = ProfileMutation.withKeymap(profile, name: "Fullwidth Symbol", enabled: true)
    profile = ProfileMutation.withZenzai(profile, enabled: true, inferLimit: 5)

    let response = try sendQuery(QueryBuilder.setConfig(profiles: [profile]))

    XCTAssertEqual(response.status, .success, "Setting custom configuration should succeed")
    XCTAssertTrue(response.errorMessage.isEmpty, "Error message should be empty on success")
  }

  func testConfigurationPersistence() throws {
    // Set a custom configuration
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

    // Create new composing text instance to test persistence
    let instanceResponse = try sendQuery(QueryBuilder.newComposingText())
    XCTAssertEqual(instanceResponse.status, .success)

    // Input number and check if it's converted to fullwidth
    let inputResponse = try sendQuery(QueryBuilder.inputText("1"))
    XCTAssertEqual(inputResponse.status, .success)

    let stringResponse = try sendQuery(QueryBuilder.getComposingString())
    XCTAssertEqual(stringResponse.status, .success)

    // With fullwidth numbers enabled, "1" should become "１"
    XCTAssertEqual(
      stringResponse.text, "１",
      "Number should be converted to fullwidth when numberFullwidth is enabled")
  }
}
