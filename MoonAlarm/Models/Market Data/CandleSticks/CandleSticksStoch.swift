//
//  CandleSticksStoch.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/25/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

extension Array where Element : CandleStick {
    
    /// Calculates and populates candlesticks with stochastic price oscillator values
    func calculateStochOscillator() {
        /// Stochastic period
        let lengthStoch = 14
        /// Smooth signal of stocastic oscillator
        let smoothK = 1
        /// Smooth signal of smoothed stochastic oscillator
        let smoothD = 3
        
        // needs a minimum of 2 * period number of sticks to be accurate
        guard   self.count > (2 * lengthStoch) else {
            NSLog("Data unavailable to calculate Stochastic Price Oscillator")
            return
        }
        
        let smaK = SMA(smoothK)
        let smaD = SMA(smoothD)
        
        for (index, stick) in self.enumerated() {
            
            // Only calculate stochastic indicator where we have enough previous data
            guard index > lengthStoch else { continue }
            
            let prefixLength = index + 1
            let minGroup = self.prefix(prefixLength).suffix(lengthStoch).map({ $0.lowPrice })
            let maxGroup = self.prefix(prefixLength).suffix(lengthStoch).map({ $0.highPrice })
            
            /// Verify min and max have values
            guard   let minPrice = minGroup.min(),
                    let maxPrice = maxGroup.max()
                    else { continue }
            
            let currentPrice = stick.closePrice
            let newStoch = (currentPrice - minPrice) / (maxPrice - minPrice) * 100
            
            stick.stoch = newStoch
            
            smaK.add(next: newStoch)
            if let newK = smaK.currentAvg {
                stick.stochK = newK
                smaD.add(next: newK)
                if let newD = smaD.currentAvg {
                    stick.stochD = newD
                }
            }
        }
        
    }

}
