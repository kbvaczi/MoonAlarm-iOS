//
//  CandlesticksMACD.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/16/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

extension Array where Element : CandleStick {

    struct EMA {
        
        private var period: Int
        
        var currentAvg: Double?
        
        init(initialPrice: Double? = nil, _ period: Int) {
            self.currentAvg = initialPrice
            self.period = period
        }
        
        @discardableResult mutating func add(next: Double) -> EMA {
            guard let currentAvg = self.currentAvg else {
                self.currentAvg = next
                return self
            }
            let weightFactor: Double = 2.0 / Double(period + 1)
            self.currentAvg = (next - currentAvg) * weightFactor + currentAvg
            return self
        }
        
    }
    
}
