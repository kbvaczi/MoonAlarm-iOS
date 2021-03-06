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
    let marketSnapshot: MarketSnapshot
    /// Criteria used for exiting trade, copied so we can modify without affecting other trades
    let exitCriteria = TradeSettings.instance.tradeStrategy.exitCriteria.copy()
    /// Used to keep track of whether trade is a draft, open, or complete
    var status: Status = .draft
    
    /// Target amount for this trade, expressed as trading pair amount
    let targetTradePairAmount = TradeSettings.instance.tradeAmountTarget
    /// Save the trading pair symbol for this trade
    let tradingPairSymbol = TradeSettings.instance.tradingPairSymbol
    /// Asset price when enter criteria triggers
    var targetEnterPrice: Price? = nil
    /// Asset price when exit criteria triggers
    var targetExitPrice: Price? = nil
    /// Actual enter price of trade based on buy order results
    var enterPrice: Price? {
        return self.buyOrderManager?.orders.avgfillPrice ?? self.targetEnterPrice
    }
    /// Actual exit price of trade based on sell order results
    var exitPrice: Price? {
        return self.sellOrderManager?.orders.avgfillPrice ?? self.targetExitPrice
    }
    
    /// Amount of coins purchased to date for this trade
    var amountTrading: Double? {
        guard   !self.isTest else {
            guard let enterPrice = self.targetEnterPrice else { return nil }
            let testTradeAmount = self.targetTradePairAmount / enterPrice
            return testTradeAmount
        }
        
        return self.buyOrderManager?.orders.amountFilled
    }
    
    /// Amount of trading pair spent to date on this trade
    var amountTradingPair: Double? {
        // If we are doing test trades, assume we always trade exactly target amount
        guard   !self.isTest else { return self.targetTradePairAmount }
        
        // Verify we have the data necessary to calculate amount trading for live trades
        guard   let amountTrading = self.amountTrading,
                let averageFillPrice = self.buyOrderManager?.orders.avgfillPrice
                else { return nil }
        
        // purchasedCoinAmount * $(pairAmount/coin) = purchasedPairAmount
        return amountTrading * averageFillPrice
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
    var sellOrderManager: SellOrderManager? = nil
    
    /// Used to trigger regular market snapshot updates
    private var updateTimer = Timer()
    /// How long to wait between updates
    let updateDelay: TimeInterval = 2
    
    /// Keep track of status of trade
    ///
    /// - draft: trade has not yet been submitted to exchange
    /// - entering: trade has been submitted, and is being tracked
    /// - entered: buy order has been filled, stop managing buy order
    /// - complete: trade has been finished, asset has been sold, no longer need to track
    enum Status: String {
        case draft = "Draft"
        case entering = "Entering"
        case entered = "Entered"
        case exiting = "Exiting"
        case complete = "Complete"
        
        /// Trade is not complete
        var isOpen: Bool { return self != .complete }
    }
    
    ////////// INIT //////////
    
    init(symbol sym: Symbol, snapshot: MarketSnapshot, isTest: Bool = true) {
        self.symbol = sym
        self.marketSnapshot = snapshot
        self.isTest = isTest
    }
    
    ////////// PROFIT CALCULATIONS //////////
    
    var profit: Double? {
        let fee = TradeSettings.instance.expectedFeePerTrade
        switch self.status {
        case .draft: return nil
        case .entering, .entered, .exiting:
            guard   let enterP = self.enterPrice,
                    let currentP = self.marketSnapshot.orderBook.topBidPrice
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
    
    ////////// ENTER / EXIT / TERMINATE //////////
    
    /// Enter a new trade, setup buy orders if live trading, and start tracking
    func enter() {
        
        // Gracefully handle repeat function calls
        guard   self.status == .draft else { return }
        
        NSLog("Trade(\(self.symbol)): Entered")
        
        let orderBook = self.marketSnapshot.orderBook
        
        // don't get into any new trades if trade session has ended
        guard   TradeSession.instance.status == .running,
                let buyPrice = orderBook.topBidPrice else {
            NSLog("Trade(\(self.symbol)): Error, cannot enter trade without market pricing")
            return
        }
        
        // If we're doing live trades, place and manage orders
        if self.isTest {
            self.status = .entered
        } else {
            let amountToBuy = self.targetTradePairAmount / buyPrice
            self.buyOrderManager = BuyOrderManager(price: buyPrice, amount: amountToBuy,
                                                   forTrade: self)
            self.buyOrderManager?.start()
            self.status = .entering
        }
        
        self.targetEnterPrice = buyPrice
        self.startRegularUpdates()
    }
    
    /// Exit a trade, setup sell orders if appropriate, continue tracking until exit complete
    @objc func exit() {
        
        // Gracefully handle repeat function calls
        guard   self.status.isOpen,
                self.status != .exiting else { return }
        
        let orderBook = self.marketSnapshot.orderBook
        let firstAskPrice = orderBook.firstAskPrice
        let currentPrice = marketSnapshot.currentPrice
        
        // verify we have price information
        guard   let sellPrice = firstAskPrice ?? currentPrice else {
            NSLog("Trade(\(self.symbol)): Error, cannot exit trade without market pricing")
            return
        }
        self.targetExitPrice = sellPrice
    
        if self.isTest {
            // No sale orders placed during testing, go ahead and complete trade
            self.complete()
        } else {
            // Cancel any open buy orders before proceeding to make sale orders
            self.buyOrderManager?.cancelOpenOrderAndStopBuying() { isSuccess in
                guard isSuccess else {
                    NSLog("Trade(\(self.symbol)): Error, unable to cancel open order")
                    let _ = Timer.scheduledTimer(timeInterval: 5.0, target: self,
                                                selector: #selector(self.exit),
                                                userInfo: nil, repeats: false)
                    return
                }
             
                // If we're doing live trading, place and manage sale orders
                guard   let amountToSell = self.amountTrading else {
                    NSLog("Trade(\(self.symbol)): Error, cannot sell without amount to trade")
                    return
                }
                self.sellOrderManager = SellOrderManager(price: sellPrice, amount: amountToSell,
                                                         forTrade: self)
                self.sellOrderManager?.start()
                self.status = .exiting  // Allows this trade to begin monitoring for completion
            }
        }
    }
    
    /// Trade has been exited, clean up, and stop tracking
    private func complete() {
        
        // Gracefully handle repeat function calls
        guard   self.status.isOpen else { return }
        
        // Cleanup
        self.status = .complete
        self.endTime = Date.currentTimeInMS
        self.stopRegularUpdates()
        TradeSettings.instance.updateBalances()         // update account balances
        
        // Log results
        let tradeProfitDisplay = (self.profitPercent != nil) ? self.profitPercent!.display1 : "???"
        NSLog("Trade(\(self.symbol)) Ended, \(tradeProfitDisplay)%% profit")
        let tradesCount = TradeSession.instance.trades.countOnly(status: .complete)
        let successRate = TradeSession.instance.trades.successRate.display1
        let sessionProfit = TradeSession.instance.trades.totalProfitPercent.display1
        NSLog("Session Trades:\(tradesCount) Success: \(successRate)%% Profit: \(sessionProfit)%%")
    }
    
    /// Monitor an trade and determine whether to exit/complete
    private func monitor() {
        switch self.status {
        case .entering:
            let buyingComplete = self.buyOrderManager?.status == .complete
            if buyingComplete { self.status = .entered }
            break
        case .entered:
            if self.exitCriteria.onePassedFor(self) { self.exit(); break }
        case .exiting:
            let sellingComplete = self.sellOrderManager?.status == .complete
            if sellingComplete { self.complete() }
        case .draft, .complete: break
        }
    }
    
    ////////// DATA UPDATES //////////
    
    private func startRegularUpdates() {
        self.updateTimer.invalidate()
        self.updateTimer = Timer.scheduledTimer(timeInterval: self.updateDelay, target: self,
                                                selector: #selector(self.regularUpdate),
                                                userInfo: nil, repeats: true)
    }
    
    @objc private func regularUpdate() {
        self.marketSnapshot.updateData {
            self.monitor()
        }
    }
    
    private func stopRegularUpdates() {
        self.updateTimer.invalidate()
    }

}
