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
        
        TradeSession.instance.updateSymbols {
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
        return TradeSession.instance.marketSnapshots.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tradeDetailCell", for: indexPath)
        let snapshot = TradeSession.instance.marketSnapshots[indexPath.row]
        
        cell.textLabel?.text = snapshot.symbol
        cell.detailTextLabel?.text = "$: \(snapshot.candleSticks.priceIsIncreasing)%  VR: \(snapshot.volumeRatio1To15M) #R:\(snapshot.tradesRatio1To15M)"

        return cell
    }
    
    private func startUpdatingData() {
        self.stopUpdatingData()
        updateData()
        TradeSession.instance.updateTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            self.updateData()
        }
    }
    
    private func stopUpdatingData() {
        TradeSession.instance.updateTimer.invalidate()
    }
    
    private func updateData() {        
        TradeSession.instance.updateMarketSnapshots {
            self.tableView.reloadData()
            TradeSession.instance.investInWinners()
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
