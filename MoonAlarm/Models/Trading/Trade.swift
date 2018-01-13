//
//  Trade.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/9/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class Trade {
    
    let symbol: String
    var marketSnapshot: MarketSnapshot
    var updateTimer = Timer()
    
    var status: Status = .draft
    var enterPrice: Double = 0
    var exitPrice: Double = 0
    
    var startTime: Milliseconds = TradeSession.instance.exchangeClock.currentTime
    var endTime: Milliseconds? = nil
    // Track how long this trade has been active
    var duration: Milliseconds {
        if let eT = self.endTime {
            return eT - self.startTime
        } else {
            return TradeSession.instance.exchangeClock.currentTime - self.startTime
        }
    }
    
    init(symbol sym: String, snapshot: MarketSnapshot) {
        self.symbol = sym
        self.marketSnapshot = snapshot
    }
    
    convenience init(symbol sym: String) {
        self.init(symbol: sym, snapshot:  MarketSnapshot(symbol: sym))
    }
    
    var profit: Double {
        return exitPrice - enterPrice - (exitPrice * 0.002)
    }
    
    var profitPercent: Percent {
        return (self.profit / enterPrice).toPercent()
    }
    
    var wasProfitable: Bool {
        return self.profit > 0
    }
    
    func execute() {
        // don't get into any new trades if trade session has ended
        guard TradeSession.instance.status == .running,
              let currentPrice = marketSnapshot.currentPrice else { return }

        self.status = .open
        self.enterPrice = currentPrice
        startUpdatingData()
        print("\(self.symbol) trade started")
    }
    
    func terminate() {
        self.status = .complete
        self.exitPrice = marketSnapshot.currentPrice ?? 0
        self.stopUpdatingData()
        print("\(self.symbol) trade ended: \(self.profitPercent)% profit")
        print("Session Trades:\(TradeSession.instance.trades.countOnly(status: .complete)) Success: \(TradeSession.instance.trades.successRate)% Total Profit: \(TradeSession.instance.trades.totalProfitPercent)%")
    }
    
    func monitorAndTerminateIfAppropriate() {
        guard let currentPrice = marketSnapshot.currentPrice else { return }
        if currentPrice > (enterPrice * 1.01) || (currentPrice * 1.005) < enterPrice || self.duration.msToSeconds > 60 {
            terminate()
        }
    }
    
    private func startUpdatingData() {
        self.stopUpdatingData()
        self.updateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.marketSnapshot.updateData {
                self.monitorAndTerminateIfAppropriate()
            }
        }
    }
    
    private func stopUpdatingData() {
        self.updateTimer.invalidate()
    }
    
    enum Status: String {
        case draft = "Draft" // trade order hasn't been filled yet on market
        case open = "Open"  // trade has been at least partially filled
        case complete = "Complete"  // asset sold, trade is complete
    }
    
}
