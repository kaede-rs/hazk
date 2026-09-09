import Foundation
import XCTest

@testable import hazkey_server

class BaseHazkeyServerTestCase: XCTestCase {
  var client: HazkeyServerClient!
  private var savedProfile: Hazkey_Config_Profile?

  override func setUpWithError() throws {
    try super.setUpWithError()

    // Ensure server is running
    XCTAssertTrue(
      TestUtilities.waitForServer(),
      "Server socket did not appear within timeout. Make sure the hazkey-server is running."
    )

    // Create and connect client
    client = HazkeyServerClient()
    try client.connect()

    // Initialize server state
    try initializeServerState()
  }

  override func tearDownWithError() throws {
    if let saved = savedProfile {
      _ = try? client.sendQuery(QueryBuilder.setConfig(profiles: [saved]))
    }
    client?.disconnect()
    client = nil
    try super.tearDownWithError()
  }

  private func initializeServerState() throws {
    let configResponse = try client.sendQuery(QueryBuilder.getConfig())
    XCTAssertEqual(configResponse.status, .success, "Failed to fetch current configuration")
    guard let originalProfile = configResponse.currentConfig.profiles.first else {
      XCTFail("Server returned no profile")
      return
    }
    savedProfile = originalProfile

    var baseline = originalProfile
    for name in [
      "Fullwidth Number", "Fullwidth Symbol", "Fullwidth Period",
      "Fullwidth Comma", "Fullwidth Space",
    ] {
      baseline = ProfileMutation.withKeymap(baseline, name: name, enabled: false)
    }
    baseline.zenzaiEnable = false

    let setResponse = try client.sendQuery(QueryBuilder.setConfig(profiles: [baseline]))
    XCTAssertEqual(setResponse.status, .success, "Failed to set baseline configuration")

    // Create composing text instance
    let instanceResponse = try client.sendQuery(QueryBuilder.newComposingText())
    XCTAssertEqual(instanceResponse.status, .success, "Failed to create composing text instance")
  }

  // Helper method for sending queries with better error reporting
  func sendQuery(
    _ query: Hazkey_RequestEnvelope,
    file: StaticString = #file,
    line: UInt = #line
  ) throws -> Hazkey_ResponseEnvelope {
    do {
      return try client.sendQuery(query)
    } catch {
      XCTFail("Failed to send query: \(error)", file: file, line: line)
      throw error
    }
  }
}
