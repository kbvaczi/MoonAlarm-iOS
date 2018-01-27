//
//  Trade.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/9/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class Trade {
    
    let symbol: Symbol
    var marketSnapshot: MarketSnapshot
    var updateTimer = Timer()
    
    var status: Status = .draft
    var enterPrice: Price? = nil
    var exitPrice: Price? = nil
    
    var exitCriteria = TradeStrategy.instance.exitCriteria.copy()
    
    var startTime: Milliseconds = ExchangeClock.instance.currentTime
    var endTime: Milliseconds? = nil
    var duration: Milliseconds { // Track how long this trade has been active
        if let eT = self.endTime {
            return eT - self.startTime
        } else {
            return ExchangeClock.instance.currentTime - self.startTime
        }
    }
    
    enum Status: String {
        case draft = "Draft" // trade order hasn't been filled yet on market
        case open = "Open"  // trade has been at least partially filled
        case complete = "Complete"  // asset sold, trade is complete
    }
    
    ////////// INIT //////////
    
    init(symbol sym: Symbol, snapshot: MarketSnapshot) {
        self.symbol = sym
        self.marketSnapshot = snapshot
    }
    
    convenience init(symbol sym: Symbol) {
        self.init(symbol: sym, snapshot:  MarketSnapshot(symbol: sym))
    }
    
    ////////// PROFIT CALCULATIONS //////////
    
    var profit: Double? {
        let fee = TradeStrategy.instance.expectedFeePerTrade
        switch self.status {
        case .draft: return nil
        case .open:
            let pairQty = TradeStrategy.instance.tradeAmountTarget
            let orderBook = self.marketSnapshot.orderBook
            guard   let enterP = self.enterPrice,
                    let currentP = orderBook.marketSellPrice(forPairVolume: pairQty)
                    else { return nil }
            return currentP - enterP - (fee.percentToDouble * currentP)
        case .complete:
            guard   let enterP = self.enterPrice,
                    let exitP = self.exitPrice else { return nil }
            return exitP - enterP - (fee.percentToDouble * exitP)
        }
    }
    
    var profitPercent: Percent? {
        guard   let enterP = self.enterPrice,
                let profit = self.profit else { return nil }
        return (profit / enterP).doubleToPercent
    }
    
    var wasProfitable: Bool? {
        guard   let profit = self.profit else { return nil }
        return profit > 0
    }
    
    ////////// EXECUTE / TERMINATE //////////
    
    func execute() {
        let pairQty = TradeStrategy.instance.tradeAmountTarget
        let orderBook = self.marketSnapshot.orderBook
        
        // don't get into any new trades if trade session has ended
        guard   TradeSession.instance.status == .running,
        // trying lower entrance price to see if can maintain profit
        // TODO: Remove this
//                let buyPrice = orderBook.marketBuyPrice(forPairVolume: pairQty)
                let buyPrice = orderBook.topBidPrice
                else { return }

        self.status = .open
        self.enterPrice = buyPrice
        self.startUpdatingData()
        print("\(self.symbol) trade started")
    }
    
    func terminate() {
        self.status = .complete
        let pairQty = TradeStrategy.instance.tradeAmountTarget
        let orderBook = self.marketSnapshot.orderBook
        let marketSellPrice = orderBook.marketSellPrice(forPairVolume: pairQty)
        let currentPrice = marketSnapshot.currentPrice
        self.exitPrice = marketSellPrice ?? currentPrice ?? 0
        self.stopUpdatingData()
        
        let tradeProfitDisplay = (self.profitPercent != nil) ?
                                 String(self.profitPercent!.roundTo(1)) : "???"
        print("\(self.symbol) trade ended: \(tradeProfitDisplay)% profit")
        
        let tradesCount = TradeSession.instance.trades.countOnly(status: .complete)
        let successRate = TradeSession.instance.trades.successRate
        let sessionProfit = TradeSession.instance.trades.totalProfitPercent.roundTo(1)
        print("Session Trades:\(tradesCount) Success:\(successRate)% Profit:\(sessionProfit)%")
    }
    
    func monitorAndTerminateIfAppropriate() {
        if self.exitCriteria.onePassedFor(self) {
            terminate()
        }
    }
    
    ////////// DATA UPDATES //////////
    
    private func startUpdatingData() {
        self.stopUpdatingData()
        self.updateTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            self.marketSnapshot.updateData {
                self.monitorAndTerminateIfAppropriate()
            }
        }
    }
    
    private func stopUpdatingData() {
        self.updateTimer.invalidate()
    }

}
