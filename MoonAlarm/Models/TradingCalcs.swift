//
//  TradingCalcs.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/7/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TradingCalcs {
    
    // no instance of this class can be made
    private init() {}
    
    static func volumeRatio(cSticks: [CandleStick], last: Int = 1, period: Int) -> Double {
        
        let periodSticks = cSticks.suffix(period)
        let periodVolTotal = periodSticks.map({ $0.volume }).reduce(0, +)
        let periodVolAvg = periodVolTotal / Double(period)
        
        let lastSticks = cSticks.suffix(last)
        let lastVolTotal = lastSticks.map({ $0.volume }).reduce(0, +)
        let lastVolAvg = lastVolTotal / Double(last)
        
        let volRatio = lastVolAvg / periodVolAvg
        let roundedVolRatio = round(volRatio * 100) / 100
        return roundedVolRatio
    }
    
    static func priceRatio(cSticks: [CandleStick], last: Int = 1, period: Int) -> Double {
        
        let periodSticks = cSticks.suffix(period)
        let periodPriceTotal = periodSticks.map({ $0.closePrice }).reduce(0, +)
        let periodPriceAvg = periodPriceTotal / Double(period)
        
        let lastSticks = cSticks.suffix(last)
        let lastPriceTotal = lastSticks.map({ $0.closePrice }).reduce(0, +)
        let lastPriceAvg = lastPriceTotal / Double(last)
        
        let priceRatio = lastPriceAvg / periodPriceAvg
        let roundedPriceRatio = round(priceRatio * 1000) / 1000
        
        print("period price: \(periodPriceAvg), last price: \(lastPriceAvg), price ratio \(roundedPriceRatio)")
        
        return roundedPriceRatio
    }
}
