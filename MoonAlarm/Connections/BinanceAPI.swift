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
            guard jsonResponse["code"].int == nil else {
                // there is an error code returned
                print("Code: \(jsonResponse["code"].intValue) Error: \(jsonResponse["msg"].stringValue)")
                callback(false, [])
                return
                
                // Example data:
                // { "code" : -1003, "msg" : "Way too many requests; IP banned until 1515547977300." }
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
    //      symbolPair - what symbol to return candlestick data from
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
            guard jsonResponse["code"].int == nil else {
                // there is an error code returned
                print("Code: \(jsonResponse["code"].intValue) Error: \(jsonResponse["msg"].stringValue)")
                callback(false, [])
                return
                
                // Example data:
                // { "code" : -1003, "msg" : "Way too many requests; IP banned until 1515547977300." }
            }
            
            // Data is an array of array (see example data in Candlestick initializer)
            for (_ ,cStickJson):(String, JSON) in jsonResponse {
                
                candleSticks.append(CandleStick(fromJson: cStickJson))
            }
            
            
            
            callback(true, candleSticks)
        }
    }
    
    // getOrderBook Method
    // Returns candlestick data from a given symbol pair
    // Parameters:
    //      symbolPair - what symbol to return order book data from
    //      limit - number of orders in book (5, 10, 20, 50, 100, 500, 1000 permitted)
    
    func getOrderBook(symbolPair: String, limit: Int = 5,
                      callback: @escaping (_ isSuccessful: Bool, _ orderBook: OrderBook) -> Void) {
        
        let url = rootURLString + "/api/v1/depth"
        let params = ["symbol": symbolPair,
                      "limit": String(limit)]
        
        Alamofire.request(url, method: .get, parameters: params).responseSwiftyJSON {
            response in
            guard response.result.isSuccess else {
                print("get order book data unsuccessful")
                print(response.result.value ?? JSON.null)
                callback(false, OrderBook(symbol: "error"))
                return
            }
            guard let jsonResponse = response.result.value else {
                print("get order book returned no data")
                callback(false, OrderBook(symbol: "error"))
                return
            }
            guard jsonResponse["code"].int == nil else {
                // there is an error code returned
                print("Code: \(jsonResponse["code"].intValue) Error: \(jsonResponse["msg"].stringValue)")
                callback(false, OrderBook(symbol: "error"))
                return
                
                // Example data:
                // { "code" : -1003, "msg" : "Way too many requests; IP banned until 1515547977300." }
            }
            
            let pairSymbol = TradeSession.instance.tradingPair
            let symbol = symbolPair.replacingOccurrences(of: pairSymbol, with: "")
            let newOrderBook = OrderBook(symbol: symbol, fromJson: jsonResponse)
            
            callback(true, newOrderBook)
        }
    }

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

extension OrderBook {
    
    convenience init(symbol sym: String, fromJson json: JSON) {
        
        // Data is a dictionary of arrays
        // Example: [{"bids" : [[Price, Quantity], [Price, Quantity]]}]
        let bidsJson = json["bids"]
        let asksJson = json["asks"]
        
        var bids = [Order]()
        var asks = [Order]()
        
        for (_ ,bidJson):(String, JSON) in bidsJson {
            bids.append(Order(fromJson: bidJson))
        }
        
        for (_ ,askJson):(String, JSON) in asksJson {
            asks.append(Order(fromJson: askJson))
        }
        
        self.init(symbol: sym, asks: asks, bids: bids)
        
        //    Example Data
        //    Dictionary of arrays
        //    {
        //    "lastUpdateId": 1027024,
        //    "bids": [
        //    [
        //    "4.00000000",     // PRICE
        //    "431.00000000",   // QTY
        //    []                // Can be ignored
        //    ]
        //    ],
        //    "asks": [
        //    [
        //    "4.00000200",
        //    "12.00000000",
        //    []
        //    ]
        //    ]
        //    }
        
    }
    
}

extension Order {
    
    // Data is an array: [Price, Quantity]
    convenience init(fromJson json: JSON) {
        self.init(price: json[0].doubleValue, quantity: json[1].doubleValue)
    }
}
