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
    
    static let instance = BinanceAPI() // Declare singleton
    
    private init() {} // Disallow multiple instances
    
    let rootURLString = "https:/api.binance.com"
    
    // Track if we're banned for sending too many requests
    var bannedUntil: Milliseconds? = nil
    
    // jsonRequest Method
    // General request method used as a root for other request methods to standardize error logging
    
    private func jsonRequest(url: String, method: HTTPMethod,
                        params: Parameters? = nil, headers: HTTPHeaders? = nil,
                        callback: @escaping (_ isSuccessful: Bool, _ jsonResponse: JSON) -> Void) {
        
        Alamofire.request(url, method: method, parameters: params, headers: headers)
                .validate(statusCode: 200..<300)
                .validate(contentType: ["application/json"])
                .responseSwiftyJSON { response in
                            
            guard response.result.isSuccess else {
                print("*** Request to \(url) unsuccessful ***")
                print("Parameters: \(params ?? [:])")
                if let error = response.result.error {
                    print("Error: \(error)")
                }
                callback(false, JSON.null)
                return
            }
            guard let jsonResponse = response.result.value else {
                print("*** Request to \(url) returned no data ***")
                print("Parameters:")
                print(params ?? "no parameters")
                callback(false, JSON.null)
                return
            }
            guard jsonResponse["code"].int == nil else {
                print("*** Error in request to \(url) ***")
                print("Parameters:")
                print(params ?? "no parameters")
                print("Code: \(jsonResponse["code"].intValue) Error: \(jsonResponse["msg"].stringValue)")
                
                // Example data:
                // { "code" : -1003, "msg" : "Way too many requests; IP banned until 1515547977300." }
                
                let isBannedForFlooding = jsonResponse["code"].intValue == -1003
                if isBannedForFlooding {
                    let message = jsonResponse["msg"].stringValue
                    self.setBannedUntilTime(fromMessage: message)
                }
                
                callback(false, JSON.null)
                return
            }
            callback(true, jsonResponse)
        }
    }
    
    // signedJsonRequest Method
    // General request method used as a root for other request methods to standardize error logging
    // Used for requests that require sending API key and encrypted message authentication
    
    private func signedJsonRequest(url: String, method: HTTPMethod,
                                   params: Parameters? = nil, headers: HTTPHeaders? = nil,
                                   callback: @escaping (_ isSuccessful: Bool, _ jsonResponse: JSON) -> Void) {

        Alamofire.request(url, method: method, parameters: params, encoding: SignedEncoding(), headers: headers)
                .validate(statusCode: 200..<300)
                .validate(contentType: ["application/json"])
                .responseSwiftyJSON { response in
                
            guard response.result.isSuccess else {
                print("*** Request to \(url) unsuccessful ***")
                print("Parameters: \(params ?? [:])")
                if let error = response.result.error {
                    print("Error: \(error)")
                }
                callback(false, JSON.null)
                return
            }
            guard let jsonResponse = response.result.value else {
                print("*** Request to \(url) returned no data ***")
                print("Parameters:")
                print(params ?? "no parameters")
                callback(false, JSON.null)
                return
            }
            guard jsonResponse["code"].int == nil else {
                print("*** Error in request to \(url) ***")
                print("Parameters:")
                print(params ?? "no parameters")
                print("Code: \(jsonResponse["code"].intValue) Error: \(jsonResponse["msg"].stringValue)")
                
                // Example data:
                // { "code" : -1003, "msg" : "Way too many requests; IP banned until 1515547977300." }
                
                let isBannedForFlooding = jsonResponse["code"].intValue == -1003
                if isBannedForFlooding {
                    let message = jsonResponse["msg"].stringValue
                    self.setBannedUntilTime(fromMessage: message)
                }
                
                callback(false, JSON.null)
                return
            }
            callback(true, jsonResponse)
        }
    }
    
    // getCurrentServerTime Method
    // Returns current timeo of server in milliseconds
    
    func getCurrentServerTime(callback: @escaping (_ isSuccessful: Bool, _ currentTime: Milliseconds) -> Void) {
        
        let url = rootURLString + "/api/v1/time"
        
        jsonRequest(url: url, method: .get, params: nil) {
            (isSuccessful, jsonResponse) in
            
            let currentServerTime = jsonResponse["serverTime"].intValue
            
            callback(true, Milliseconds(currentServerTime))
        }
        
        // Example Data:
        // { "serverTime": 1499827319559 }
    }
    
    // isBannedForRequestFlooding Method
    // Check to see if we're banned for flooding before sending requests
    
    func isBannedForRequestFlooding() -> Bool {
        guard let bannedUntil = self.bannedUntil else { return false }
        let currentTime = ExchangeClock.instance.currentTime
        if currentTime > bannedUntil {
            self.bannedUntil = nil
            return false
        }
        return true
    }
    
    // setIsBannedTime Method
    // When server response with message saying we're banned, determine when ban is lifted
    
    func setBannedUntilTime(fromMessage msg: String) {
        let timeNumberLength = 13
        let regex = "\\d{\(timeNumberLength)}"
        
        guard   let bannedUntil = msg.matches(for: regex).first
                else { return }
        
        self.bannedUntil = Milliseconds(bannedUntil)
    }
    
    // getAllSymbols Method
    // Returns list of all available symbols with selected trading pair
    
    func getAllSymbols(forTradingPair tradingPairSymbol: String,
                       callback: @escaping (_ isSuccessful: Bool, _ symbols: [Symbol]?) -> Void) {
        
        let url = rootURLString + "/api/v1/ticker/allPrices"
        var symbolsList = [String]()
        
        jsonRequest(url: url, method: .get, params: nil) {
            (isSuccessful, jsonResponse) in
            
            guard isSuccessful else {
                callback(false, nil)
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
    
    // get24HrPairVolume Method
    // Returns 24hr pair volume of given symbol
    
    func get24HrPairVolume(forTradingPair tradingPair: String,
                       callback: @escaping (_ isSuccessful: Bool, _ volume: Double?) -> Void) {
        
        let url = rootURLString + "/api/v1/ticker/24hr"
        let params = ["symbol": tradingPair]
        
        jsonRequest(url: url, method: .get, params: params) {
            (isSuccessful, jsonResponse) in
            
            guard isSuccessful else {
                callback(false, nil)
                return
            }
            
            // Data is a dictionary
            /*
            {
                "priceChange": "-94.99999800",
                "priceChangePercent": "-95.960",
                "weightedAvgPrice": "0.29628482",
                "prevClosePrice": "0.10002000",
                "lastPrice": "4.00000200",
                "bidPrice": "4.00000000",
                "askPrice": "4.00000200",
                "openPrice": "99.00000000",
                "highPrice": "100.00000000",
                "lowPrice": "0.10000000",
                "volume": "8913.30000000",
                "openTime": 1499783499040,
                "closeTime": 1499869899040,
                "fristId": 28385,   // First tradeId
                "lastId": 28460,    // Last tradeId
                "count": 76         // Trade count
            }
            */
            
            let volume = jsonResponse["volume"].doubleValue
            let price = jsonResponse["lastPrice"].doubleValue
            let pairVolume = volume * price
            callback(true, pairVolume)
        }
    }
    
    // getCandleSticks Method
    // Returns candlestick data from a given symbol pair
    // Parameters:
    //      symbolPair - what symbol to return candlestick data from
    //      interval - time interval for candlesticks
    //      limit - number of candlesticks to get, starting from present time going backwards
    
    func getCandleSticks(symbolPair: String, interval: KLineInterval, limit: Int = 2,
                      callback: @escaping (_ isSuccessful: Bool, _ candleSticks: CandleSticks?) -> Void) {
        
        let url = rootURLString + "/api/v1/klines"
        let params = ["symbol": symbolPair,
                      "interval": interval.rawValue,
                      "limit": String(limit)]
        
        var candleSticks = [CandleStick]()
        
        jsonRequest(url: url, method: .get, params: params) {
            (isSuccessful, jsonResponse) in
            
            guard isSuccessful else {
                callback(false, nil)
                return
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
    
    func getOrderBook(symbolPair: String, limit: Int = 50,
                      callback: @escaping (_ isSuccessful: Bool, _ orderBook: OrderBook?) -> Void) {
        
        let url = rootURLString + "/api/v1/depth"
        let params = ["symbol": symbolPair,
                      "limit": String(limit)]
        
        jsonRequest(url: url, method: .get, params: params) {
            (isSuccessful, jsonResponse) in
            
            guard isSuccessful else {
                callback(false, nil)
                return
            }
            
            let pairSymbol = TradeStrategy.instance.tradingPairSymbol
            let symbol = symbolPair.replacingOccurrences(of: pairSymbol, with: "")
            let newOrderBook = OrderBook(symbol: symbol, fromJson: jsonResponse)
            
            callback(true, newOrderBook)
        }
    }
    
    ///////// SIGNED REQUESTS ///////////
    
    func getOpenOrders(forSymbolPair sP: String,
                       callback: @escaping (_ isSuccess: Bool, _ orders: TradeOrders?) -> Void) {
        
        let url = rootURLString + "/api/v3/openOrders"
        let head = ["X-MBX-APIKEY": BinanceAPI.apiKey]
        
        let params: Parameters = ["symbol": sP,
                                  "timestamp": ExchangeClock.instance.currentTime]
        
        signedJsonRequest(url: url, method: .get, params: params, headers: head) {
            (isSuccessful, jsonResponse) in
            
            guard isSuccessful else {
                callback(false, nil)
                return
            }

            print("JSON \(jsonResponse)")
        }
    }
    
    func postNewOrder(for order: TradeOrder,
                       callback: @escaping (_ isSuccess: Bool, _ order: TradeOrder?) -> Void) {
        
        let url = rootURLString + "/api/v3/order" + (order.isTestOrder ? "/test" : "")
        let head = ["X-MBX-APIKEY": BinanceAPI.apiKey]
        var params: Parameters = ["symbol": order.symbolPair,
                                  "side": order.side.rawValue,
                                  "type": order.type.rawValue,
                                  "quantity": order.quantityOrdered,
                                  "timestamp": ExchangeClock.instance.currentTime]
        
        if order.type != .market {
            params["timeInForce"] = order.timeInForce.rawValue
            params["price"] = order.price?.rounded8
        }
        
        signedJsonRequest(url: url, method: .post, params: params, headers: head) {
            (isSuccessful, jsonResponse) in
            
            guard isSuccessful else {
                callback(false, nil)
                return
            }
            
            // Example Response:
            // {  "symbol":"LTCBTC",
            //    "orderId": 1,
            //    "clientOrderId": "myOrder1" // Will be newClientOrderId
            //    "transactTime": 1499827319559 }
            
            let clientOrderID = jsonResponse["clientOrderId"].stringValue
            order.uid = clientOrderID
            
            print("JSON \(jsonResponse)")
            callback(true, order)
        }
    }
    
    ///////// DATA STREAMS //////////
    
    func startUserDataStream(forSymbolPair sP: String, apiKey: String,
                             callback: @escaping (_ isSuccess: Bool, _ listenKey: String?) -> Void) {
        
        let url = rootURLString + "/api/v1/userDataStream"
        let head = ["X-MBX-APIKEY": apiKey]
        
        jsonRequest(url: url, method: .post, headers: head) {
            (isSuccessful, jsonResponse) in
            
            guard isSuccessful else {
                callback(false, nil)
                return
            }
            
            // Example Data:
            // {"listenKey": "pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1"}
            
            let listenKey = jsonResponse["listenKey"].stringValue
            print("listenKey \(listenKey)")
            callback(true, listenKey)
        }
        
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
    
        self.init(openTime: (json[0].intValue as Milliseconds),
                  closeTime: (json[6].intValue as Milliseconds),
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
