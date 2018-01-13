//
//  SpareRunwayCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/12/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class SpareRunwayCriterion: TradeEnterCriterion {
    
    var minRunwayPercent: Percent = 1.0
    
    override init() { }
    
    init(minRunwayPercent mrp: Double) {
        self.minRunwayPercent = mrp
    }
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
        guard   let runwayPercent = snapshot.runwayPercent1M else { return false }
        
        return runwayPercent > minRunwayPercent
    }
    
}
