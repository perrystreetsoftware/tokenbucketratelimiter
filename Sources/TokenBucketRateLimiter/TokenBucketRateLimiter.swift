//
//  PSSTokenBucketRateLimiter.swift
//  Husband Material
//
//  Created by Kyle Rohr on 8/3/17.
//
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

            // debugLog("PSSRemoteRequestMeter tokens calc \(name): Tokens \(tokensAccrued); Delta: \(delta); Capacity: \(capacity); seconds since last request: \(secondsSinceLastRequest)")

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
        // debugLog("PSSRemoteRequestMeter \(name): Tokens \(tokens) consumed; Total tokens: \(tokensAccrued)")

            return false
        }

        tokensAccrued -= tokens

        // debugLog("PSSRemoteRequestMeter \(name): Tokens \(tokens) consumed; Total tokens: \(tokensAccrued)")

        return true
    }

    public var capacityRemaining: Float {
        return Float(tokensAccrued) / Float(self.capacity)
    }
}
