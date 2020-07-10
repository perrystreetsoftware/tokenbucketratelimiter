import XCTest
@testable import TokenBucketRateLimiter

final class TokenBucketRateLimiterTests: XCTestCase {
    func testHighInitialTokens() {
         let remoteRequestMeter = TokenBucketRateLimiter(capacity: 1, initialTokens: 3, fillRate: 2.0, name: "Test meter")
         XCTAssertTrue(remoteRequestMeter.consume())
         XCTAssertTrue(remoteRequestMeter.consume())
         XCTAssertTrue(remoteRequestMeter.consume())
         XCTAssertFalse(remoteRequestMeter.consume())
         usleep(500000) // sleep for 500 milliseconds
         XCTAssertTrue(remoteRequestMeter.consume())
         XCTAssertFalse(remoteRequestMeter.consume())
     }

     func testHighInitialCapacity() {
         let remoteRequestMeter = TokenBucketRateLimiter(capacity: 3, initialTokens: 1, fillRate: 3.0, name: "Test meter")
         XCTAssertTrue(remoteRequestMeter.consume())
         XCTAssertFalse(remoteRequestMeter.consume())
         usleep(333334) // sleep for 333 milliseconds
         XCTAssertTrue(remoteRequestMeter.consume())
         XCTAssertFalse(remoteRequestMeter.consume())
         sleep(1)
         XCTAssertTrue(remoteRequestMeter.consume())
         XCTAssertTrue(remoteRequestMeter.consume())
         XCTAssertTrue(remoteRequestMeter.consume())
         XCTAssertFalse(remoteRequestMeter.consume())
     }

     func testFasterFillRate() {
         let remoteRequestMeter = TokenBucketRateLimiter(capacity: 4, initialTokens: 1, fillRate: 2.0, name: "Test meter")
         XCTAssertTrue(remoteRequestMeter.consume())
         XCTAssertFalse(remoteRequestMeter.consume())
         sleep(1)
         XCTAssertTrue(remoteRequestMeter.consume())
         XCTAssertTrue(remoteRequestMeter.consume())
         XCTAssertFalse(remoteRequestMeter.consume())
     }

     func testFasterFillRate2() {
         let remoteRequestMeter = TokenBucketRateLimiter(capacity: 4, initialTokens: 1, fillRate: 4.0, name: "Test meter")
         XCTAssertTrue(remoteRequestMeter.consume())
         XCTAssertFalse(remoteRequestMeter.consume())
         usleep(250000) // sleep for 250 milliseconds
         // Our 4 tokens/sec fill rate means it only took 250 ms to get a token
         XCTAssertTrue(remoteRequestMeter.consume())
         XCTAssertFalse(remoteRequestMeter.consume())
     }

     func testLastTokenCalculatedDate() {
         let oneSecondAgo = Date() - 1.0

         let remoteRequestMeter = TokenBucketRateLimiter(capacity: 1,
                                                        initialTokens: 0,
                                                        fillRate: 1.0,
                                                        name: "Test meter",
                                                        lastTokenCalculatedDate: oneSecondAgo)
         XCTAssertTrue(remoteRequestMeter.consume())
         XCTAssertFalse(remoteRequestMeter.consume())

         usleep(250000) // sleep for 250 milliseconds
         XCTAssertFalse(remoteRequestMeter.consume())

         usleep(250000) // sleep for 250 milliseconds
         XCTAssertFalse(remoteRequestMeter.consume())

         usleep(250000) // sleep for 250 milliseconds
         XCTAssertFalse(remoteRequestMeter.consume())

         usleep(250000) // sleep for 250 milliseconds
         XCTAssertTrue(remoteRequestMeter.consume())
     }

     func testCanConsume() {
         let remoteRequestMeter = TokenBucketRateLimiter(capacity: 1, initialTokens: 0, fillRate: 4.0, name: "Test meter")
         XCTAssertFalse(remoteRequestMeter.canConsume())
         XCTAssertFalse(remoteRequestMeter.consume())
         XCTAssertFalse(remoteRequestMeter.canConsume())
         XCTAssertFalse(remoteRequestMeter.consume())
         usleep(250000) // sleep for 250 milliseconds

         // Our 4 tokens/sec fill rate means it only took 250 ms to get a token
         XCTAssertTrue(remoteRequestMeter.canConsume())
         XCTAssertTrue(remoteRequestMeter.consume())
         XCTAssertFalse(remoteRequestMeter.canConsume())
         XCTAssertFalse(remoteRequestMeter.consume())
     }

    static var allTests = [
        ("test high initial tokens", testHighInitialTokens),
        ("test high initial capacity", testHighInitialCapacity),
        ("test faster fill rate", testFasterFillRate),
        ("test faster fill rate 2", testFasterFillRate2),
        ("test last token calculated date", testLastTokenCalculatedDate),
        ("test can consume", testCanConsume)
    ]
}
