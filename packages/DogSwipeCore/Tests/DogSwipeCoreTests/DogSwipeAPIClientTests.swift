import Foundation
import XCTest
@testable import DogSwipeCore

private final class MockHTTPClient: DogSwipeHTTPClient, @unchecked Sendable {
    var requests: [URLRequest] = []
    var nextStatusCode = 200
    var nextData = Data()

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: nextStatusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (nextData, response)
    }
}

final class DogSwipeAPIClientTests: XCTestCase {
    func testDiscoveryDecodesSnakeCaseResponse() async throws {
        let http = MockHTTPClient()
        http.nextData = """
        {
          "profiles": [
            {
              "id": "dog-luna",
              "name": "Luna",
              "breed": "Australian Shepherd",
              "age_years": 2.5,
              "temperament": "Active",
              "distance_miles": 4.2,
              "shelter_name": "River North Rescue",
              "image_url": null,
              "compatibility_score": 0.91,
              "adoption_status": "available"
            }
          ]
        }
        """.data(using: .utf8)!
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        let profiles = try await client.discovery(limit: 10)

        XCTAssertEqual(profiles.map(\.id), ["dog-luna"])
        XCTAssertEqual(http.requests.first?.url?.path, "/v1/discovery")
        XCTAssertEqual(http.requests.first?.url?.query, "limit=10")
    }

    func testSwipeEncodesBackendContract() async throws {
        let http = MockHTTPClient()
        http.nextData = """
        {"profile_id":"dog-luna","decision":"super_like","matched":true}
        """.data(using: .utf8)!
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        let response = try await client.swipe(
            userID: "local-user",
            profileID: "dog-luna",
            decision: .superLike
        )

        XCTAssertEqual(response, SwipeResponse(profileID: "dog-luna", decision: .superLike, matched: true))
        XCTAssertEqual(http.requests.first?.httpMethod, "POST")
        let body = String(data: http.requests.first!.httpBody!, encoding: .utf8)!
        XCTAssertTrue(body.contains("\"user_id\":\"local-user\""))
        XCTAssertTrue(body.contains("\"profile_id\":\"dog-luna\""))
        XCTAssertTrue(body.contains("\"decision\":\"super_like\""))
    }

    func testMatchesAddsUserIDQuery() async throws {
        let http = MockHTTPClient()
        http.nextData = #"{"matches":[]}"#.data(using: .utf8)!
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        let matches = try await client.matches(userID: "local-user")

        XCTAssertTrue(matches.isEmpty)
        XCTAssertEqual(http.requests.first?.url?.path, "/v1/matches")
        XCTAssertEqual(http.requests.first?.url?.query, "user_id=local-user")
    }

    func testNonSuccessStatusThrowsAPIError() async {
        let http = MockHTTPClient()
        http.nextStatusCode = 503
        http.nextData = Data()
        let client = DogSwipeAPIClient(baseURL: URL(string: "http://localhost:8000")!, httpClient: http)

        do {
            _ = try await client.discovery()
            XCTFail("Expected request to throw")
        } catch let error as DogSwipeAPIError {
            XCTAssertEqual(error, .invalidResponseStatus(503))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
