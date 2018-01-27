//
//  MoonAlarmTableViewController.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/7/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import UIKit

class MoonAlarmTableViewController: UITableViewController {

    @IBAction func startStopButtonPushed(_ sender: UIButton) {
        switch TradeSession.instance.status {
        case .running:
            sender.setTitle("Start Trading", for: .normal)
            TradeSession.instance.stop { }
        case .stopped:
            sender.setTitle("Stop Trading", for: .normal)
            TradeSession.instance.start { }
        }
    }
    
    @IBOutlet weak var symbolsCountLabel: UILabel!
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    @IBOutlet weak var completedTradesLabel: UILabel!
    @IBOutlet weak var successRateLabel: UILabel!
    @IBOutlet weak var totalProfitPercentLabel: UILabel!
    @IBOutlet weak var sessionTimeLabel: UILabel!
    @IBOutlet weak var tradeAmountLabel: UILabel!
    
    var openTrades = Trades()
    var completedTrades = Trades()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startRegularDisplayUpdates()
        
        TradeStrategy.instance.entranceCriteria = [
//            RSIEnter(max: 40, inLast: 1),
            SpareRunwayEnter(percent: 1.5),
//            FallwaySupportEnter(percent: 0.4),
        ]
        
        TradeStrategy.instance.exitCriteria = [
            LossExit(percent: 2.0),
            TrailingLossExit(percent: 1.0, after: 3.0),
            RSIExit(max: 65),
            MinRunwayExit(percent: 0.2),
            AndExit([LossExit(percent: 1.0), FallwayExit(percent: 0.5)])
        ]
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Open Trades"
        case 1: return "Completed Trades"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return self.openTrades.count
        case 1: return self.completedTrades.count
        default: return 0
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tradeDetailCell", for: indexPath)
        switch indexPath.section {
        case 0:
            let currentTrade = openTrades[indexPath.row]
            self.buildCell(cell, from: currentTrade)
        case 1:
            let currentTrade = completedTrades[indexPath.row]
            self.buildCell(cell, from: currentTrade)
        default: break
        }
        return cell
    }
    
    func buildCell(_ cell: UITableViewCell, from trade: Trade) {
        // set enter price
        var entPriceString = ""
        if let enterPrice = trade.enterPrice {
            entPriceString = enterPrice.toDisplay
        } else {
            entPriceString = "?"
        }
        
        // Set exit price
        var exitPriceString = ""
        if let exitPrice = trade.exitPrice {
            exitPriceString = exitPrice.toDisplay
        } else {
            let pairVolume = TradeStrategy.instance.tradeAmountTarget
            if let marketExitPrice = trade.marketSnapshot.orderBook.marketSellPrice(forPairVolume: pairVolume) {
                exitPriceString = marketExitPrice.toDisplay
            } else {
                exitPriceString = "?"
            }
        }
        cell.textLabel?.text = "\(trade.symbol) \(entPriceString) -> \(exitPriceString)"
        if let profitPercent = trade.profitPercent {
            cell.detailTextLabel?.text = "\(profitPercent)%"
        }
    }
    
    private func startRegularDisplayUpdates() {
        let _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){ _ in
            self.updateDisplay()
        }
    }
    
    private func updateDisplay() {
        self.openTrades = TradeSession.instance.trades.selectOnly(status: .open)
        self.completedTrades = TradeSession.instance.trades.selectOnly(status: .complete)
        self.tableView.reloadData()
        self.symbolsCountLabel.text = "Markets: \(TradeSession.instance.symbols.count)"
        if  let marketLastUpdate = TradeSession.instance.lastUpdateTime {
            let currentTime = ExchangeClock.instance.currentTime
            let secondsSinceLastUpdate = (currentTime - marketLastUpdate).msToSeconds
            let secondsSinceLastUpdateDisplay = String(format: "%.0f", arguments: [secondsSinceLastUpdate])
            self.lastUpdatedLabel.text = "Last Refresh: \(secondsSinceLastUpdateDisplay)"
        }
        self.completedTradesLabel.text = "Complete Trades: \(TradeSession.instance.trades.countOnly(status: .complete))"
        self.successRateLabel.text = "Success Rate: \(TradeSession.instance.trades.successRate)%"
        self.totalProfitPercentLabel.text = "Total Profit: \(TradeSession.instance.trades.totalProfitPercent)%"
        self.sessionTimeLabel.text = "Session Time: \(TradeSession.instance.duration.displayMsToHHMM)"
        self.tradeAmountLabel.text = "Trade Amount: \(TradeStrategy.instance.tradeAmountTarget) \(TradeStrategy.instance.tradingPairSymbol)"
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
