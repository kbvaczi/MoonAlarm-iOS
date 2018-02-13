// http://stockcharts.com/school/doku.php?id=chart_school:technical_indicators:stochrsi


import Foundation

class CandleStick {
    
    ////////// Price //////////
    
    let rsi: Double?
    var stochRSI: Double? = nil
    var stochRSIK: Double? = nil
    var stochRSID: Double? = nil
    
    ////////// Initializer //////////
    
    init(_ rsi: Double?) {
        self.rsi = rsi
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
}

extension Array where Element : CandleStick {
    
    /// Calculates and populates candlesticks with stochastic RSI value
    func calculateStochRSI() {
        /// RSI Period
        let lengthRSI = 14
        /// Stochastic period
        let lengthStoch = 14
        /// Smooth signal of stocastic RSI
        let smoothK = 3
        /// Smooth signal of smoothed stochastic RSI
        let smoothD = 3
        
        // RSI needs a minimum of 2 * period to be accurate
        guard   self.count > (2 * lengthRSI),
            self.last?.rsi != nil
            else {
                
                NSLog("Unable to calculate Stochastic RSI")
                return
        }
        
        let smaK = SMA(smoothK)
        let smaD = SMA(smoothD)
        
        for (index, stick) in self.enumerated() {
            /// Ignore data points before we have minimum RSI points for calculation
            guard   index >= (lengthRSI + lengthStoch - 1), lengthStoch <= lengthRSI,
                smoothK < lengthStoch, smoothD < lengthStoch
                else { continue }
            
            let prefix = index + 1
            let minMaxGroup = self.prefix(prefix).suffix(lengthStoch).filter({ $0.rsi != nil })
                .map({ $0.rsi! })
            
            /// Verify min and max have values
            guard   let currentRSI = stick.rsi,
                let minRSI = minMaxGroup.min(),
                let maxRSI = minMaxGroup.max()
                else { continue }
            
            let newStochRSI = (currentRSI - minRSI) / (maxRSI - minRSI)
            
            stick.stochRSI = newStochRSI
            
            smaK.add(next: newStochRSI * 100)
            if let newK = smaK.currentAvg {
                stick.stochRSIK = newK
                smaD.add(next: newK)
                if let newD = smaD.currentAvg {
                    stick.stochRSID = newD
                }
            }
        }
        
    }
    
    //  Example Calculation:
    //    lengthRSI = 10 //RSI period
    //    lengthStoch = 10 //Stochastic period
    //    smoothK = 10 //Smooth signal of stochastic RSI
    //    smoothD = 3 //Smooth signal of smoothed stochastic RSI
    //
    //    myRSI = RSI[lengthRSI](close)
    //    MinRSI = lowest[lengthStoch](myrsi)
    //    MaxRSI = highest[lengthStoch](myrsi)
    //
    //    StochRSI = (myRSI-MinRSI) / (MaxRSI-MinRSI)
    //
    //    K = average[smoothK](stochrsi)*100
    //    D = average[smoothD](K)
    
}

var sticks = [CandleStick]()
let rsis  = [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 54.0907, 59.8981, 58.1992, 59.7562, 52.3508, 52.8207, 56.9367, 57.4695, 55.2607, 57.5080, 54.8013, 51.4717, 56.1598, 58.3369, 56.0218, 60.2219, 56.7477, 57.3832, 50.2306, 57.0617, 61.5069, 63.6927, 66.2177, 69.1576, 70.7253, 67.7876, 68.8154, 62.3843, 67.5881, 67.5881]

for rsi in rsis {
    sticks.append(CandleStick(rsi))
}

sticks.calculateStochRSI()
