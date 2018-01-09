//
//  MoonAlarmTableViewController.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/7/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import UIKit

class MoonAlarmTableViewController: UITableViewController {

    var tradingPair = "BTC"
    var symbols = [String]()
    var marketSnapshots = MarketSnapshots()
    var updateTimer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSymbols {
            self.startUpdatingData()
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return marketSnapshots.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tradeDetailCell", for: indexPath)
        let snapshot = marketSnapshots[indexPath.row]
        
        cell.textLabel?.text = snapshot.symbol
        cell.detailTextLabel?.text = "$: \(snapshot.candleSticks.priceIsIncreasing)%  VR: \(snapshot.volumeRatio1To15M) #R:\(snapshot.tradesRatio1To15M)"

        return cell
    }
    
    private func updateSymbols(callback: @escaping () -> Void) {
        BinanceAPI.instance.getAllSymbols() { (isSuccess, newSymbols) in
            if isSuccess {
                self.symbols = newSymbols
                callback()
            }
        }
    }
    
    private func updateSymbolData(callback: @escaping () -> Void) {
        // remove outdated information
        self.marketSnapshots.removeAll()
        
        // use a dispatch group to keep track of how many symbols we've updated
        let dpG = DispatchGroup()
        
        for symbol in symbols {
            dpG.enter() // enter dispatch queue
            let newSnapshot = MarketSnapshot(symbol: symbol)
            let symbolPair = symbol + tradingPair

            BinanceAPI.instance.getKLineData(symbolPair: symbolPair, interval: .m1, limit: 15) {
                (isSuccess, cSticks) in
                if isSuccess {
                    newSnapshot.candleSticks = cSticks
                    if  newSnapshot.candleSticks.last!.pairVolume > 3 &&
                        newSnapshot.candleSticks.priceIsIncreasing {
                            self.marketSnapshots.append(newSnapshot)
                    }
                    
                }
                dpG.leave() // leave dispatch queue
            }
            
//            BinanceAPI.instance.getVolumeRatio(symbolPair: symbolPair, last: .m15, forPeriod: 4){
//                (isSuccess, volRatio, candlesticks) in
//                if isSuccess {
//                    newDetail.volumeRatio = volRatio
//                }
//                BinanceAPI.instance.getPriceRatio(symbolPair: symbolPair, last: .m1, forPeriod: 5) {
//                    (isSuccess, pRatio, candlesticks) in
//                    if isSuccess {
//                        newDetail.priceRatio = pRatio

//                    }
//                    let lastVolume = candlesticks.last!.volume
//                    let pairEquivalentVolume = lastVolume * candlesticks.last!.closePrice
//                    let toBeDisplayed = pRatio > 1 && volRatio >= 1 && pairEquivalentVolume > 3
//                    if toBeDisplayed {
//                        self.tradingDetails.append(newDetail)
//                    }
//                    dpG.leave()
//                }
//            }
        }
        
        // when all API calls are returned, run callback
        dpG.notify(queue: .main) {
            self.marketSnapshots = self.marketSnapshots.sorted(by: { $0.volumeRatio1To15M > $1.volumeRatio1To15M })
            callback()
        }
    }
    
    private func startUpdatingData() {
        self.stopUpdatingData()
        updateData()
        self.updateTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            self.updateData()
        }
    }
    
    private func stopUpdatingData() {
        self.updateTimer.invalidate()
    }
    
    private func updateData() {
        print("updating data")
        self.updateSymbolData {
            self.tableView.reloadData()
        }
    }
    
   
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
