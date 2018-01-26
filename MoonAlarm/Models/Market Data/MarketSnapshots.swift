//
//  MarketSnapshots.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/8/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

typealias MarketSnapshots = Array<MarketSnapshot>

extension Array where Element : MarketSnapshot {
    
    func select(_ symbol: Symbol) -> MarketSnapshot? {
        return self.filter({$0.symbol == symbol}).first
    }
    
    mutating func updateSnapshotFor(_ symbol: Symbol, with newSnapshot: MarketSnapshot) {
        guard var snapshotToUpdate: MarketSnapshot = self.first(where: {$0.symbol == symbol})
            else {
            print("tried to update snapshot for symbol that doesn't exist")
            return
        }
        if snapshotToUpdate.symbol == symbol {
            snapshotToUpdate = newSnapshot
        }
    }
    
}
