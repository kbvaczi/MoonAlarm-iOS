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
    
    var maxFallwayPercent: Percent = 0.4
    
    override init() { }
    
    init(maxFallwayPercent mfp: Double) {
        self.maxFallwayPercent = mfp
    }
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
        guard   let fallwayPercent = snapshot.fallwayPercent1Period else { return false }
        
        return fallwayPercent < self.maxFallwayPercent
    }
    
}


