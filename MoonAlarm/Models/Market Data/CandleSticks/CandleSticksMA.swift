//
//  CandleSticksMA.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/10/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

    /// Simple Moving Average
    class SMA {
        
        /// Period over which to calculate average
        let period: Int
        /// Keep track of last values added to MA
        var lastInputs = [Double]()
        /// Keep track of last values added to MA
        var lastAverages = [Double]()
        /// Current simple average
        var currentAvg: Double?
        
        init(initialValue: Double? = nil, _ period: Int) {
            self.currentAvg = initialValue
            self.period = period
        }
        
        /// Add new input value to the list of last values
        ///
        /// - Parameter nextValue: next input value to append
        func appendInput(nextValue: Double) {
            lastInputs.append(nextValue)
            if self.lastInputs.count > period {
                lastInputs.remove(at: 0)
            }
        }
        
        /// Add new average to the list of last averages
        ///
        /// - Parameter nextValue: next average value to append
        func appendAverage(nextValue: Double) {
            self.currentAvg = nextValue
            lastAverages.append(nextValue)
            if self.lastAverages.count > period {
                lastAverages.remove(at: 0)
            }
        }
        
        /// Backtrack moving average to change last values
        ///
        /// - Parameter count: number of input values to backtrack
        /// - Returns: Moving average after backtracking, nil if count invalid
        func backTrack(_ count: Int) -> SMA? {
            guard   count < period,
                count < lastAverages.count,
                count < lastInputs.count else { return nil }
            
            self.lastInputs.removeLast(count)
            self.lastAverages.removeLast(count)
            self.currentAvg = lastAverages.last
            return self
        }
        
        func updatedAvg(adding next: Double) -> Double? {
            /// Verify we have a valid moving average prior to continuing
            guard   let currentAvg = self.currentAvg else { return nil }
            
            let newAvg = ((currentAvg * Double(self.period - 1)) + next) / Double(self.period)
            return newAvg
        }
        
        @discardableResult func add(next: Double) -> SMA {
            self.appendInput(nextValue: next)
            
            /// MA starts with a straight average of first *period* inputs
            if self.currentAvg == nil, self.lastInputs.count >= self.period {
                let avgOfLastInputs = self.lastInputs.reduce(0, +) /
                                      Double(self.lastInputs.count)
                self.appendAverage(nextValue: avgOfLastInputs)
                return self
            }
            
            // SMA is valid, continue updating SMA with new inputs
            if let newAvg = self.updatedAvg(adding: next) {
                self.appendAverage(nextValue: newAvg)
            }
            
            return self
        }
        
    }
    
    /// Exponential moving average
    class EMA: SMA {
        
        override func updatedAvg(adding next: Double) -> Double? {
            /// Verify we have a valid moving average prior to continuing
            guard   let currentAvg = self.currentAvg else { return nil }
            
            let weightFactor: Double = 2.0 / Double(self.period + 1)
            let newAvg = (next - currentAvg) * weightFactor + currentAvg

            return newAvg
        }
        
    }

