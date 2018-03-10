//
//  Markets.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/25/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

/// Markets to track, designated by coin symbol
class Markets {
    
    /// Coin symbols to track for current trading pair
    var symbols = [Symbol]()
    
    /// Markets to track
    ///
    /// - Parameter symbols: symbols indicating which coins to track
    init(symbols: [Symbol] = []) {
        self.symbols = symbols
    }
    
    /// Combines market filters together
    ///
    /// - Parameter callback: Do this after markets are filtered
    func filter (callback: @escaping (_ isSuccess: Bool) -> Void) {
        self.filterBy24HrVol() { isSuccess in
            guard isSuccess else { callback(false); return }
//            self.filterWithStochRSI() { isSuccess in
                NSLog("MARKETS: Filtered Markets Watching to \(self.symbols)")
                callback(isSuccess)
//            }
        }
    }
    
    /// Filters markets by minimum 24hr volume
    ///
    /// - Parameter callback: do this after markets filtered
    private func filterBy24HrVol(callback: @escaping (_ isSuccess: Bool) -> Void) {
        let dpG = DispatchGroup() // Keep track of how many have updated
        /// Keep track of whether all callcs for 24hrvol were successful
        var allSuccess = true
        /// Keep track of what indexes we want to remove
        var indexesToRemove = [Int]()

        for (index, symbol) in self.symbols.enumerated() {
            dpG.enter()
            BinanceAPI.instance.get24HrPairVolume(forTradingPair: symbol.symbolPair) {
                (isSuccessful, pairVolume) in
                
                if isSuccessful, let pairVolume = pairVolume {
                    // TODO: come up with a more intelligent way of filtering symbols
                    let min24HrVol = TradeSettings.instance.marketMin24HrVol
                    
                    if pairVolume < min24HrVol {
                        indexesToRemove.append(index)
                    }
                } else {
                    allSuccess = false
                }
                dpG.leave()
            }
        }
        
        dpG.notify(queue: .main) {
            self.symbols.remove(at: indexesToRemove)
            callback(allSuccess)
        }
    }
    
    /// Check the longer duration chart and make sure the to filter out bearish markets.
    ///
    /// - Parameter callback: do this after markets filtered
    private func filterWithStochRSI(callback: @escaping (_ isSuccess: Bool) -> Void) {
        let dpG = DispatchGroup() // Keep track of how many have updated
        /// Keep track of whether all callcs for 24hrvol were successful
        var allSuccess = true
        /// Keep track of what indexes we want to remove
        var indexesToRemove = [Int]()
        
        for (index, symbol) in self.symbols.enumerated() {
            dpG.enter()
            let pair = symbol.symbolPair
            // Get enough 1-day sticks to calculate stochastic price oscillator
            BinanceAPI.instance.getCandleSticks(symbolPair: pair, interval: .h1, limit: 100) {
                (isSuccess, cSticks) in
                if isSuccess, let cSticks = cSticks {
                    cSticks.calculateRSI()
                    cSticks.calculateStochRSI()
                    if let currentStoch = cSticks.last?.stochRSIK,
                       let prevStoch = cSticks[cSticks.count - 2].stochRSIK,
                       let currentStochDelta = cSticks.last?.stochRSISignalDelta {
                        if currentStoch > 80 || currentStochDelta < 0 || currentStoch < prevStoch {
                            indexesToRemove.append(index)
                        }
                    } else {
                        indexesToRemove.append(index)
                    }
                } else {
                    allSuccess = false
                }
                dpG.leave()
            }
        }
        
        dpG.notify(queue: .main) {
            self.symbols.remove(at: indexesToRemove)
            callback(allSuccess)
        }
    }
    
    /// Remove all markets
    func removeAll() {
        self.symbols.removeAll()
    }
    
}
