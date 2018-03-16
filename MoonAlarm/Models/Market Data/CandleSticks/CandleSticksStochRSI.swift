//
//  CandleSticksStochRSI.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/10/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

extension Array where Element : CandleStick {
    
    /// Calculates and populates candlesticks with stochastic RSI value
    func calculateStochRSI() {
        /// RSI Period
        let lengthRSI = 14
        /// Stochastic period
        let lengthStoch = 9
        /// Smooth signal of stocastic RSI
        let smoothK = 2
        /// Smooth signal of smoothed stochastic RSI
        let smoothD = 2
        
        // RSI needs a minimum of 2 * period to be accurate
        guard   self.count > (2 * lengthRSI),
                self.last?.rsi != nil
                else {
                
                NSLog("RSI data unavailable to calculate Stochastic RSI")
                return
        }
        
        guard   lengthStoch <= lengthRSI,
                smoothK < lengthStoch, smoothD < lengthStoch
                else {
                    
                NSLog("Invalid Stochastic RSI Inputs")
                return
        }
        
        let smaK = SMA(smoothK)
        let smaD = SMA(smoothD)
        
        for (index, stick) in self.enumerated() {
            /// Ignore data points before we have minimum RSI points for calculation
            guard   index >= (lengthRSI + lengthStoch - 1) else { continue }
            
            let prefix = index + 1
            let minMaxGroup = self.prefix(prefix).suffix(lengthStoch).filter({ $0.rsi != nil })
                .map({ $0.rsi! })
            
            /// Verify min and max have values
            guard   let currentRSI = stick.rsi,
                let minRSI = minMaxGroup.min(),
                let maxRSI = minMaxGroup.max()
                else { continue }
            
            let newStochRSI = (currentRSI - minRSI) / (maxRSI - minRSI) * 100
            
            stick.stochRSI = newStochRSI
            
            smaK.add(next: newStochRSI)
            if let newK = smaK.currentAvg {
                stick.stochRSIK = newK
                smaD.add(next: newK)
                if let newD = smaD.currentAvg {
                    stick.stochRSID = newD
                }
            }
        }
        
    }
    
    //  Example Calculation:
    //    lengthRSI = 10 //RSI period
    //    lengthStoch = 10 //Stochastic period
    //    smoothK = 10 //Smooth signal of stochastic RSI
    //    smoothD = 3 //Smooth signal of smoothed stochastic RSI
    //
    //    myRSI = RSI[lengthRSI](close)
    //    MinRSI = lowest[lengthStoch](myrsi)
    //    MaxRSI = highest[lengthStoch](myrsi)
    //
    //    StochRSI = (myRSI-MinRSI) / (MaxRSI-MinRSI)
    //
    //    K = average[smoothK](stochrsi)*100
    //    D = average[smoothD](K)
    
}
