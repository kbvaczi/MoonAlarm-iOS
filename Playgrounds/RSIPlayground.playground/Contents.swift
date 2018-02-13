import Foundation

class CandleStick {
    
    ////////// Price //////////
    
    let closePrice: Double
    var rsi: Double? = nil
    
    ////////// Initializer //////////
    
    init(_ closePrice: Double) {
        self.closePrice = closePrice
    }
    
}

extension Array where Element : CandleStick {
    
    func calculateRSI(_ period: Int = 14) {
        
        // RSI needs a minimum of 2 * period to be accurate
        guard   self.count > (2 * period),
            period > 0
            else { return }
        
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
        
        let bullSMA = SMA(initialValue: initialBullAvg, period)
        let bearSMA = SMA(initialValue: initialBearAvg, period)
        
        let remainingPeriods = self.dropFirst(period + 1)
        for (index, cStick) in remainingPeriods.enumerated() {
            let indexInSelf = remainingPeriods.startIndex + index
            let prevClosePrice = self[indexInSelf - 1].closePrice
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
            
            guard   let bullSMAValue = bullSMA.currentAvg,
                let bearSMAValue = bearSMA.currentAvg
                else { return }
            
            let rs = bullSMAValue / bearSMAValue
            let rsi = (100 - (100 / (1 + rs)))
            
            self[indexInSelf].rsi = rsi
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
let closePrices  = [44.3389, 44.0902, 44.1497, 43.6124, 44.3278, 44.8264, 45.0955, 45.4245, 45.8433, 46.0826, 45.8931, 46.0328, 45.6140, 46.2820, 46.2820, 46.0028, 46.0328, 46.4116, 46.2222, 45.6439, 46.2122, 46.2521, 45.7137, 46.4515, 45.7835, 45.3548, 44.0288, 44.1783, 44.2181, 44.5672, 43.4205, 42.6628, 43.131]

for cp in closePrices {
    sticks.append(CandleStick(cp))
}

sticks.calculateRSI()
