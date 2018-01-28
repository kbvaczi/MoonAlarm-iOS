//
//  BinanceExtensions.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/28/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation
import SwiftyJSON


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
        
        self.init(openTime: (json[0].int64Value as Milliseconds),
                  closeTime: (json[6].int64Value as Milliseconds),
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

extension ExchangeInfo.SymbolPairInfo {
    
    /// Initialize from JSON
    ///
    /// - Parameter json: json to build symbolpairinfo from
    init(fromJson json: JSON) {
        
        var priceFilterJson: JSON = JSON.null
        var lotSizeJson: JSON = JSON.null
        
        for (_ ,filterInfoJson):(String, JSON) in json["filters"] {
            if filterInfoJson["filterType"].stringValue == "PRICE_FILTER" {
                priceFilterJson = filterInfoJson
            }
            if filterInfoJson["filterType"].stringValue == "LOT_SIZE" {
                lotSizeJson = filterInfoJson
            }
        }
        
        self.symbolPair = json["symbol"].stringValue
        self.priceFilter = ExchangeInfo.PriceFilter(fromJson: priceFilterJson)
        self.lotSize = ExchangeInfo.LotSize(fromJson: lotSizeJson)
    }
    
            // Example Data:
            //{
            //    "symbol": "ETHBTC",
            //    "status": "TRADING",
            //    "baseAsset": "ETH",
            //    "baseAssetPrecision": 8,
            //    "quoteAsset": "BTC",
            //    "quotePrecision": 8,
            //    "orderTypes": ["LIMIT", "MARKET"],
            //    "icebergAllowed": false,
            //    "filters": [{
            //        "filterType": "PRICE_FILTER",
            //        "minPrice": "0.00000100",
            //        "maxPrice": "100000.00000000",
            //        "tickSize": "0.00000100"
            //        }, {
            //        "filterType": "LOT_SIZE",
            //        "minQty": "0.00100000",
            //        "maxQty": "100000.00000000",
            //        "stepSize": "0.00100000"
            //        }, {
            //        "filterType": "MIN_NOTIONAL",
            //        "minNotional": "0.00100000"
            //    }]
            //}
    
}

extension ExchangeInfo.LotSize {
    
    init(fromJson json: JSON) {
        self.minQty = json["minQty"].doubleValue
        self.maxQty = json["maxQty"].doubleValue
        self.stepSize = json["stepSize"].doubleValue
    }
    
            //    {
            //        "filterType": "LOT_SIZE",
            //        "minQty": "0.00100000",
            //        "maxQty": "100000.00000000",
            //        "stepSize": "0.00100000"
            //    }
}

extension ExchangeInfo.PriceFilter {
    
    init(fromJson json: JSON) {
        self.minPrice = json["minPrice"].doubleValue
        self.maxPrice = json["maxPrice"].doubleValue
        self.tickSize = json["tickSize"].doubleValue
    }
    
            //    {
            //        "filterType": "PRICE_FILTER",
            //        "minPrice": "0.00000100",
            //        "maxPrice": "100000.00000000",
            //        "tickSize": "0.00000100"
            //    }
}





















