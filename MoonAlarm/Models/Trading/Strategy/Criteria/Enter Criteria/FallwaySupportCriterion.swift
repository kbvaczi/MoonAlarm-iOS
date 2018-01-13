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
        guard   let fallwayPercent = mSnapshot.fallwayPercent1M else { return false }
        
        return fallwayPercent < self.maxFallwayPercent
    }
    
}


