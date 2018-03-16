//
//  MoonAlarmTableViewController.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/7/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import UIKit

class MoonAlarmTableViewController: UITableViewController {
    
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
        self.initPlayButton()
    
        //  IPAD //
        TradeSettings.instance.tradeStrategy.entranceCriteria = [
            StochRSIEnter(max: 85, noPriorCrossInLast: 0),
//            RSIEnter(max: 30, inLast: 5),
            RunFallRatioEnter(1.2),
//            SpareRunwayEnter(percent: 0.5),
            DelayBetweenTradesEnter(minutes: 5),
        ]

        TradeSettings.instance.tradeStrategy.exitCriteria = [
//            ProfitCutoffExit(percent: 1.0),
            StochRSIExit(max: 98),
            AndExit([MinRunwayExit(percent: 0.05), FallwayExit(percent: 0.2)]),
            LossExit(percent: 1.0),
        ]
    }

    /// Initialize test mode switch, set to current mode
    func initTestModeSwitch() {
        let isTestMode = TradeSettings.instance.testMode
        self.testModeSwitch.setOn(isTestMode, animated: true)
        self.testModeSwitch.tintColor = UIColor.red // Show the switch as red if out of test mode
    }
    
    @objc func tradeStartStopButtonPushed() {
        switch TradeSession.instance.status {
        case .running:
            TradeSession.instance.stop {
                self.initPlayButton()
            }
        case .stopped:
            TradeSession.instance.start {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(MoonAlarmTableViewController.tradeStartStopButtonPushed))
            }
        }
    }
    
    func initPlayButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(MoonAlarmTableViewController.tradeStartStopButtonPushed))
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var sender: Any
        switch indexPath.section {
        case 0: sender = self.openTrades[indexPath.row]
        default: sender = self.completedTrades[indexPath.row]
        }
        self.performSegue(withIdentifier: "showTradeSegue", sender: sender)
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
        
        cell.textLabel?.text = "\(trade.symbol): \(fillAmtString) \(trade.tradingPairSymbol)"
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
        
        let tradeSession = TradeSession.instance
        let tradeSettings = TradeSettings.instance
        
        // Reload table
        self.openTrades = tradeSession.trades.filterOnlyOpen()
        self.completedTrades = tradeSession.trades.filterOnlyComplete()
        self.tableView.reloadData()
        
        // Set Labels
        self.symbolsCountLabel.text = "Markets: \(tradeSession.marketsWatching.symbols.count)"
        if      tradeSession.status == .running,
                let marketLastUpdate = tradeSession.lastUpdateTime {
            let currentTime = Date.currentTimeInMS
            let secondsSinceLastUpdate = (currentTime - marketLastUpdate).msToSeconds
            let secondsSinceLastUpdateDisplay =
                String(format: "%.0f", arguments: [secondsSinceLastUpdate])
            self.lastUpdatedLabel.text = "Last Refresh: \(secondsSinceLastUpdateDisplay)"
        }
        
        // Account Balances
        let pairBalance = tradeSettings.tradingPairBalance.display8
        let pairSymbol = tradeSettings.tradingPairSymbol
        let pairCoinBalanceString = "\(pairBalance) \(pairSymbol)"
        self.pairCoinBalanceLabel.text = "\(pairCoinBalanceString)"
        let feeCoinBalance = tradeSettings.tradingFeeCoinBalance.display8
        let feeCoinSymbol = tradeSettings.tradingFeeCoinSymbol
        let feeCoinBalanceString =  feeCoinSymbol != nil ?
                                    "\(feeCoinBalance) \(feeCoinSymbol!)" :
                                    "N/A"
        self.feeCoinBalanceLabel.text = "\(feeCoinBalanceString)"
        
        // Trade Session Details
        self.completedTradesLabel.text =
            "Trades: \(TradeSession.instance.trades.countComplete())"
        self.successRateLabel.text =
            "Success: \(TradeSession.instance.trades.successRate)%"
        self.totalProfitPercentLabel.text =
            "Profit: \(TradeSession.instance.trades.totalProfitPercent)%"
        self.sessionTimeLabel.text =
            "Session: \(TradeSession.instance.duration.displayMsToHHMM)"
        let targetTradeAmount = TradeSettings.instance.tradeAmountTarget
        self.tradeAmountLabel.text = "Amount: \(targetTradeAmount) \(pairSymbol)"
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {        
        if (segue.identifier == "showTradeSegue") {
            guard   let destination = segue.destination as? TradeShowViewController,
                    let sender = sender as? Trade
                    else { return }
            
            destination.trade = sender
            destination.navTitle.title = sender.symbol.symbolPair
        }
    }
 

}











