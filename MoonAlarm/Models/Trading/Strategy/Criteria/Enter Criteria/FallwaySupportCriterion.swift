//
//  FallwaySupportCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/13/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

// Runway ratio is the ratio of runway price to sell wall vs fallway price to buy walls
class FallwaySupportCriterion: TradeEnterCriterion {
    
    var maxFallwayPercent: Percent
    
    init(maxFallwayPercent mfp: Double) {
        self.maxFallwayPercent = mfp
    }
    
    override func passed(usingSnapshot mSnapshot: MarketSnapshot) -> Bool {
        guard let currentVol = mSnapshot.candleSticks.currentStickVolume,
            let currentPrice = mSnapshot.currentPrice else { return false }
        guard let fallwayPrice = mSnapshot.orderBook.fallwayPrice(forVolume: currentVol)
            else { return false }
        
        let fallwayPercent = (currentPrice / fallwayPrice - 1).toPercent()
        
        return fallwayPercent < self.maxFallwayPercent
    }
    
}


