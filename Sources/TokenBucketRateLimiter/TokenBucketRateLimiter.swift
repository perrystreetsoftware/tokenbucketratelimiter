//
// DateTokenBucketRateLimiter.swift
//
// MIT License
// Copyright (c) 2020 Perry Street Software, Inc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation

public class DateTokenBucketRateLimiter: TokenBucketRateLimiter {
    private var lastTokenCalculatedDate: Date

    public init(capacity: Int,
         initialTokens: Int,
         fillRate: Double,
         name: String,
         lastTokenCalculatedDate: Date = Date()) {
        self.lastTokenCalculatedDate = lastTokenCalculatedDate

        super.init(capacity: capacity, initialTokens: initialTokens, fillRate: fillRate, name: name)
    }

    public override func resetCalculatedEvents() {
        self.lastTokenCalculatedDate = Date()
    }

    internal override func calculateEventsSinceLastRequest() -> Double {
        return Date().timeIntervalSince(self.lastTokenCalculatedDate)
    }

    public func overrideLastTokenCalculatedDate(with consumptionDate: Date) {
        self.lastTokenCalculatedDate = consumptionDate
    }

    public override func recordEvent() {
        // no-op; this happens by default as time elapses
    }
}

public class EventTokenBucketRateLimiter: TokenBucketRateLimiter {
    private var totalEvents: Int = 0

    public override func resetCalculatedEvents() {
        self.totalEvents = 0
    }

    internal override func calculateEventsSinceLastRequest() -> Double {
        return Double(self.totalEvents)
    }

    public override func recordEvent() {
        self.totalEvents += 1
    }
}

public class TokenBucketRateLimiter {
    public static let maxBurstConsumptionRate: Int = defaultCapacity / 2
    public static let defaultCapacity: Int = 30
    public static let defaultFillRate: Double = 2.0

    public var defaultConsumptionRate = 1

    private var totalCurrentRequests: Int = 0
    private var maxConcurrentRequests: Int = 0
    private var maxTimeToWaitForResponse: Int = 0
    private var capacity: Int = 0
    private var fillRate: Double = 0.0
    private var name: String
    private var tokensAccrued: Int = 0

    internal func calculateEventsSinceLastRequest() -> Double {
        fatalError("Must override in subclass")
    }

    public func resetCalculatedEvents()  {
        fatalError("Must override in subclass")
    }

    public func recordEvent()  {
        fatalError("Must override in subclass")
    }

    private func recalculateTokens() -> Int {
        let eventsSinceLastRequest = self.calculateEventsSinceLastRequest()

        if tokensAccrued < capacity {
            let delta: Double = fillRate * eventsSinceLastRequest
            tokensAccrued = min(capacity, Int(floor(Double(tokensAccrued) + delta)))

            print("TokenBucketRateLimiter tokens calc \(name): Tokens \(tokensAccrued); Delta: \(delta); Capacity: \(capacity); seconds since last request: \(eventsSinceLastRequest)")

            if tokensAccrued > 0 {
                resetCalculatedEvents()
            }
        }

        return tokensAccrued
    }

    public init(capacity: Int,
                initialTokens: Int,
                fillRate: Double,
                name: String) {
        self.name = name
        self.capacity = capacity
        self.tokensAccrued = initialTokens
        self.fillRate = fillRate
    }

    @discardableResult public func consume() -> Bool {
        return consume(defaultConsumptionRate)
    }

    public func canConsume() -> Bool {
        return canConsumeExactly(1)
    }

    public func canConsumeExactly(_ tokens: Int = 1) -> Bool {
        // Uses our accessor, which regenerates tokens
        guard tokens <= self.recalculateTokens() else {
            return false
        }

        return true
    }

    public func consume(_ tokens: Int) -> Bool {
        // Uses our accessor, which regenerates tokens
        guard canConsumeExactly(tokens) else {
        // print("TokenBucketRateLimiter \(name): Tokens \(tokens) consumed; Total tokens: \(tokensAccrued)")

            return false
        }

        tokensAccrued -= tokens

        // print("TokenBucketRateLimiter \(name): Tokens \(tokens) consumed; Total tokens: \(tokensAccrued)")

        return true
    }

    public var capacityRemaining: Float {
        return Float(tokensAccrued) / Float(self.capacity)
    }
}
