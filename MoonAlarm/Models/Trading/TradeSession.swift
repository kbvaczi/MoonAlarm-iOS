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
    var symbolsWatching = [Symbol]()
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
    
    // Conditions //
    var status: Status = .stopped
    enum Status: String {
        case running = "Running"
        case stopped = "Stopped"
    }
    
    // Children //
    var trades = Trades()
    
    func start(callback: @escaping () -> Void) {
        self.status = .running
        self.startTime = Date.currentTimeInMS
        TradeStrategy.instance.updateBalances()
        self.updateSymbolsAndPrioritize { isSuccess in
            self.startRegularSnapshotUpdates()
            callback()
        }
    }
    
    func stop(callback: @escaping () -> Void) {
        self.status = .stopped
        self.stopRegularSnapshotUpdates()
        callback()
    }
    
    func updateSymbolsAndPrioritize(callback: @escaping (_ isSuccess: Bool) -> Void) {
        let tradingPairSymbol = TradeStrategy.instance.tradingPairSymbol
        
        self.exchangeInfo.updateData() { isSuccess in
            
            // Verify we got exchange data
            guard isSuccess == true else { callback(false); return }
            
            self.symbolsWatching.removeAll()
            
            let allAvailableSymbols = self.exchangeInfo.symbolsForPair(tradingPairSymbol)
            let dpG = DispatchGroup() // Keep track of how many have updated
            
            for symbol in allAvailableSymbols {
                dpG.enter()
                BinanceAPI.instance.get24HrPairVolume(forTradingPair: symbol.symbolPair) {
                    (isSuccessful, pairVolume) in
                    
                    if isSuccessful, let pairVolume = pairVolume {
                        // TODO: come up with a more intelligent way of filtering symbols
                        let min24HrVol = TradeStrategy.instance.marketMin24HrVol
                        
                        // Due to API request limits, can monitor up to 50 symbols at once
                        if pairVolume > min24HrVol, self.symbolsWatching.count < 50 {
                            self.symbolsWatching.append(symbol)
                        }
                    }
                    dpG.leave()
                }
            }
            
            dpG.notify(queue: .main) {
                callback(true)
            }
        }
    }
    
    func updateMarketSnapshots(callback: @escaping () -> Void) {
        
        // use a dispatch group to keep track of how many symbols we've updated
        let dpG = DispatchGroup()
        
        for symbol in self.symbolsWatching {
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
    
    func startRegularSnapshotUpdates() {
        self.updateTimer.invalidate() // Stop prior update timer
        self.updateTimer = Timer.scheduledTimer(timeInterval: 15, target: self,
                                                selector: #selector(self.regularUpdate),
                                                userInfo: nil, repeats: true)
    }
    
    @objc func regularUpdate() {
        let maxOpenTrades = TradeStrategy.instance.maxOpenTrades
        guard self.trades.countOpen() < maxOpenTrades else { return }
        self.updateMarketSnapshots {
            self.investInWinners()
        }
    }
    
    func stopRegularSnapshotUpdates() {
        self.updateTimer.invalidate()
    }
    
    func investInWinners() {
        let maxOpenTrades = TradeStrategy.instance.maxOpenTrades
        
        for snapshot in self.marketSnapshots {
            // don't start any more trades if we've maxed out
            guard trades.countOpen() < maxOpenTrades else { return }
            
            // only one trade open per symbol at a time
            if trades.openTradeFor(snapshot.symbol) { continue }
            
            // We don't want to make real trades in test mode
            let isTestMode = TradeStrategy.instance.testMode
            
            // only trade if the market snapshot passes our trade enter criteria
            if TradeStrategy.instance.entranceCriteria.allPassedFor(snapshot) {
                let newTrade = Trade(symbol: snapshot.symbol, snapshot: snapshot,
                                     isTest: isTestMode)
                self.trades.insert(newTrade, at: 0)
                newTrade.enter()
            }
        }
    }
    
}
