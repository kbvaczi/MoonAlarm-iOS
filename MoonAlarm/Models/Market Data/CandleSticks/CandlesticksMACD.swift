//
//  CandlesticksMACD.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/16/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

// Moving average convergence divergence (MACD) is a trend-following momentum indicator that
// shows the relationship between two moving averages of prices. The MACD is calculated by
// subtracting the 26-day exponential moving average (EMA) from the 12-day EMA. A nine-day EMA
// of the MACD, called the "signal line", is then plotted on top of the MACD, functioning as a
// trigger for buy and sell signals.

import Foundation

extension Array where Element : CandleStick {
    
    func calculateMACD() {
        
        // need a minimum of 2 * period candlesticks to be accurate
        guard self.count > 50 else { return }
        
        let ema26 = EMA(26)
        let ema12 = EMA(12)
        let signal = EMA(9)
        
        for stick in self {
            
            let currentClosePrice = stick.closePrice
            
            ema26.add(next: currentClosePrice)
            ema12.add(next: currentClosePrice)
            
            if let ema26Avg = ema26.currentAvg, let ema12Avg = ema12.currentAvg {
                let macd = ema12Avg - ema26Avg
                stick.macd = macd
                signal.add(next: macd)
                if let newSignal = signal.currentAvg {
                    stick.macdSignal = newSignal
                }
            }
        }
    }
    
}
    

