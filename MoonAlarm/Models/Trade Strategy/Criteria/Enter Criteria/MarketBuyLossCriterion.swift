//
//  MarketBuyLossCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/19/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class MarketBuyLossEnter: TradeEnterCriterion {
    
    var maxLossPercent: Percent
    
    init(maxLossPercent mlp: Percent = 0.3) {
        self.maxLossPercent = mlp
    }
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
        let pairVolume = TradeSettings.instance.tradeAmountTarget
        let ob = snapshot.orderBook
        
        guard   let marketBuyPrice = ob.marketBuyPrice(forPairVolume: pairVolume),
                let firstAsk = ob.firstAskPrice
                else { return false }
        
        let lossPercent = ((firstAsk - marketBuyPrice)/marketBuyPrice).doubleToPercent
        
        return lossPercent < maxLossPercent
    }
    
}
