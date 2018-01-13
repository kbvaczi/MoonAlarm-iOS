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
        guard   let runwayPercent = mSnapshot.runwayPercent1M else { return false }
        
        return runwayPercent > minRunwayPercent
    }
    
}

