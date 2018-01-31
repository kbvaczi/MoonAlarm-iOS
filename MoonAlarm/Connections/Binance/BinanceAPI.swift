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
    
    // Disallow multiple instances by marking initializer private
    private init() { }
    
    let rootURLString = "https:/api.binance.com"
    
    // Track if we're banned for sending too many requests
    var bannedUntil: Milliseconds? = nil
    
    var sessionMgr = SessionManager()
    
    // jsonRequest Method
    // General request method used as a root for other request methods to standardize error logging
    
    private func jsonRequest(url: String, method: HTTPMethod,
                        params: Parameters? = nil, headers: HTTPHeaders? = nil,
                        callback: @escaping (_ isSuccessful: Bool, _ jsonResponse: JSON) -> Void) {
        
        guard !isBannedForRequestFlooding() else {
            callback(false, JSON.null)
            return
        }
        
        sessionMgr.request(url, method: method, parameters: params, headers: headers)
                .validate(contentType: ["application/json"])
                .responseSwiftyJSON { response in
                    
            guard   let jsonResponse = response.result.value else {
                print("*** Request to \(url) unsuccessful *** NO DATA RETURNED ***")
                callback(false, JSON.null)
                return
            }
            guard   response.result.isSuccess else {
                        
                // HTTP 5XX return codes are used for binance errors
                guard response.response?.statusCode != 502 else {
                    callback(false, JSON.null)
                    return
                }
                // HTTP 429 return code is used when breaking a request rate limit.
                if response.response?.statusCode == 429 {
                    let message = jsonResponse["msg"].stringValue
                    self.setBannedUntilTime(fromMessage: message)
                }
                
                print("*** Request to \(url) unsuccessful ***")
                print("Parameters: \(params ?? [:])")
                if let error = response.error {
                    print("Error: \(error)")
                }
                print("Code: \(jsonResponse["code"].intValue) Error: \(jsonResponse["msg"].stringValue)")
                        
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

        guard !isBannedForRequestFlooding() else {
            callback(false, JSON.null)
            return
        }
        
        sessionMgr.request(url, method: method, parameters: params, encoding: SignedEncoding(), headers: headers)
                .validate(contentType: ["application/json"])
                .responseSwiftyJSON { response in
                
            // HTTP 5XX return codes are used for binance errors
            guard response.response?.statusCode != 502 else {
                callback(false, JSON.null)
                return
            }
                    
            guard let jsonResponse = response.result.value else {
                print("*** Request to \(url) unsuccessful ***")
                print("no data returned")
                callback(false, JSON.null)
                return
            }
                    
            // HTTP 429 return code is used when breaking a request rate limit.
            guard response.response?.statusCode != 429 else {
                let message = jsonResponse["msg"].stringValue
                self.setBannedUntilTime(fromMessage: message)
                callback(false, JSON.null)
                return
            }
                    
            guard jsonResponse["code"].int == nil else {
                print("*** Request to \(url) unsuccessful ***")
                if let statusCode = response.response?.statusCode {
                    print("HTTP Status Code: \(statusCode)")
                }
                print("Parameters: \(params ?? [:])")
                print("Code: \(jsonResponse["code"].intValue) Error: \(jsonResponse["msg"].stringValue)")
                callback(false, JSON.null)
                return
            }
                    
            callback(true, jsonResponse)
        }
    }
    
    /// Check to see if we're banned for flooding before sending requests
    ///
    /// - Returns: true if we are banned for flooding
    private func isBannedForRequestFlooding() -> Bool {
        guard let bannedUntil = self.bannedUntil else { return false }
        let currentTime = ExchangeClock.instance.currentTime
        if currentTime > bannedUntil {
            self.bannedUntil = nil
            return false
        }
        return true
    }
    
    /// Parses response from server to determine how long we're banned
    ///
    /// - Parameter msg: message from server including timestamp
    private func setBannedUntilTime(fromMessage msg: String) {
        let timeNumberLength = 13
        let regex = "\\d{\(timeNumberLength)}"
        
        guard   let bannedUntil = msg.matches(for: regex).first
            else { return }
        
        self.bannedUntil = Milliseconds(bannedUntil)
    }
    
    /// Get current server time in milliseconds
    ///
    /// - Parameter callback: do this after getting time
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
    
    /// Get exchange information for each symbol including lot size and price filter
    ///
    /// - Parameter callback: Do this after
    func getExchangeInfo(callback: @escaping (_ isSuccessful: Bool,
                                              _ info: [ExchangeInfo.SymbolPairInfo]?) -> Void) {
        
        let url = rootURLString + "/api/v1/exchangeInfo"
        
        jsonRequest(url: url, method: .get, params: nil) {
            (isSuccessful, jsonResponse) in
            
            guard isSuccessful else {
                callback(false, nil)
                return
            }
            
            var pairInfo = [ExchangeInfo.SymbolPairInfo]()
            
            for (_ ,symbolInfoJson):(String, JSON) in jsonResponse["symbols"] {
                let newInfo = ExchangeInfo.SymbolPairInfo(fromJson: symbolInfoJson)
                pairInfo.append(newInfo)
            }
            
            callback(true, pairInfo)
            
                    //    {
                    //        "symbols": [{
                    //            "symbol": "ETHBTC",
                    //            "status": "TRADING",
                    //            "baseAsset": "ETH",
                    //            "baseAssetPrecision": 8,
                    //            "quoteAsset": "BTC",
                    //            "quotePrecision": 8,
                    //            "orderTypes": ["LIMIT", "MARKET"],
                    //            "icebergAllowed": false,
                    //            "filters": [{
                    //                "filterType": "PRICE_FILTER",
                    //                "minPrice": "0.00000100",
                    //                "maxPrice": "100000.00000000",
                    //                "tickSize": "0.00000100"
                    //                }, {
                    //                "filterType": "LOT_SIZE",
                    //                "minQty": "0.00100000",
                    //                "maxQty": "100000.00000000",
                    //                "stepSize": "0.00100000"
                    //                }, {
                    //                "filterType": "MIN_NOTIONAL",
                    //                "minNotional": "0.00100000"
                    //            }]
                    //        }]
                    //    }
        }
    }
    
    /// Returns list of all available symbols with selected trading pair
    ///
    /// - Parameters:
    ///   - tradingPairSymbol: symbol for trading pair
    ///   - callback: do this after retrieving symbols
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

    /// Returns 24hr pair volume of given symbol
    ///
    /// - Parameters:
    ///   - tradingPair: symbol for trading pair
    ///   - callback: do this after
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
            
            let volume = jsonResponse["volume"].doubleValue
            let price = jsonResponse["lastPrice"].doubleValue
            let pairVolume = volume * price
            callback(true, pairVolume)
            
            // Data is a dictionary
            //    {
            //    "priceChange": "-94.99999800",
            //    "priceChangePercent": "-95.960",
            //    "weightedAvgPrice": "0.29628482",
            //    "prevClosePrice": "0.10002000",
            //    "lastPrice": "4.00000200",
            //    "bidPrice": "4.00000000",
            //    "askPrice": "4.00000200",
            //    "openPrice": "99.00000000",
            //    "highPrice": "100.00000000",
            //    "lowPrice": "0.10000000",
            //    "volume": "8913.30000000",
            //    "openTime": 1499783499040,
            //    "closeTime": 1499869899040,
            //    "fristId": 28385,   // First tradeId
            //    "lastId": 28460,    // Last tradeId
            //    "count": 76         // Trade count
            //    }
        }
    }

    /// Returns candlestick data from a given symbol pair
    ///
    /// - Parameters:
    ///   - symbolPair: what symbol to return candlestick data from
    ///   - interval: time interval for candlesticks
    ///   - limit: number of candlesticks to get, starting from present time going backwards
    ///   - callback: Do this after retrieval
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

    
    /// Returns orderbook data from a given symbol pair
    ///
    /// - Parameters:
    ///   - symbolPair: what symbol to return order book data from
    ///   - limit: number of orders in book (5, 10, 20, 50, 100, 500, 1000 permitted)
    ///   - callback: Perform this after retrieval of orderbook
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
    
    /*
    /////////////////////////////////////
    ///////// SIGNED REQUESTS ///////////
    /////////////////////////////////////
    */
    
    /// Retrieve balance available to trade for specified coin
    ///
    /// - Parameters:
    ///   - symbol: symbol of coin to retrieve balance for
    ///   - callback: do this after retrieving balance
    func getBalance(for symbol: Symbol,
                    callback: @escaping (_ isSuccess: Bool, _ balance: Double?) -> Void) {
        
        let url = rootURLString + "/api/v3/account"
        let head = ["X-MBX-APIKEY": BinanceAPI.apiKey]
        
        let params: Parameters = ["timestamp": ExchangeClock.instance.currentTime]
        
        signedJsonRequest(url: url, method: .get, params: params, headers: head) {
            (isSuccessful, jsonResponse) in
            
            guard isSuccessful else {
                callback(false, nil)
                return
            }
            
            // Data is an array of dictionary
            for (_ , assetJson):(String, JSON) in jsonResponse["balances"] {
                
                if  let assetSymbol = assetJson["asset"].string,
                    assetSymbol == symbol {
                    
                    let balance = assetJson["free"].doubleValue
                    callback(true, balance)
                    return
                }
            }
            
            callback(false, nil)
            
            /* Example Response:
            {
                "makerCommission": 15,
                "takerCommission": 15,
                "buyerCommission": 0,
                "sellerCommission": 0,
                "canTrade": true,
                "canWithdraw": true,
                "canDeposit": true,
                "updateTime": 123456789,
                "balances": [
                {
                "asset": "BTC",
                "free": "4723846.89208129",
                "locked": "0.00000000"
                },
                {
                "asset": "LTC",
                "free": "4763368.68006011",
                "locked": "0.00000000"
                }
                ]
            }
            */            
        }
    }
    
    
    /// Get open orders for specified symbol pair
    ///
    /// - Parameters:
    ///   - symbolPair: Symbol pair to retrieve orders for
    ///   - callback: Do this after retrieving orders
    func getOpenOrders(for symbolPair: String,
                       callback: @escaping (_ isSuccess: Bool, _ orders: TradeOrders?) -> Void) {
        
        let url = rootURLString + "/api/v3/openOrders"
        let head = ["X-MBX-APIKEY": BinanceAPI.apiKey]
        
        let params: Parameters = ["symbol": symbolPair,
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
    
    /// Send a new order to Binance
    ///
    /// - Parameters:
    ///   - order: Order object describing order
    ///   - callback: Do this after order placed
    func postNewOrder(for order: TradeOrder,
                       callback: @escaping (_ isSuccess: Bool, _ order: TradeOrder?) -> Void) {
        
        let url = rootURLString + "/api/v3/order" + (order.isTestOrder ? "/test" : "")
        let head = ["X-MBX-APIKEY": BinanceAPI.apiKey]
        var params: Parameters = ["symbol": order.symbolPair,
                                  "side": order.side.rawValue,
                                  "type": order.type.rawValue,
                                  "quantity": order.quantityOrdered.toDisplay,
                                  "newOrderRespType": BinanceAPI.NewOrderRespType.full.rawValue,
                                  "timestamp": ExchangeClock.instance.currentTime]
        
        if order.type != .market {
            params["timeInForce"] = order.timeInForce.rawValue
            guard let price = order.orderPrice else {
                callback(false, nil)
                return
            }
            params["price"] = price.toDisplay
            if let ibq = order.quantityVisible {
                params["icebergQty"] = ibq.toDisplay
            }
        }
        
        signedJsonRequest(url: url, method: .post, params: params, headers: head) {
            (isSuccessful, jsonResponse) in
            
            guard isSuccessful else {
                callback(false, nil)
                return
            }
            
            self.updateOrder(order, from: jsonResponse)
            
            callback(true, order)
        }
    }
    
    
    /// Get status update for an order that has already been placed
    ///
    /// - Parameters:
    ///   - order: order to get status update for
    ///   - callback: what to do after status update recieved
    func getOrderUpdate(for order: TradeOrder,
                      callback: @escaping (_ isSuccess: Bool, _ order: TradeOrder?) -> Void) {
        
        // Verify order has been processed before proceeding
        guard let orderID = order.uid else {
            callback(false, nil)
            return
        }
        
        let url = rootURLString + "/api/v3/order"
        let head = ["X-MBX-APIKEY": BinanceAPI.apiKey]
        let params: Parameters = ["symbol": order.symbolPair,
                                  "orderId": orderID,
                                  "timestamp": ExchangeClock.instance.currentTime]
        
        signedJsonRequest(url: url, method: .get, params: params, headers: head) {
            (isSuccessful, jsonResponse) in
            
            guard isSuccessful else {
                callback(false, nil)
                return
            }
            
            self.updateOrder(order, from: jsonResponse)

            callback(true, order)
        }
    }
    
    /// Cancel an existing order
    ///
    /// - Parameters:
    ///   - order: order to be cancelled
    ///   - callback: do this after cancelled
    func cancelOrder(_ order: TradeOrder,
                    callback: @escaping (_ isSuccess: Bool, _ order: TradeOrder?) -> Void) {
        
        // Verify order has been processed before proceeding
        guard let orderID = order.uid else {
            callback(false, nil)
            return
        }
        
        let url = rootURLString + "/api/v3/order"
        let head = ["X-MBX-APIKEY": BinanceAPI.apiKey]
        let params: Parameters = ["symbol": order.symbolPair,
                                  "orderId": orderID,
                                  "timestamp": ExchangeClock.instance.currentTime]
        
        signedJsonRequest(url: url, method: .delete, params: params, headers: head) {
            (cancelSuccess, jsonResponse) in
            
            guard cancelSuccess else {
                callback(false, nil)
                return
            }
            
            // Unfortunately, binance doesn't give us an update when we cancel so we have to
            // update after cancellation (see json below)
            order.update(callback: { updateSuccess in
                callback(updateSuccess, order)
            })
            
                    //    Example JSON Response:
                    //    {
                    //    "orderId" : 16058114,
                    //    "symbol" : "IOTABTC",
                    //    "origClientOrderId" : "Z9Mekllm2mYteyTrdKqdir",
                    //    "clientOrderId" : "LuLLH2vxLfVhGSfLrCLngU"
                    //    }
        }
    }
    
    /// used to update order based on json response from server. Used in multiple functions.
    ///
    /// - Parameters:
    ///   - order: order to update
    ///   - json: json to update order with
    private func updateOrder(_ order: TradeOrder, from json: JSON) {
        
        // Set uid now that the order has been processed
        let orderID = json["orderId"].stringValue
        order.uid = orderID
        
        // Update quantity executed
        let newQtyFilled = json["executedQty"].doubleValue
        if newQtyFilled > 0 {
            order.quantityFilled = newQtyFilled
        }
        
        // Update status of order
        let newStatusString = json["status"].stringValue
        if let newStatus = BinanceAPI.OrderStatus(rawValue: newStatusString) {
            order.status = newStatus
        }
        
        // Update fills (expect this only from create response with market orders?)
        let fillsJSON = json["fills"]
        for (_ ,fillJson):(String, JSON) in fillsJSON {
            let price = fillJson["price"].doubleValue
            let qty = fillJson["qty"].doubleValue
            let fee = fillJson["commission"].doubleValue
            let feeAsset = fillJson["commissionAsset"].stringValue
            
            guard price > 0, qty > 0, fee > 0 else { continue }
            
            let newFill = TradeOrderFill(qty, atPrice: price, fee: fee, feeAsset: feeAsset)
            order.fills.append(newFill)
        }
               
                // Example Response:
                //    {
                //        "symbol": "BTCUSDT",
                //        "orderId": 28,
                //        "clientOrderId": "6gCrw2kRUAF9CvJDGP16IP",
                //        "transactTime": 1507725176595,
                //        "price": "0.00000000",
                //        "origQty": "10.00000000",
                //        "executedQty": "10.00000000",
                //        "status": "FILLED",
                //        "timeInForce": "GTC",
                //        "type": "MARKET",
                //        "side": "SELL",
                //        "fills": [
                //        {
                //        "price": "4000.00000000",
                //        "qty": "1.00000000",
                //        "commission": "4.00000000",
                //        "commissionAsset": "USDT"
                //        },
                //        {
                //        "price": "3999.00000000",
                //        "qty": "5.00000000",
                //        "commission": "19.99500000",
                //        "commissionAsset": "USDT"
                //        }]
                //    }
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

