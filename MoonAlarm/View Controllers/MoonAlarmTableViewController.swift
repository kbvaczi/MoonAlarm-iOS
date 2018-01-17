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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startRegularDisplayUpdates()
        
//        let srC = SpareRunwayCriterion(minRunwayPercent: 1.0)
//        let fsC = FallwaySupportCriterion(maxFallwayPercent: 1.0)
        let mvC = MinVolumeCriterion(minVolume: 5 * TradeStrategy.instance.tradeAmountTarget)
        let macdC = MACDEnterCriterion()
        let vrC = IncreaseVolumeCriterion(minVolRatio: 0.5)
            
        TradeStrategy.instance.entranceCriteria = [macdC, mvC, vrC]
        TradeStrategy.instance.exitCriteria = [TimeLimitProfitableCriterion(timeLimit: 20.minutesToMilliseconds),
                                               TimeLimitUnprofitableCriterion(timeLimit: 30.minutesToMilliseconds),
                                               LossPercentCriterion(percent: 2.0),
                                               MACDExitCriterion()]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Summary"
        case 1: return "Open Trades"
        case 2: return "Completed Trades"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3
        case 1: return TradeSession.instance.trades.countOnly(status: .open)
        case 2: return TradeSession.instance.trades.countOnly(status: .complete)
        default: return 0
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "tradeDetailCell", for: indexPath)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Total Trades:"
                cell.detailTextLabel?.text = "\(TradeSession.instance.trades.countOnly(status: .complete))"
            case 1:
                cell.textLabel?.text = "Success Rate:"
                cell.detailTextLabel?.text = "\(TradeSession.instance.trades.successRate)%"
            case 2:
                cell.textLabel?.text = "Total Profit:"
                cell.detailTextLabel?.text = "\(TradeSession.instance.trades.totalProfitPercent)%"
            default: return cell
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "tradeDetailCell", for: indexPath)
            let trades = TradeSession.instance.trades.selectOnly(status: .open)
            cell.textLabel?.text = trades[indexPath.row].symbol
            if let profitPercent = trades[indexPath.row].profitPercent {
                cell.detailTextLabel?.text = "\(profitPercent)%"
            }
            return cell
        case 2:
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
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){ _ in
            self.updateDisplay()
        }
    }
    
    private func updateDisplay() {
        self.tableView.reloadData()
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
