//
//  ExchangeInfo.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/28/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

/// Used to keep track of lot sizes and valid prices for trades
class ExchangeInfo {
    
    /// Price & Amount info for different markets
    private var info: [SymbolPairInfo] = []
    
    //////////////////////////////////////////////
    ////////// ADDING AND UPDATING DATA //////////
    //////////////////////////////////////////////
    
    /// Populate exchange info with data from server
    ///
    /// - Parameter callback: do this after update
    func updateData(callback: @escaping (_ isSuccess: Bool) -> Void ) {
        BinanceAPI.instance.getExchangeInfo() { isSuccess, pairInfo in
            // Verify we received pairInfo
            guard let infos = pairInfo, infos.count > 0 else { callback(false); return }
            
            for info in infos {
                self.addInfo(info)
            }
            
            callback(true)
        }
    }
    
    /// Add symbol pair info to exchange information
    ///
    /// - Parameter info: info to add, overwrites existing if present
    func addInfo(_ info: SymbolPairInfo) {
        if let existingIndex = self.info.index(where: {$0.symbolPair == info.symbolPair}) {
            self.info[existingIndex] = info
        } else {
            self.info.append(info)
        }
    }
    
    /////////////////////////////////////
    ////////// RETRIEVING DATA //////////
    /////////////////////////////////////
    
    /// Returns an array of symbols available to trade with given trading pair
    ///
    /// - Parameter tradingPair: symbol for trading pair coin (ex. "BTC")
    /// - Returns: array of symbols available to trade with pair
    func symbolsForPair(_ tradingPairSymbol: String) -> [Symbol] {
        let symbolPairs = self.info.filter({ $0.symbolPair.hasSuffix(tradingPairSymbol) })
        let symbols = symbolPairs.map({$0.symbolPair.replacingOccurrences(
            of: tradingPairSymbol, with: "") })
        return symbols
    }
    
    /// Returns the nearest allowable trade amount within lot size restrictions
    ///
    /// - Parameters:
    ///   - amount: planned amount
    ///   - symbolPair: for this symbol pair
    /// - Returns: nearest allowable trade amount
    func nearestValidAmount(to amount: Double, for symbolPair: SymbolPair) -> Double? {
        guard let symbolInfo = self.info.first(where: {$0.symbolPair == symbolPair}) else {
            return nil
        }
        
        return symbolInfo.lotSize.nearestAllowableAmount(to: amount).roundTo(8)
    }
    
    
    /// Returns the minimum increment exchange allows for setting amount ordered
    ///
    /// - Parameter symbolPair: for this symbol pair
    /// - Returns: minimum amount tick allowable for this market
    func amountTick(for symbolPair: SymbolPair) -> Double? {
        guard let symbolInfo = self.info.first(where: {$0.symbolPair == symbolPair}) else {
            return nil
        }
        
        return symbolInfo.lotSize.stepSize
    }
    
    /// Returns the nearest allowable trade amount within lot size restrictions
    ///
    /// - Parameters:
    ///   - amount: planned amount
    ///   - symbolPair: for this symbol pair
    /// - Returns: nearest allowable trade amount
    func nearestValidPrice(to price: Price, for symbolPair: SymbolPair) -> Double? {
        guard let symbolInfo = self.info.first(where: {$0.symbolPair == symbolPair}) else {
            return nil
        }
        
        return symbolInfo.priceFilter.nearestAllowablePrice(to: price).roundTo(8)
    }
    
    /// Returns the minimum increment exchange allows for setting price
    ///
    /// - Parameter symbolPair: for this symbol pair
    /// - Returns: minimum price tick allowable for this market
    func priceTick(for symbolPair: SymbolPair) -> Price? {
        guard let symbolInfo = self.info.first(where: {$0.symbolPair == symbolPair}) else {
            return nil
        }
        
        return symbolInfo.priceFilter.tickSize
    }
    
    /// Returns minimum value (price * amount) allowed for buy/sell
    ///
    /// - Parameter symbolPair: for this market
    /// - Returns: minimum value ("min notional")
    func minNotionalValue(for symbolPair: SymbolPair) -> Double? {
        guard let symbolInfo = self.info.first(where: {$0.symbolPair == symbolPair}) else {
            return nil
        }
        
        return symbolInfo.minNotionalValue
    }
    
    ////////// DATA STRUCTURES //////////
    
    /// Describes information for a symbol pair
    struct SymbolPairInfo {
        let symbolPair: SymbolPair
        let lotSize: LotSize
        let priceFilter: PriceFilter
        let minNotionalValue: Double
        
        init(_ symbolPair: SymbolPair, lotSize: LotSize, priceFilter: PriceFilter,
             minNotional: Double) {
            self.symbolPair = symbolPair
            self.lotSize = lotSize
            self.priceFilter = priceFilter
            self.minNotionalValue = minNotional
        }
    }
    
    /// Describes lot size information for a symbol pair
    struct LotSize {
        let minQty: Double
        let maxQty: Double
        let stepSize: Double
        
        init(minQty: Double, maxQty: Double, stepSize: Double) {
            self.minQty = minQty
            self.maxQty = maxQty
            self.stepSize = stepSize
        }
        
        func nearestAllowableAmount(to amount: Double) -> Double {
            var nearestAllowableSize = trunc(amount / self.stepSize) * self.stepSize
            if nearestAllowableSize < self.minQty { nearestAllowableSize = self.minQty }
            if nearestAllowableSize > self.maxQty { nearestAllowableSize = self.maxQty }
            return nearestAllowableSize
        }
    }
    
    /// Describes price filter information for a symbol pair
    struct PriceFilter {
        let minPrice: Price
        let maxPrice: Price
        let tickSize: Price
        
        init(minPrice: Price, maxPrice: Price, tickSize: Price) {
            self.minPrice = minPrice
            self.maxPrice = maxPrice
            self.tickSize = tickSize
        }
        
        func nearestAllowablePrice(to price: Price) -> Price {
            var nearestAllowablePrice = trunc(price / self.tickSize) * self.tickSize
            if nearestAllowablePrice < self.minPrice { nearestAllowablePrice = self.minPrice }
            if nearestAllowablePrice > self.maxPrice { nearestAllowablePrice = self.maxPrice }
            return nearestAllowablePrice
        }
    }
    
}
