//
//  BinanceAPI.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/6/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import AlamofireSwiftyJSON

class BinanceAPI {
    // Declare singleton
    static let instance = BinanceAPI()
    // Disallow multiple instances
    private init() {}
    
    let rootURLString = "https:/api.binance.com"
    
    // getAllSymbols Method
    // Returns list of all available symbols with selected trading pair
    
    func getAllSymbols(forTradingPair tradingPairSymbol: String = "BTC",
                       callback: @escaping (_ isSuccessful: Bool, _ symbols: [String]) -> Void) {
        
        let url = rootURLString + "/api/v1/ticker/allPrices"
        var symbolsList = [String]()
        
        Alamofire.request(url, method: .get).responseSwiftyJSON { response in
            guard response.result.isSuccess else {
                print("get symbols unsuccessful")
                print(response.result.value ?? JSON.null)
                callback(false, [])
                return
            }
            guard let jsonResponse = response.result.value else {
                print("get symbols returned no data")
                callback(false, [])
                return
            }
            
            // Data is an array of dictionaries
            // Example data: [{"price" : "0.05919500","symbol" : "ETHBTC"}]
            for (_ ,subJson):(String, JSON) in jsonResponse {
                let symbolPair = subJson["symbol"].stringValue
                if symbolPair.hasSuffix(tradingPairSymbol) {
                    let symbol = symbolPair.replacingOccurrences(of: tradingPairSymbol, with: "")
                    symbolsList.append(symbol)
                }
            }
            
            callback(true, symbolsList)
        }        
    }
    
    // getKLineData Method
    // Returns candlestick data from a given symbol pair
    // Parameters:
    //      symbolPair - what symbol to return candlestick data form
    //      interval - time interval for candlesticks
    //      limit - number of candlesticks to get, starting from present time
    
    func getKLineData(symbolPair: String, interval: KLineInterval, limit: Int = 2,
                      callback: @escaping (_ isSuccessful: Bool, _ candleSticks: CandleSticks) -> Void) {
        
        let url = rootURLString + "/api/v1/klines"
        let params = ["symbol": symbolPair,
                      "interval": interval.rawValue,
                      "limit": String(limit)]
        
        var candleSticks = [CandleStick]()
        
        Alamofire.request(url, method: .get, parameters: params).responseSwiftyJSON {
            response in
            guard response.result.isSuccess else {
                print("get kline data unsuccessful")
                print(response.result.value ?? JSON.null)
                callback(false, [])
                return
            }
            guard let jsonResponse = response.result.value else {
                print("get kline data returned no data")
                callback(false, [])
                return
            }
            
            // Data is an array of array (see example data in Candlestick initializer)
            for (_ ,cStickJson):(String, JSON) in jsonResponse {
                candleSticks.append(CandleStick(fromJson: cStickJson))
            }
            
            callback(true, candleSticks)
        }
    }
    
//    // getVolumeRatio Method
//    // computes normalized trading volume for the last KLineInterval over the previous period
//    // Parameters:
//    //      symbolPair -    symbol for coin plus trading pair, ex: "LTCBTC"
//    //      last -          kline interval to compare volume for
//    //      forPeriod -     number of periods to compare, ex: last m5, forPeriod 4 looks at normalized volume
//    //                      from last 5 minutes compared to the last 20 minutes
//    // Returns: volume ratio, candlesticks
//
//    func getVolumeRatio(symbolPair: String, last: KLineInterval = .m5, forPeriod period: Int = 4,
//                        callback: @escaping (_ isSuccessful: Bool, _ volRatio: Double,
//                                             _ candleSticks: [CandleStick]) -> Void) {
//
//        getKLineData(symbolPair: symbolPair, interval: last, limit: period) {
//            (isSuccess, candleSticks) in
//
//            guard isSuccess, candleSticks.count >= period else {
//                callback(false, 0.0, [])
//                return
//            }
//
//            let volRatio = TradingCalcs.volumeRatio(cSticks: candleSticks, last: 1, period: period)
//
//            callback(true, volRatio, candleSticks)
//        }
//    }
//
//    // getPriceRatio Method
//    // compares last close price for the last KLineInterval over the previous period
//    // Parameters:
//    //      symbolPair -    symbol for coin plus trading pair, ex: "LTCBTC"
//    //      last -          kline interval to compare volume for
//    //      forPeriod -     number of periods to compare, ex: last m1, forPeriod 5 looks at the last 1 minute price
//    //                      compared to the average 5 minute price
//    // Returns: price ratio, candlesticks
//
//    func getPriceRatio(symbolPair: String, last: KLineInterval = .m1, forPeriod period: Int = 5,
//                        callback: @escaping (_ isSuccessful: Bool, _ volRatio: Double,
//        _ candleSticks: [CandleStick]) -> Void) {
//
//        getKLineData(symbolPair: symbolPair, interval: last, limit: period) {
//            (isSuccess, candleSticks) in
//
//            guard isSuccess, candleSticks.count >= period else {
//                callback(false, 0.0, [])
//                return
//            }
//
//            let priceRatio = TradingCalcs.priceRatio(cSticks: candleSticks, last: 1, period: period)
//
//            callback(true, priceRatio, candleSticks)
//        }
//    }

    enum KLineInterval: String {
        case m1 = "1m"
        case m3 = "3m"
        case m5 = "5m"
        case m15 = "15m"
        case m30 = "30m"
        case h1 = "1h"
        case h12 = "12h"
        case d1 = "1d"
    }
    
}

extension CandleStick {

    convenience init(fromJson json: JSON) {
        
        
        /* Example data:
         [
            [1499040000000,      // Open time
             "0.01634790",       // Open
             "0.80000000",       // High
             "0.01575800",       // Low
             "0.01577100",       // Close
             "148976.11427815",  // Volume
             1499644799999,      // Close time
             "2434.19055334",    // Quote asset volume
             308,                // Number of trades
             "1756.87402397",    // Taker buy base asset volume
             "28.46694368",      // Taker buy quote asset volume
             "17928899.62484339"] // Can be ignored
         ]*/
    
        self.init(openTime: (json[0].doubleValue as Milliseconds).msToSeconds(),
                  closeTime: (json[6].doubleValue as Milliseconds).msToSeconds(),
                  openPrice: json[1].doubleValue, closePrice: json[4].doubleValue,
                  highPrice: json[2].doubleValue, lowPrice: json[3].doubleValue,
                  volume: json[5].doubleValue, pairVolume: json[7].doubleValue,
                  tradesCount: json[8].intValue)
    }
}
