import XCTest
@testable import TokenBucketRateLimiter

final class EventTokenBucketRateLimiterTests: XCTestCase {
    func buildEventTokenBucketRateLimiter(capacity: Int,
                                          initialTokens: Int,
                                          fillRate: Double,
                                          name: String) -> EventTokenBucketRateLimiter {

        return EventTokenBucketRateLimiter(capacity: capacity,
                                   initialTokens: initialTokens,
                                   fillRate: fillRate,
                                   name: name)
    }

    func testHighInitialTokens() {
        let remoteRequestMeter =
            buildEventTokenBucketRateLimiter(capacity: 1,
                                             initialTokens: 3,
                                             fillRate: 0.1,
                                             name: "Test meter")

        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertFalse(remoteRequestMeter.consume())

        for _ in 0..<9 {
            remoteRequestMeter.recordEvent()
        }
        XCTAssertFalse(remoteRequestMeter.consume())

        remoteRequestMeter.recordEvent()
        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertFalse(remoteRequestMeter.consume())
    }

    func testNoInitialTokens() {
        let remoteRequestMeter =
            buildEventTokenBucketRateLimiter(capacity: 1,
                                             initialTokens: 0,
                                             fillRate: 0.5,
                                             name: "Test meter")
        XCTAssertFalse(remoteRequestMeter.consume())
        remoteRequestMeter.recordEvent()
        XCTAssertFalse(remoteRequestMeter.consume())
        remoteRequestMeter.recordEvent()
        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertFalse(remoteRequestMeter.consume())

        XCTAssertEqual(remoteRequestMeter.totalEventCount, 2)
    }

    func testAccrueMultipleTokens() {
        let remoteRequestMeter =
            buildEventTokenBucketRateLimiter(capacity: 2,
                                             initialTokens: 0,
                                             fillRate: 0.5,
                                             name: "Test meter")
        XCTAssertFalse(remoteRequestMeter.consume())
        remoteRequestMeter.recordEvent()
        remoteRequestMeter.recordEvent()
        remoteRequestMeter.recordEvent()
        remoteRequestMeter.recordEvent()
        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertFalse(remoteRequestMeter.consume())

        XCTAssertEqual(remoteRequestMeter.totalEventCount, 4)
    }

    func testRecordMultipleEvents() {
        let remoteRequestMeter =
            buildEventTokenBucketRateLimiter(capacity: 2,
                                             initialTokens: 0,
                                             fillRate: 0.5,
                                             name: "Test meter")

        XCTAssertFalse(remoteRequestMeter.consume())
        remoteRequestMeter.recordEvents(count: 2)
        XCTAssertTrue(remoteRequestMeter.consume())
    }

    static var allTests = [
        ("test high initial tokens", testHighInitialTokens),
        ("test no initial capacity", testNoInitialTokens),
        ("test accrue multiple tokens", testAccrueMultipleTokens),
        ("test record multiple events", testRecordMultipleEvents)
    ]
}

final class DateTokenBucketRateLimiterTests: XCTestCase {
    func buildDateTokenBucketRateLimiter(capacity: Int,
                                         initialTokens: Int,
                                         fillRate: Double,
                                         name: String,
                                         lastTokenCalculatedDate: Date = Date()) -> DateTokenBucketRateLimiter {

        return DateTokenBucketRateLimiter(capacity: capacity,
                                   initialTokens: initialTokens,
                                   fillRate: fillRate,
                                   name: name,
                                   lastTokenCalculatedDate: lastTokenCalculatedDate)
    }

    func testTimeUntilNextTokenStartOfEpoch() {
        // If our last token calculated date is "never", then the seconds until
        // our next token is going to be a random number that is always less than the fill rate
        let remoteRequestMeter = buildDateTokenBucketRateLimiter(capacity: 1, initialTokens: 0, fillRate: 1.0/30.0, name: "Test meter", lastTokenCalculatedDate: Date(timeIntervalSince1970: 0))

        XCTAssertLessThan(remoteRequestMeter.secondsUntilNextToken, 30.0)
    }

    func testTimeUntilNextToken() {
        let remoteRequestMeter = buildDateTokenBucketRateLimiter(capacity: 1, initialTokens: 0, fillRate: 1.0/30.0, name: "Test meter", lastTokenCalculatedDate: Date())

        let timeUntilNextTokenString = remoteRequestMeter.timeUntilNextToken
        switch timeUntilNextTokenString {
        case "30 seconds", "29 seconds":
            break
        default:
            XCTFail("Invalid time until next token")
        }
    }

    func testTokenCreatedLongAgoConsumeDoesNotImmediatelyFill() {
        // This is a limiter that was created 10 seconds ago
        let remoteRequestMeter = buildDateTokenBucketRateLimiter(capacity: 1, initialTokens: 1, fillRate: 0.1, name: "Test meter", lastTokenCalculatedDate: Date() - 10.0)
        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertFalse(remoteRequestMeter.consume())
    }

    func testHighInitialTokens() {
        let remoteRequestMeter = buildDateTokenBucketRateLimiter(capacity: 1, initialTokens: 3, fillRate: 2.0, name: "Test meter")
        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertFalse(remoteRequestMeter.consume())
        usleep(500005) // sleep for 500 milliseconds

        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertFalse(remoteRequestMeter.consume())
     }

     func testHighInitialCapacity() {
        let remoteRequestMeter = buildDateTokenBucketRateLimiter(capacity: 3, initialTokens: 1, fillRate: 3.0, name: "Test meter")
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
        let remoteRequestMeter = buildDateTokenBucketRateLimiter(capacity: 4, initialTokens: 1, fillRate: 2.0, name: "Test meter")
        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertFalse(remoteRequestMeter.consume())
        sleep(1)
        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertFalse(remoteRequestMeter.consume())
     }

     func testFasterFillRate2() {
        let remoteRequestMeter = buildDateTokenBucketRateLimiter(capacity: 4, initialTokens: 1, fillRate: 4.0, name: "Test meter")
        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertFalse(remoteRequestMeter.consume())
        usleep(250000) // sleep for 250 milliseconds
        // Our 4 tokens/sec fill rate means it only took 250 ms to get a token
        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertFalse(remoteRequestMeter.consume())
     }

     func testLastTokenCalculatedDate() {
        let oneSecondAgo = Date() - 1.0

        let remoteRequestMeter = buildDateTokenBucketRateLimiter(capacity: 1,
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
        let remoteRequestMeter = buildDateTokenBucketRateLimiter(capacity: 1, initialTokens: 0, fillRate: 4.0, name: "Test meter")
        XCTAssertFalse(remoteRequestMeter.canConsume())
        XCTAssertFalse(remoteRequestMeter.consume())
        XCTAssertFalse(remoteRequestMeter.canConsume())
        XCTAssertFalse(remoteRequestMeter.consume())

        // SOME KIND OF BUG CAUSES THE FIRST USLEEP TO BE IGNORED
        usleep(1000) // sleep for 100 microseconds
        usleep(250000) // sleep for 250 milliseconds

        // Our 4 tokens/sec fill rate means it only took 250 ms to get a token
        XCTAssertTrue(remoteRequestMeter.canConsume())
        XCTAssertTrue(remoteRequestMeter.consume())
        XCTAssertFalse(remoteRequestMeter.canConsume())
        XCTAssertFalse(remoteRequestMeter.consume())
     }

    func testOverrideLastCalculatedDate() {
        let remoteRequestMeter = buildDateTokenBucketRateLimiter(capacity: 1, initialTokens: 0, fillRate: 4.0, name: "Test meter")
        XCTAssertFalse(remoteRequestMeter.canConsume())
        remoteRequestMeter.lastTokenCalculatedDate = Date() - 5.0
        XCTAssertTrue(remoteRequestMeter.canConsume())
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
