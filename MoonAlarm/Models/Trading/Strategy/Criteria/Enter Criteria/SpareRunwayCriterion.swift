//
//  SpareRunwayCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/12/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class SpareRunwayCriterion: TradeEnterCriterion {
    
    var minRunwayPercent: Percent
    
    init(minRunwayPercent mrp: Double) {
        self.minRunwayPercent = mrp
    }
    
    override func passed(usingSnapshot mSnapshot: MarketSnapshot) -> Bool {
        guard let currentVol = mSnapshot.candleSticks.currentStickVolume,
              let currentPrice = mSnapshot.currentPrice else { return false }
        guard let runwayPrice = mSnapshot.orderBook.runwayPrice(forVolume: currentVol)
                  else { return false }
        
        let runwayPercent = (runwayPrice / currentPrice - 1).toPercent()
        
        return runwayPercent > minRunwayPercent
    }
    
}

