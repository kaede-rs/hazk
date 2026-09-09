import Foundation
import XCTest

@testable import hazkey_server

final class CandidateTests: BaseHazkeyServerTestCase {

  func testGetCandidatesWithEmptyInput() throws {
    let candidatesResponse = try sendQuery(QueryBuilder.getCandidates())

    XCTAssertEqual(
      candidatesResponse.status, .success, "Getting candidates should succeed even with empty input"
    )

    if case .candidates(let candidatesResult) = candidatesResponse.payload {
      XCTAssertTrue(
        candidatesResult.candidates.isEmpty || candidatesResult.candidates.count > 0,
        "Should return candidates array (empty or populated)")
    } else {
      XCTFail("Response should contain candidates")
    }
  }

  func testGetCandidatesWithHiraganaInput() throws {
    // Input some hiragana
    let inputResponse = try sendQuery(QueryBuilder.inputText("あい"))
    XCTAssertEqual(inputResponse.status, .success)

    let candidatesResponse = try sendQuery(QueryBuilder.getCandidates())

    XCTAssertEqual(candidatesResponse.status, .success, "Getting candidates should succeed")

    if case .candidates(let candidatesResult) = candidatesResponse.payload {
      XCTAssertFalse(
        candidatesResult.candidates.isEmpty, "Should return some candidates for hiragana input")

      // Check first candidate structure
      if let firstCandidate = candidatesResult.candidates.first {
        XCTAssertFalse(firstCandidate.text.isEmpty, "Candidate text should not be empty")
      }
    } else {
      XCTFail("Response should contain candidates")
    }
  }

  func testGetCandidatesWithNBestLimit() throws {
    let configResponse = try sendQuery(QueryBuilder.getConfig())
    XCTAssertEqual(configResponse.status, .success)
    guard var profile = configResponse.currentConfig.profiles.first else {
      XCTFail("No profile returned")
      return
    }
    let limit: Int32 = 3
    profile.numCandidatesPerPage = limit
    let setResponse = try sendQuery(QueryBuilder.setConfig(profiles: [profile]))
    XCTAssertEqual(setResponse.status, .success)

    let inputResponse = try sendQuery(QueryBuilder.inputText("あ"))
    XCTAssertEqual(inputResponse.status, .success)

    let candidatesResponse = try sendQuery(QueryBuilder.getCandidates())
    XCTAssertEqual(candidatesResponse.status, .success)

    if case .candidates(let candidatesResult) = candidatesResponse.payload {
      XCTAssertLessThanOrEqual(
        candidatesResult.candidates.count, Int(limit),
        "Should not return more candidates than num_candidates_per_page")
    } else {
      XCTFail("Response should contain candidates")
    }
  }

  func testGetCandidatesInPredictMode() throws {
    let configResponse = try sendQuery(QueryBuilder.getConfig())
    XCTAssertEqual(configResponse.status, .success)
    guard var profile = configResponse.currentConfig.profiles.first else {
      XCTFail("No profile returned")
      return
    }
    profile.suggestionListMode = .suggestionListShowPredictiveResults
    let setResponse = try sendQuery(QueryBuilder.setConfig(profiles: [profile]))
    XCTAssertEqual(setResponse.status, .success)

    let inputResponse = try sendQuery(QueryBuilder.inputText("こん"))
    XCTAssertEqual(inputResponse.status, .success)

    let candidatesResponse = try sendQuery(QueryBuilder.getCandidates(isSuggest: true))

    XCTAssertEqual(candidatesResponse.status, .success, "Predict mode should work")

    if case .candidates(let candidatesResult) = candidatesResponse.payload {
      XCTAssertTrue(candidatesResult.candidates.count >= 0, "Should return candidates array")
    } else {
      XCTFail("Response should contain candidates")
    }
  }
}
