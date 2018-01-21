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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startRegularDisplayUpdates()
        
        TradeStrategy.instance.entranceCriteria = [
            MACDEnterCriterion(incTrendFor: 2, requireCross: false, inLast: 1),
            RSIEnterCriterion(max: 35, inLast: 5),
//            SpareRunwayCriterion(minRunwayPercent: 1.0),
//            IncreaseVolumeCriterion(minVolRatio: 2.0),
//            BidAskGapCriterion(maxGapPercent: 0.5),
//            MarketyBuyLossCriterion(maxLossPercent: 0.5)
        ]
        TradeStrategy.instance.exitCriteria = [
//            TimeLimitProfitableCriterion(timeLimit: 60.minutesToMilliseconds),
//            TimeLimitUnprofitableCriterion(timeLimit: 30.minutesToMilliseconds),
            LossPercentCriterion(percent: 3.0),
//            ProfitCutoffCriterion(profitPercent: 5.0),
            TrailingLossPercentCriterion(loss: 1.0, after: 2.0),
            RSIExitCriterion(max: 60),
//            MACDExitCriterion()
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
        case 0: return TradeSession.instance.trades.countOnly(status: .open)
        case 1: return TradeSession.instance.trades.countOnly(status: .complete)
        default: return 0
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "tradeDetailCell", for: indexPath)
            let trades = TradeSession.instance.trades.selectOnly(status: .open)
            let currentTrade = trades[indexPath.row]
            let entPriceString =    (currentTrade.enterPrice != nil) ?
                                    String(format: "%0.5f", arguments: [currentTrade.enterPrice!]) : "?"
            let exitPriceString =   (currentTrade.exitPrice != nil) ?
                                    String(format: "%0.5f", arguments: [currentTrade.exitPrice!]) : "?"
            cell.textLabel?.text = "\(currentTrade.symbol) \(entPriceString) -> \(exitPriceString)"
            if let profitPercent = trades[indexPath.row].profitPercent {
                cell.detailTextLabel?.text = "\(profitPercent)%"
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "tradeDetailCell", for: indexPath)
            let trades = TradeSession.instance.trades.selectOnly(status: .complete)
            let currentTrade = trades[indexPath.row]
            let entPriceString =    (currentTrade.enterPrice != nil) ?
                                    String(format: "%0.5f", arguments: [currentTrade.enterPrice!]) : "?"
            let pairVolume = TradeStrategy.instance.tradeAmountTarget
            let marketExitPrice = currentTrade.marketSnapshot.orderBook.marketSellPrice(forPairVolume: pairVolume)
            let exitPriceString =   (currentTrade.exitPrice != nil) ?
                                        String(format: "%0.5f", arguments: [currentTrade.exitPrice!]) :
                                        (marketExitPrice != nil) ?
                                            String(format: "%0.5f", arguments: [marketExitPrice!]) :
                                            "?"
            cell.textLabel?.text = "\(currentTrade.symbol) \(entPriceString) -> \(exitPriceString)"
            if let profitPercent = trades[indexPath.row].profitPercent {
                cell.detailTextLabel?.text = "\(profitPercent)%"
            }
            return cell
        default: return UITableViewCell()
        }
    }
    
    private func startRegularDisplayUpdates() {
        let _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){ _ in
            self.updateDisplay()
        }
    }
    
    private func updateDisplay() {
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
