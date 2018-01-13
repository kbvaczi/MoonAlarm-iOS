//
//  MoonAlarmTableViewController.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/7/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import UIKit

class MoonAlarmTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let ivC = IncreaseVolumeCriterion(minVolRatio: 2.0)
        let srC = SpareRunwayCriterion(minRunwayPercent: 1.0)
        let fsC = FallwaySupportCriterion(maxFallwayPercent: 0.5)
        let mvC = MinVolumeCriterion(minVolume: 10 * TradeSession.instance.tradeAmountTarget)
        
        TradeStrategy.instance.entranceCriteria = [ivC, srC, mvC, fsC]
        TradeSession.instance.start {
            self.updateDisplay()
            TradeSession.instance.investInWinners()
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
        return TradeSession.instance.marketSnapshots.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tradeDetailCell", for: indexPath)
        let snapshot = TradeSession.instance.marketSnapshots[indexPath.row]
        
        cell.textLabel?.text = snapshot.symbol
        
        guard   let currentVol = snapshot.candleSticks.currentStickVolume,
                let currentPrice = snapshot.currentPrice else { return cell }
        
        guard   let runwayPrice = snapshot.orderBook.runwayPrice(forVolume: currentVol),
                let fallwayPrice = snapshot.orderBook.fallwayPrice(forVolume: currentVol)
                else { return cell }
        
        let runwayPercent = (runwayPrice / currentPrice - 1).toPercent()
        let fallwayPercent = (currentPrice / fallwayPrice - 1).toPercent()
        
        cell.detailTextLabel?.text = "Run:\(runwayPercent)%  Fall:\(fallwayPercent)% VRat:\(snapshot.volumeRatio1To15M!) tRat:\(snapshot.tradesRatio1To15M!)"

        return cell
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
