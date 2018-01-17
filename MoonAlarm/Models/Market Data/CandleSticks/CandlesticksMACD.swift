//
//  CandlesticksMACD.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/16/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

extension Array where Element : CandleStick {

    /*
     Moving average convergence divergence (MACD) is a trend-following momentum indicator thatshows the relationship between two moving averages of prices. The MACD is calculated by subtracting the 26-day exponential moving average (EMA) from the 12-day EMA. A nine-day EMA of the MACD, called the "signal line", is then plotted on top of the MACD, functioning as a trigger for buy and sell signals.
     */
    func calculateMACD() {
        
        // RSI needs a minimum of 2 * period to be accurate
        guard self.count > 50 else { return }
        
        var initialEMA26Avg: Double = 0.0
        var initialEMA12Avg: Double = 0.0
        var initialSignalAvg: Double = 0.0
        
        var ema26 = EMA(26)
        var ema12 = EMA(12)
        var signal = EMA(9)
        
        for (index, stick) in self.enumerated() {
            
            let currentClosePrice = stick.closePrice
            
            // Establish SMA for each respective period
            if index <= 26 {
                initialEMA26Avg += currentClosePrice / 26.0
                if index <= 12 {
                    initialEMA12Avg += currentClosePrice / 12.0
                }
                
                if index == 26  { ema26.add(next: initialEMA26Avg) }
                if index == 12  { ema12.add(next: initialEMA12Avg) }
            }
            
            if index > 12 {
                
                ema12.add(next: stick.closePrice)

                if index > 26 {
                
                    ema26.add(next: stick.closePrice)
                    let macd = ema12.currentAvg! - ema26.currentAvg!
                    stick.macd = macd
                    
                    if index < 26 + 9 {
                        initialSignalAvg += macd / 9.0
                    } else if index == 26 + 9 {
                        signal.add(next: initialSignalAvg)
                    } else {
                        signal.add(next: macd)
                        stick.macdSignal = signal.currentAvg
                    }
                    
                }
            }
            
        }

    }
    
    struct EMA {
        
        private var period: Int
        
        var currentAvg: Double?
        
        init(initialPrice: Double? = nil, _ period: Int) {
            self.currentAvg = initialPrice
            self.period = period
        }
        
        @discardableResult mutating func add(next: Double) -> EMA {
            guard let currentAvg = self.currentAvg else {
                self.currentAvg = next
                return self
            }
            let weightFactor: Double = 2.0 / Double(period + 1)
            self.currentAvg = (next - currentAvg) * weightFactor + currentAvg
            return self
        }
        
    }
    
}
