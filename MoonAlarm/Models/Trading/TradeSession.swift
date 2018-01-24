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
    var symbols = [String]()
    var marketSnapshots = MarketSnapshots()
    
    // TIME //
    var startTime: Milliseconds? = nil
    var duration: Milliseconds {
        guard   let st = self.startTime
                else { return 0 }
        return Date().millisecondsSince1970 - st
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
        self.startTime = Date().millisecondsSince1970
        TradeSession.instance.updateSymbolsAndPrioritize {
            self.startRegularSnapshotUpdates {
                self.investInWinners()
            }
            callback()
        }
    }
    
    func stop(callback: @escaping () -> Void) {
        self.status = .stopped
        self.stopRegularSnapshotUpdates()
        callback()
    }
    
    func updateSymbolsAndPrioritize(callback: @escaping () -> Void) {
        let tradingPairSymbol = TradeStrategy.instance.tradingPairSymbol
        BinanceAPI.instance.getAllSymbols(forTradingPair: tradingPairSymbol) {
            (isSuccess, allSymbols) in
            if isSuccess {
                
                // use a dispatch group to keep track of how many symbols we've updated
                let dpG = DispatchGroup()
                
                // clear out old symbols
                self.symbols.removeAll()
                
                for symbol in allSymbols {
                    dpG.enter()
                    BinanceAPI.instance.get24HrPairVolume(forTradingPair: symbol.symbolPair) {
                        (isSuccessful, pairVolume) in
                        let min24HrVol = TradeStrategy.instance.tradingPairSymbol == "BTC" ? 1000.0 : 3000.0
                        if  pairVolume > min24HrVol,
                            self.symbols.count < 50 {
                            self.symbols.append(symbol)
                        }
                        dpG.leave()
                    }
                }
                
                dpG.notify(queue: .main) {
                    callback()
                }
            }
        }
    }
    
    func updateMarketSnapshots(callback: @escaping () -> Void) {
        
        // use a dispatch group to keep track of how many symbols we've updated
        let dpG = DispatchGroup()
        
        for symbol in self.symbols {
            dpG.enter() // enter dispatch queue
            let newSnapshot = MarketSnapshot(symbol: symbol)
            newSnapshot.updateData {
                self.marketSnapshots.updateSnapshotFor(symbol, with: newSnapshot)
                dpG.leave()
            }
        }
        
        // when all API calls are returned, run callback
        dpG.notify(queue: .main) {
            self.lastUpdateTime = ExchangeClock.instance.currentTime
            callback()
        }
    }
    
    func startRegularSnapshotUpdates(callback: @escaping () -> Void) {
        self.updateTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            let maxOpenTrades = TradeStrategy.instance.maxOpenTrades
            guard self.trades.countOnly(status: .open) < maxOpenTrades else { return }
            self.updateMarketSnapshots {
                callback()
            }
        }
    }
    
    func stopRegularSnapshotUpdates() {
        self.updateTimer.invalidate()
    }
    
    func investInWinners() {
        let maxOpenTrades = TradeStrategy.instance.maxOpenTrades
        
        for snapshot in self.marketSnapshots {
            // don't start any more trades if we've maxed out
            guard trades.countOnly(status: .open) < maxOpenTrades else { return }
            
            // only one trade open per symbol at a time
            if trades.openTradeFor(snapshot.symbol) { continue }
            
            // only trade if the market snapshot passes our trade enter criteria
            if TradeStrategy.instance.entranceCriteria.allPassedFor(snapshot) {
                let newTrade = Trade(symbol: snapshot.symbol, snapshot: snapshot)
                self.trades.insert(newTrade, at: 0)
                newTrade.execute()
            }
        }
    }
    
}
