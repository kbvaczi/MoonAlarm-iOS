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
            TradeSession.instance.stop {
//                self.stopRegularDisplayUpdates()
            }
        case .stopped:
            sender.setTitle("Stop Trading", for: .normal)
            TradeSession.instance.start {
//                self.startRegularDisplayUpdates()
            }
        }
    }
    
    @IBAction func testModeSwitchToggle(_ sender: UISwitch) {
        if sender.isOn {
            TradeSettings.instance.testMode = true
        } else {
            let switchAlert = UIAlertController(title: "Leaving Test Mode",
                                        message: "Are you sure you want to start live trading?",
                                        preferredStyle: UIAlertControllerStyle.alert)
            switchAlert.addAction(UIAlertAction(title: "No", style: .cancel,
                                                handler: { (action: UIAlertAction!) in
                self.testModeSwitch.setOn(true, animated: true) // Turn switch back
            }))
            switchAlert.addAction(UIAlertAction(title: "Yes", style: .destructive,
                                                handler: { (action: UIAlertAction!) in
                TradeSettings.instance.testMode = false
            }))
            present(switchAlert, animated: true, completion: nil)
        }
    }
    
    @IBOutlet weak var testModeSwitch: UISwitch!
    @IBOutlet weak var symbolsCountLabel: UILabel!
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    @IBOutlet weak var completedTradesLabel: UILabel!
    @IBOutlet weak var successRateLabel: UILabel!
    @IBOutlet weak var totalProfitPercentLabel: UILabel!
    @IBOutlet weak var sessionTimeLabel: UILabel!
    @IBOutlet weak var tradeAmountLabel: UILabel!
    @IBOutlet weak var pairCoinBalanceLabel: UILabel!
    @IBOutlet weak var feeCoinBalanceLabel: UILabel!
    
    var openTrades = Trades()
    var completedTrades = Trades()
    var updateTimer = Timer()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startRegularDisplayUpdates()
        self.initTestModeSwitch()
        
        //  MINI //
        TradeSettings.instance.tradeStrategy.entranceCriteria = [
            StochRSIEnter(max: 80, noPriorCrossInLast: 10),
            SpareRunwayEnter(percent: 1.0),
            DelayBetweenTradesEnter(delay: 10),
        ]

        TradeSettings.instance.tradeStrategy.exitCriteria = [
            ProfitCutoffExit(percent: 0.5),
            MinRunwayExit(percent: 0.1),
            LossExit(percent: 0.4),
        ]
    
        //  IPAD //
//        TradeSettings.instance.tradeStrategy.entranceCriteria = [
//            StochRSIEnter(max: 80, noPriorCrossInLast: 10),
//            SpareRunwayEnter(percent: 1.0),
//            DelayBetweenTradesEnter(delay: 10),
//        ]
//
//        TradeSettings.instance.tradeStrategy.exitCriteria = [
//            ProfitCutoffExit(percent: 0.8),
//            MinRunwayExit(percent: 0.1),
//            LossExit(percent: 0.4),
//        ]
    }

    /// Initialize test mode switch, set to current mode
    func initTestModeSwitch() {
        let isTestMode = TradeSettings.instance.testMode
        self.testModeSwitch.setOn(isTestMode, animated: true)
        self.testModeSwitch.tintColor = UIColor.red // Show the switch as red if out of test mode
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
        
        // set fill amount
        let fillAmount = trade.amountTradingPair
        let fillAmtString = fillAmount != nil ? fillAmount!.display3 : "?"
        
        // set enter price
        let enterPrice = trade.enterPrice
        let enterPriceString = enterPrice != nil ? enterPrice!.display8 : "?"
        
        // Set exit price
        let exitPrice = trade.exitPrice ?? trade.marketSnapshot.orderBook.firstAskPrice
        let exitPriceString = exitPrice != nil ? exitPrice!.display8 : "?"
        
        cell.textLabel?.text = "\(trade.symbol): \(fillAmtString) \(trade.tradingPairSymbol)  \(enterPriceString) -> \(exitPriceString)"
        if let profitPercent = trade.profitPercent {
            cell.detailTextLabel?.text = "\(profitPercent)%"
        }
    }
    
    private func startRegularDisplayUpdates() {
        self.updateTimer.invalidate() // Stop prior update timer
        self.updateTimer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                                selector: #selector(self.updateDisplay),
                                                userInfo: nil, repeats: true)
    }
    
    private func stopRegularDisplayUpdates() {
        self.updateTimer.invalidate()
    }
    
    @objc private func updateDisplay() {
        self.openTrades = TradeSession.instance.trades.filterOnlyOpen()
        self.completedTrades = TradeSession.instance.trades.filterOnlyComplete()
        self.tableView.reloadData()
        self.symbolsCountLabel.text = "Markets: \(TradeSession.instance.symbolsWatching.count)"
        if  let marketLastUpdate = TradeSession.instance.lastUpdateTime {
            let currentTime = Date.currentTimeInMS
            let secondsSinceLastUpdate = (currentTime - marketLastUpdate).msToSeconds
            let secondsSinceLastUpdateDisplay =
                                String(format: "%.0f", arguments: [secondsSinceLastUpdate])
            self.lastUpdatedLabel.text = "Last Refresh: \(secondsSinceLastUpdateDisplay)"
        }
        
        // Set Labels
        
        // Account Balances
        let pairBalance = TradeSettings.instance.tradingPairBalance.display8
        let pairSymbol = TradeSettings.instance.tradingPairSymbol
        let pairCoinBalanceString = "\(pairBalance) \(pairSymbol)"
        self.pairCoinBalanceLabel.text = "Pair Coin Balance: \(pairCoinBalanceString)"
        let feeCoinBalance = TradeSettings.instance.tradingFeeCoinBalance.display8
        let feeCoinSymbol = TradeSettings.instance.tradingFeeCoinSymbol
        let feeCoinBalanceString =  feeCoinSymbol != nil ?
                                    "\(feeCoinBalance) \(feeCoinSymbol!)" :
                                    "N/A"
        self.feeCoinBalanceLabel.text = "Fee Coin Balance: \(feeCoinBalanceString)"
        
        // Trade Session Details
        self.completedTradesLabel.text =
            "Trades Completed: \(TradeSession.instance.trades.countComplete())"
        self.successRateLabel.text =
            "Success Rate: \(TradeSession.instance.trades.successRate)%"
        self.totalProfitPercentLabel.text =
            "Total Profit: \(TradeSession.instance.trades.totalProfitPercent)%"
        self.sessionTimeLabel.text =
            "Session Time: \(TradeSession.instance.duration.displayMsToHHMM)"
        let targetTradeAmount = TradeSettings.instance.tradeAmountTarget
        self.tradeAmountLabel.text = "Target Trade Amount: \(targetTradeAmount) \(pairSymbol)"
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
