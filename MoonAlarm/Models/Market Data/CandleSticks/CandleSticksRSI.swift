//
//  CandleSticksRSI.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/15/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

extension Array where Element : CandleStick {
    
    func calculateRSI(_ period: Int = 14) {
        
        // RSI needs a minimum of 2 * period to be accurate
        guard   self.count > (2 * period),
                period > 0
                else { return }
        
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
        
        let bullSMA = SMA(initialValue: initialBullAvg, period)
        let bearSMA = SMA(initialValue: initialBearAvg, period)
        
        let remainingPeriods = self.dropFirst(period + 1)
        for (index, cStick) in remainingPeriods.enumerated() {
            let indexInSelf = remainingPeriods.startIndex + index
            let prevClosePrice = self[indexInSelf - 1].closePrice
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

            guard   let bullSMAValue = bullSMA.currentAvg,
                    let bearSMAValue = bearSMA.currentAvg
                    else { return }
            
            let rs = bullSMAValue / bearSMAValue
            let rsi = (100 - (100 / (1 + rs)))
            
            self[indexInSelf].rsi = rsi
        }
    
    }
    

}
