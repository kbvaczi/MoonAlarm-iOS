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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startRegularDisplayUpdates()
        
        let srC = SpareRunwayCriterion(minRunwayPercent: 1.0)
        let fsC = FallwaySupportCriterion(maxFallwayPercent: 1.0)
        let mvC = MinVolumeCriterion(minVolume: 10 * TradeStrategy.instance.tradeAmountTarget)
        let mgC = BidAskGapCriterion()
        let macdC = MACDEnterCriterion()
        let vrC = IncreaseVolumeCriterion(minVolRatio: 0.5)
            
        TradeStrategy.instance.entranceCriteria = [macdC, srC, fsC]
        TradeStrategy.instance.exitCriteria = [TimeLimitProfitableCriterion(timeLimit: 30.minutesToMilliseconds),
                                               TimeLimitUnprofitableCriterion(timeLimit: 60.minutesToMilliseconds),
                                               LossPercentCriterion(percent: 5.0),
                                               MACDExitCriterion()]
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
            cell.textLabel?.text = trades[indexPath.row].symbol
            if let profitPercent = trades[indexPath.row].profitPercent {
                cell.detailTextLabel?.text = "\(profitPercent)%"
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "tradeDetailCell", for: indexPath)
            let trades = TradeSession.instance.trades.selectOnly(status: .complete)
            cell.textLabel?.text = trades[indexPath.row].symbol
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
        self.symbolsCountLabel.text = "Markets Monitoring: \(TradeSession.instance.symbols.count)"
        if  let marketLastUpdate = TradeSession.instance.lastUpdateTime {
            let currentTime = ExchangeClock.instance.currentTime
            let secondsSinceLastUpdate = (currentTime - marketLastUpdate).msToSeconds
            let secondsSinceLastUpdateDisplay = String(format: "%.0f", arguments: [secondsSinceLastUpdate])
            self.lastUpdatedLabel.text = "Last Updated: \(secondsSinceLastUpdateDisplay)s ago"
        }
        self.completedTradesLabel.text = "Completed Trades: \(TradeSession.instance.trades.countOnly(status: .complete))"
        self.successRateLabel.text = "Success Rate: \(TradeSession.instance.trades.successRate)%"
        self.totalProfitPercentLabel.text = "Total Profit: \(TradeSession.instance.trades.totalProfitPercent)%"
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
