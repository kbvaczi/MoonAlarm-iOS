import Foundation

class CandleStick {
    
    ////////// Price //////////
    
    let closePrice: Double
    
    ////////// Initializer //////////
    
    init(_ closePrice: Double) {
        self.closePrice = closePrice
    }
    
}

extension Array where Element : CandleStick {
    
    func currentRSI(_ period: Int = 14) -> Double? {
        
        // RSI needs a minimum of 2 * period to be accurate
        guard self.count > (2 * period) else { return nil }
        
        var initialBullAvg: Double = 0.0
        var initialBearAvg: Double = 0.0
        
        let initialPeriod = self.prefix(period)
        for (index, cStick) in initialPeriod.enumerated() {
            if index == 0 { continue } // can't get prev close from first
            let prevClosePrice = self[index - 1].closePrice
            let deltaPrice = cStick.closePrice - prevClosePrice
            
            let isBull = deltaPrice > 0
            if isBull {
                let gain = deltaPrice
                initialBullAvg += gain / Double(period)
            } else {
                let loss = deltaPrice * -1
                initialBearAvg += loss / Double(period)
            }
        }
        
        var bullSMA = SMA(initialValue: initialBullAvg, period)
        var bearSMA = SMA(initialValue: initialBearAvg, period)
        
        let remainingPeriods = self.dropFirst(period + 1)
        let rpStartIndex = remainingPeriods.startIndex
        for (index, cStick) in remainingPeriods.enumerated() {
            let prevClosePrice = self[index + rpStartIndex - 1].closePrice
            let deltaPrice = cStick.closePrice - prevClosePrice
            
            let isBull = deltaPrice > 0
            if isBull {
                let gain = deltaPrice
                bullSMA.add(next: gain)
                bearSMA.add(next: 0)
            } else {
                let loss = deltaPrice * -1
                bearSMA.add(next: loss)
                bullSMA.add(next: 0)
            }
        }
        
        guard   let bullSMAValue = bullSMA.currentAvg,
                let bearSMAValue = bearSMA.currentAvg
                else { return nil }
        
        let rs = bullSMAValue / bearSMAValue
        let rsi = (100 - (100 / (1 + rs)))
        
        return rsi
    }
    
    struct SMAOld {
        
        private var period: Int
        var currentAvg: Double?
        
        init(initialPrice: Double? = nil, _ period: Int) {
            self.currentAvg = initialPrice
            self.period = period
        }
        
        @discardableResult mutating func add(next: Double) -> SMAOld {
            guard let currentAvg = self.currentAvg else {
                self.currentAvg = next
                return self
            }
            self.currentAvg = ((currentAvg * Double(period - 1)) + next) / Double(period)
            return self
        }
    }
    
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
}

var sticks = [CandleStick]()
let closePrices  = [44.34,44.09,44.15,43.61,44.33,44.83,45.10,45.42,45.84,46.08,45.89,46.03,45.61,46.28,46.28,46.00,46.03,46.41,46.22,45.64,46.21,46.25,45.71,46.45,45.78,45.35,44.03,44.18,44.22,44.57,43.42,42.66,43.13]

for cp in closePrices {
    sticks.append(CandleStick(cp))
}

sticks.currentRSI()

