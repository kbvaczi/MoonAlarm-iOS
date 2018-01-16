//
//  CandleSticksRSI.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/15/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

extension Array where Element : CandleStick {

    func currentRSI(_ period: Int = 14) -> Double? {
        
        // RSI needs a minimum of 2 * period to be accurate
        guard self.count > (2 * period) else { return nil }

        var initialBullAvg: Double = 0.0
        var initialBearAvg: Double = 0.0
        
        let initialPeriod = self.prefix(period)
        for cStick in initialPeriod {
            let isBull = cStick.closePrice > cStick.openPrice
            let isBear = cStick.closePrice < cStick.openPrice
            if isBull {
                let gain = cStick.closePrice - cStick.openPrice
                initialBullAvg += gain / Double(period)
            } else if isBear {
                let loss = cStick.openPrice - cStick.closePrice
                initialBearAvg += loss / Double(period)
            }
        }
        
        var bullSMA = SMA(initialPrice: initialBullAvg, period)
        var bearSMA = SMA(initialPrice: initialBearAvg, period)
        
        let remainingPeriods = self.dropFirst(period)
        for cStick in remainingPeriods {
            let isBull = cStick.closePrice > cStick.openPrice
            if isBull {
                let gain = cStick.closePrice - cStick.openPrice
                bullSMA.add(next: gain)
                bearSMA.add(next: 0)
            } else {
                let loss = cStick.openPrice - cStick.closePrice
                bearSMA.add(next: loss)
                bullSMA.add(next: 0)
            }
        }
        
        guard   let bullSMAValue = bullSMA.currentAvg,
                let bearSMAValue = bearSMA.currentAvg else { return nil }
        
        let rs = bullSMAValue / bearSMAValue
        let rsi = (100 - (100 / (1 + rs)))
        
        return rsi
    }
    
    struct SMA {
        
        private var period: Int
        var currentAvg: Double?
        
        init(initialPrice: Double? = nil, _ period: Int) {
            self.currentAvg = initialPrice
            self.period = period
        }
        
        @discardableResult mutating func add(next: Double) -> SMA {
            guard let currentAvg = self.currentAvg else {
                self.currentAvg = next
                return self
            }
            self.currentAvg = ((currentAvg * Double(period - 1)) + next) / Double(period)
            return self
        }
    }

}
