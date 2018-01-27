//
//  BidAskGapCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/19/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class BidAskGapEnter: TradeEnterCriterion {
    
    var maxGapPercent: Percent
    
    init(maxGapPercent mgp: Percent = 1.0) {
        self.maxGapPercent = mgp
    }
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
        guard let currentGapPercent = snapshot.orderBook.bidAskGapPercent else { return false }
        return currentGapPercent < self.maxGapPercent
    }
    
}
