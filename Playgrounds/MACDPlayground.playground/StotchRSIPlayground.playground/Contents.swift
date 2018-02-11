// http://investexcel.net/how-to-calculate-macd-in-excel/

import Foundation

class CandleStick {
    
    ////////// Price //////////
    
    let closePrice: Double
    var macd: Double? = nil
    var macdSignal: Double? = nil
    var ema26: Double? = nil
    
    ////////// Initializer //////////
    
    init(_ closePrice: Double) {
        self.closePrice = closePrice
    }
    
}

extension Array where Element : CandleStick {
    
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
            //            let newAvg = next * weightFactor + currentAvg * (1-weightFactor)
            
            return newAvg
        }
        
    }
    
}

extension Array where Element : CandleStick {
    
    func calculateMACD() {
        
        // need a minimum of 2 * period candlesticks to be accurate
        guard self.count > 50 else { return }
        
        let ema26 = EMA(26)
        let ema12 = EMA(12)
        let signal = EMA(9)
        
        for stick in self {
            
            let currentClosePrice = stick.closePrice
            
            ema26.add(next: currentClosePrice)
            ema12.add(next: currentClosePrice)
            
            if let ema26Avg = ema26.currentAvg, let ema12Avg = ema12.currentAvg {
                stick.ema26 = ema26Avg
                let macd = ema12Avg - ema26Avg
                stick.macd = macd
                signal.add(next: macd)
                if let newSignal = signal.currentAvg {
                    stick.macdSignal = newSignal
                }
            }
        }
    }
    
}

var sticks = [CandleStick]()
let closePrices  = [459.99, 448.85, 446.06, 450.81, 442.8, 448.97, 444.57, 441.4, 430.47, 420.05, 431.14, 425.66, 430.58, 431.72, 437.87, 428.43, 428.35, 432.5, 443.66, 455.72, 454.49, 452.08, 452.73, 461.91, 463.58, 461.14, 452.08, 442.66, 428.91, 429.79, 431.99, 427.72, 423.2, 426.21, 426.98, 435.69, 434.33, 429.8, 419.85, 426.24, 402.8, 392.05, 390.53, 398.67, 406.13, 405.46, 408.38, 417.2, 430.12, 442.78, 439.29, 445.52, 449.98, 460.71, 458.66, 463.84, 456.77, 452.97, 454.74, 443.86, 428.85, 434.58, 433.26, 442.93, 439.66, 441.35
]

for cp in closePrices {
    sticks.append(CandleStick(cp))
}

sticks.calculateMACD()
sticks.last?.macd
sticks.last?.macdSignal








