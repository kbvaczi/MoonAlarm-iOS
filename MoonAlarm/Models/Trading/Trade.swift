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
    
    init(symbol sym: String, snapshot: MarketSnapshot) {
        self.symbol = sym
        self.marketSnapshot = snapshot
    }
    
    convenience init(symbol sym: String) {
        self.init(symbol: sym, snapshot:  MarketSnapshot(symbol: sym))
    }
    
    var profit: Double {
        return exitPrice - enterPrice
    }
    
    var profitPercent: Percent {
        return exitPrice / enterPrice
    }
    
    var wasProfitable: Bool {
        return self.profit > 0
    }
    
    func execute() {
        // don't get into any new trades if trade session has ended
        guard TradeSession.instance.status == .running else { return }

        self.status = .open
        self.enterPrice = marketSnapshot.currentPrice
        startUpdatingData()
        print("\(self.symbol) trade started")
    }
    
    func terminate() {
        self.status = .complete
        self.exitPrice = marketSnapshot.currentPrice
        self.stopUpdatingData()
        print("\(self.symbol) trade ended: \(self.profitPercent) profit")
        print("Session Success Rate: \(TradeSession.instance.trades.successRate)")
    }
    
    func monitorAndTerminateIfAppropriate() {
        if marketSnapshot.currentPrice > (enterPrice * 1.01) || (marketSnapshot.currentPrice * 1.01) < enterPrice {
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
