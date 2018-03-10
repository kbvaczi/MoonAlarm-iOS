//
//  TradeSession.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/9/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TradeSession {
    
    static let instance = TradeSession() // singleton
    private init() { } // prohibit instances of this class from being declared
    
    // Market Data //
    var exchangeInfo = ExchangeInfo()
    var marketsWatching = Markets()
    var marketSnapshots = MarketSnapshots()
    
    // TIME //
    var startTime: Milliseconds? = nil
    var duration: Milliseconds {
        guard   let st = self.startTime
                else { return 0 }
        return Date.currentTimeInMS - st
    }
    
    private var updateTimer = Timer() // Timer that periodically updates market data
    var lastUpdateTime: Milliseconds? = nil
    
    /// Update markets watching, filter out bearish coins
    private var marketUpdateTimer = Timer()
    
    // Conditions //
    var status: Status = .stopped
    enum Status: String {
        case running = "Running"
        case stopped = "Stopped"
    }
    
    // Children //
    var trades = Trades()
    
    /// Start trade session
    ///
    /// - Parameter callback: do this after trade session started
    func start(callback: @escaping () -> Void) {
        self.updateMarketsWatching { isSuccess in
            self.status = .running
            self.startTime = Date.currentTimeInMS
            TradeSettings.instance.updateBalances()
            self.startRegularUpdates()
            callback()
        }
    }
    
    /// Stop trade session
    ///
    /// - Parameter callback: do this after trade session stopped
    func stop(callback: @escaping () -> Void) {
        self.status = .stopped
        self.stopRegularUpdates()
        callback()
    }
    
    /// Refresh available markekts for given trading pair, filter appropriately
    ///
    /// - Parameter callback: do this after markets updated
    func updateMarketsWatching(callback: @escaping (_ isSuccess: Bool) -> Void) {
        let tradingPairSymbol = TradeSettings.instance.tradingPairSymbol
        
        self.marketsWatching.removeAll()
        
        self.exchangeInfo.updateData() { isSuccess in
            
            // Verify we got exchange data
            guard isSuccess == true else { callback(false); return }
            
            let allAvailableSymbols = self.exchangeInfo.symbolsForPair(tradingPairSymbol)
            let newMarkets = Markets(symbols: allAvailableSymbols)
            
            newMarkets.filter() { isSuccess in
                guard isSuccess else { callback(false); return }
                self.marketsWatching = newMarkets
                callback(true)
            }
        }
    }
    
    func updateMarketSnapshots(callback: @escaping () -> Void) {
        
        // use a dispatch group to keep track of how many symbols we've updated
        let dpG = DispatchGroup()
        
        for symbol in self.marketsWatching.symbols {
            // don't need to evaluate for coins already trading
            if trades.openTradeFor(symbol) { continue }
            
            dpG.enter() // enter dispatch queue
            
            if let existingSnapshot = self.marketSnapshots.first(where: {$0.symbol == symbol}) {
                existingSnapshot.updateData {
                    dpG.leave()
                }
            } else {
                let newSnapshot = MarketSnapshot(symbol: symbol)
                newSnapshot.updateData {
                    self.marketSnapshots.append(newSnapshot)
                    dpG.leave()
                }
            }
        }
        
        // when all API calls are returned, run callback
        dpG.notify(queue: .main) {
            self.lastUpdateTime = Date.currentTimeInMS
            callback()
        }
    }
    
    func startRegularUpdates() {
        self.updateTimer.invalidate() // Stop prior update timer
        self.updateTimer = Timer.scheduledTimer(timeInterval: 10, target: self,
                                                selector: #selector(self.regularUpdate),
                                                userInfo: nil, repeats: true)
        self.marketUpdateTimer.invalidate()
        self.marketUpdateTimer = Timer.scheduledTimer(timeInterval: 10.0.minutesToSeconds,
                                                      target: self,
                                                      selector: #selector(self.marketUpdate),
                                                      userInfo: nil, repeats: true)
    }
    
    @objc func regularUpdate() {
        let maxOpenTrades = TradeSettings.instance.maxOpenTrades
        guard self.trades.countOpen() < maxOpenTrades else { return }
        self.updateMarketSnapshots {
            self.investInWinners()
        }
    }
    
    @objc func marketUpdate() {
        self.updateMarketsWatching() { _ in }
    }
    
    func stopRegularUpdates() {
        self.updateTimer.invalidate()
        self.marketUpdateTimer.invalidate()
    }
    
    func investInWinners() {
        let maxOpenTrades = TradeSettings.instance.maxOpenTrades
        
        for snapshot in self.marketSnapshots {
            // don't start any more trades if we've maxed out
            guard trades.countOpen() < maxOpenTrades else { return }
            
            // only one trade open per symbol at a time
            if trades.openTradeFor(snapshot.symbol) { continue }
            
            // We don't want to make real trades in test mode
            let isTestMode = TradeSettings.instance.testMode
            
            // only trade if the market snapshot passes our trade enter criteria
            if TradeSettings.instance.tradeStrategy.shouldEnterTrade(for: snapshot) {
                let newTrade = Trade(symbol: snapshot.symbol, snapshot: snapshot,
                                     isTest: isTestMode)
                self.trades.insert(newTrade, at: 0)
                newTrade.enter()
            }
        }
    }
    
}
