//
//  Trade.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/9/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class Trade {
    
    /// Symbol for asset we are trading
    let symbol: Symbol
    /// No assets purchased/sold on test trades
    let isTest: Bool
    /// Market info we track for trade
    var marketSnapshot: MarketSnapshot
    /// Criteria used for exiting trade, copied so we can modify without affecting other trades
    let exitCriteria = TradeStrategy.instance.exitCriteria.copy()
    /// Used to keep track of whether trade is a draft, open, or complete
    var status: Status = .draft
    
    /// Asset price when enter criteria triggers
    var targetEnterPrice: Price? = nil
    /// Asset price when exit criteria triggers
    var targetExitPrice: Price? = nil
    /// Actual enter price of trade based on buy order results
    var enterPrice: Price? {
        return self.isTest ? self.targetEnterPrice : self.buyOrderManager?.orders.avgfillPrice
    }
    /// Actual exit price of trade based on sell order results
    var exitPrice: Price? {
        return self.isTest ? self.targetExitPrice : self.sellOrders.avgfillPrice
    }
    
    /// Amount of coins purchased to date for this trade
    var amountTrading: Double? {
        if self.isTest {
            guard let enterPrice = targetEnterPrice else { return nil }
            let testTradeAmount = TradeStrategy.instance.tradeAmountTarget / enterPrice
            return testTradeAmount
        }
        
        return self.buyOrderManager?.orders.amountFilled
    }
    
    /// When trade started
    var startTime: Milliseconds = Date.currentTimeInMS  // When trade started
    /// When trade ended, nil if still open
    var endTime: Milliseconds? = nil
    /// How long trade has been active
    var duration: Milliseconds {
        if let eT = self.endTime {
            return eT - self.startTime
        } else {
            return Date.currentTimeInMS - self.startTime
        }
    }
    
    /// Orders placed to buy asset for this trade
    var buyOrderManager: BuyOrderManager? = nil
    /// Orders placed to sell asset
    var sellOrders: TradeOrders = []
    
    /// Used to trigger regular market snapshot updates
    private var updateTimer = Timer()                           // For updating market info
    
    /// Keep track of status of trade
    ///
    /// - draft: trade has not yet been submitted to exchange
    /// - open: trade has been submitted, and is being tracked
    /// - complete: trade has been finished, asset has been sold, no longer need to track
    enum Status: String {
        case draft = "Draft"
        case open = "Open"
        case complete = "Complete"
    }
    
    ////////// INIT //////////
    
    init(symbol sym: Symbol, snapshot: MarketSnapshot, isTest: Bool = true) {
        self.symbol = sym
        self.marketSnapshot = snapshot
        self.isTest = isTest
    }
    
    ////////// PROFIT CALCULATIONS //////////
    
    var profit: Double? {
        let fee = TradeStrategy.instance.expectedFeePerTrade
        switch self.status {
        case .draft: return nil
        case .open:
            let orderBook = self.marketSnapshot.orderBook
            guard   let enterP = self.enterPrice,
                    let currentP = orderBook.firstAskPrice
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
        
        NSLog("\(self.symbol) trade started")
        
        let orderBook = self.marketSnapshot.orderBook
        
        // don't get into any new trades if trade session has ended
        guard   TradeSession.instance.status == .running,
                let buyPrice = orderBook.topBidPrice
                else { return }

        // If we're not testing, place and manage orders
        if !self.isTest {
            let amountToBuy = TradeStrategy.instance.tradeAmountTarget / buyPrice
            self.buyOrderManager = BuyOrderManager(price: buyPrice, amount: amountToBuy,
                                                   forTrade: self)
            self.buyOrderManager?.execute()
        }
        
        self.status = .open
        self.targetEnterPrice = buyPrice
        self.startRegularUpdates()
        
    }
    
    func terminate() {
        self.status = .complete
        let orderBook = self.marketSnapshot.orderBook
        let firstAsk = orderBook.firstAskPrice
        let currentPrice = marketSnapshot.currentPrice
        self.targetExitPrice = firstAsk ?? currentPrice ?? 0
        
        // TODO: execute sell order and manage?
        
        self.stopRegularUpdates()
                
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
    
    private func startRegularUpdates() {
        self.updateTimer.invalidate()
        self.updateTimer = Timer.scheduledTimer(timeInterval: 3, target: self,
                                                selector: #selector(self.regularUpdate),
                                                userInfo: nil, repeats: true)
    }
    
    @objc func regularUpdate() {
        self.marketSnapshot.updateData {
            self.monitorAndTerminateIfAppropriate()
        }
    }
    
    private func stopRegularUpdates() {
        self.updateTimer.invalidate()
    }

}
