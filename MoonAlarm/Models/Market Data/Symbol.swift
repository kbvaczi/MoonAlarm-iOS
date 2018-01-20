//
//  Symbol.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/19/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

typealias Symbol = String

extension Symbol {
    
    var symbolPair: String {
        return self + TradeStrategy.instance.tradingPairSymbol
    }
    
}
