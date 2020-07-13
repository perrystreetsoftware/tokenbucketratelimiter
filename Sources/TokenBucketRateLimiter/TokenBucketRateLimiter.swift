//
// TokenBucketRateLimiter.swift
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

public class TokenBucketRateLimiter {
    public static let maxBurstConsumptionRate: Int = defaultCapacity / 2
    private static let defaultCapacity: Int = 30
    private static let defaultFillRate: Double = 2.0

    public var defaultConsumptionRate = 1

    private var totalCurrentRequests: Int = 0
    private var maxConcurrentRequests: Int = 0
    private var maxTimeToWaitForResponse: Int = 0
    private var capacity: Int = 0
    private var fillRate: Double = 0.0
    private var name: String
    private var lastTokenCalculatedDate: Date
    private var tokensAccrued: Int = 0

    private func recalculateTokens() -> Int {
        let now = Date()
        let secondsSinceLastRequest: TimeInterval = -1 * self.lastTokenCalculatedDate.timeIntervalSince(now)

        if tokensAccrued < capacity {
            let delta: Double = TimeInterval(fillRate) * secondsSinceLastRequest
            tokensAccrued = min(capacity, Int(floor(Double(tokensAccrued) + delta)))

            // print("TokenBucketRateLimiter tokens calc \(name): Tokens \(tokensAccrued); Delta: \(delta); Capacity: \(capacity); seconds since last request: \(secondsSinceLastRequest)")

            if tokensAccrued > 0 {
                self.lastTokenCalculatedDate = Date()
            }
        }

        return tokensAccrued
    }

    public init(capacity: Int,
         initialTokens: Int,
         fillRate: Double,
         name: String,
         lastTokenCalculatedDate: Date = Date()) {
        self.name = name
        self.lastTokenCalculatedDate = lastTokenCalculatedDate
        self.capacity = capacity
        self.tokensAccrued = initialTokens
        self.fillRate = fillRate
    }

    convenience public init(name: String) {
        self.init(capacity: type(of: self).defaultCapacity,
                  initialTokens: type(of: self).defaultCapacity,
                  fillRate: type(of: self).defaultFillRate,
                  name: name,
                  lastTokenCalculatedDate: Date())
    }

    @discardableResult public func consume() -> Bool {
        return consume(defaultConsumptionRate)
    }

    public func canConsume(_ tokens: Int = 1) -> Bool {
        // Uses our accessor, which regenerates tokens
        guard tokens <= self.recalculateTokens() else {
            return false
        }

        return true
    }

    public func overrideLastTokenCalculatedDate(with consumptionDate: Date) {
        self.lastTokenCalculatedDate = consumptionDate
    }

    public func consume(_ tokens: Int) -> Bool {
        // Uses our accessor, which regenerates tokens
        guard canConsume(tokens) else {
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
