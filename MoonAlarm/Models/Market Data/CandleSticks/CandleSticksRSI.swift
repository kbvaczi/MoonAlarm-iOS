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
        for (index, cStick) in initialPeriod.enumerated() {
            if index == 0 { continue } // can't get prev close from first
            let prevClosePrice = self[index - 1].closePrice
            let deltaPrice = cStick.closePrice - prevClosePrice
            
            let isBull = deltaPrice > 0
            if isBull {
                let gain = deltaPrice
                initialBullAvg += gain / Double(period)
            } else {
                let loss = deltaPrice * -1
                initialBearAvg += loss / Double(period)
            }
        }
        
        var bullSMA = SMA(initialPrice: initialBullAvg, period)
        var bearSMA = SMA(initialPrice: initialBearAvg, period)
        
        let remainingPeriods = self.dropFirst(period + 1)
        let rpStartIndex = remainingPeriods.startIndex
        for (index, cStick) in remainingPeriods.enumerated() {
            let prevClosePrice = self[index + rpStartIndex - 1].closePrice
            let deltaPrice = cStick.closePrice - prevClosePrice
            
            let isBull = deltaPrice > 0
            if isBull {
                let gain = deltaPrice
                bullSMA.add(next: gain)
                bearSMA.add(next: 0)
            } else {
                let loss = deltaPrice * -1
                bearSMA.add(next: loss)
                bullSMA.add(next: 0)
            }
        }
        
        guard   let bullSMAValue = bullSMA.currentAvg,
            let bearSMAValue = bearSMA.currentAvg
            else { return nil }
        
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
