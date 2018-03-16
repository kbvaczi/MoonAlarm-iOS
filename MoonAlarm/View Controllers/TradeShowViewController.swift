//
//  TradeShowViewController.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 3/10/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import UIKit
import Charts

class TradeShowViewController: UIViewController, ChartViewDelegate {

    var trade: Trade? = nil
    var updateTimer = Timer()
    
    @IBOutlet weak var navTitle: UINavigationItem!
    
    @IBOutlet weak var candleStickChartView: CandleStickChartView!
    @IBOutlet weak var lineChart1View: LineChartView!
    @IBOutlet weak var lineChart2View: LineChartView!
    
    @IBOutlet weak var entryPriceLabel: UILabel!
    @IBOutlet weak var exitPriceLabel: UILabel!
    @IBOutlet weak var profitLabel: UILabel!
    @IBOutlet weak var tradeAmountLabel: UILabel!
    @IBOutlet weak var tradeStatusLabel: UILabel!
    
    @IBAction func exitTradeButtonPushed(_ sender: UIButton) {
        guard   let trade = self.trade,
                trade.status.isOpen,
                trade.status != .exiting else {
                sender.setTitle("Trade Already Exited", for: .normal)
                return
        }
        sender.setTitle("Trade Exiting", for: .normal)
        trade.exit()
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initCandleStickChart()
        initStochRSIChart()
//        initRSIChart()
        initOrderBookChart(chartView: lineChart2View)
        regularUpdate()
        startRegularUpdates()
    }
    
    func initCandleStickChart() {
        self.candleStickChartView.delegate = self
        
        self.candleStickChartView.chartDescription?.enabled = false
        self.candleStickChartView.backgroundColor = UIColor.groupTableViewBackground
        
        self.candleStickChartView.dragEnabled = false
        self.candleStickChartView.setScaleEnabled(false)
        self.candleStickChartView.maxVisibleCount = 30
        self.candleStickChartView.pinchZoomEnabled = false
        
        self.candleStickChartView.legend.horizontalAlignment = .right
        self.candleStickChartView.legend.verticalAlignment = .top
        self.candleStickChartView.legend.orientation = .horizontal
        self.candleStickChartView.legend.drawInside = true
    
        self.candleStickChartView.leftAxis.labelPosition = .insideChart
        
        self.candleStickChartView.rightAxis.enabled = false
        
        self.candleStickChartView.xAxis.labelPosition = .bottom
        self.candleStickChartView.xAxis.labelFont = UIFont(name: "HelveticaNeue-Light", size: 0)!
    }
    
    func updateCandleStickChart() {
        /// Verify we have market data
        guard let mSS = self.trade?.marketSnapshot else { return }
        
        let yVals1 = mSS.candleSticks.suffix(30).enumerated().map {
            (index, stick) -> CandleChartDataEntry in
            let high = stick.highPrice
            let low = stick.lowPrice
            let open = stick.openPrice
            let close = stick.closePrice
            
            return CandleChartDataEntry(x: Double(index), shadowH: high, shadowL: low,
                                        open: open, close: close)
        }
        
        let set1 = CandleChartDataSet(values: yVals1, label: "Price")
        set1.axisDependency = .left
        set1.setColor(UIColor(white: 80/255, alpha: 1))
        set1.drawIconsEnabled = false
        set1.shadowColor = .darkGray
        set1.shadowWidth = 0.7
        set1.decreasingColor = .red
        set1.decreasingFilled = true
        set1.increasingColor = UIColor(red: 122/255, green: 242/255, blue: 84/255, alpha: 1)
        set1.increasingFilled = true
        set1.neutralColor = .blue
        
        let data = CandleChartData(dataSet: set1)
        self.candleStickChartView.data = data
    }
    
    func initStochRSIChart() {
        initLineChart(chartView: lineChart1View, min: 0, max: 100, lowLimit: 20, highLimit: 80)
    }
    
    func initRSIChart() {
        initLineChart(chartView: lineChart2View, min: 0, max: 100, lowLimit: 30, highLimit: 70)
    }
    
    func initLineChart(chartView: LineChartView,
                       min: Double, max: Double, lowLimit: Double, highLimit: Double) {
        
        chartView.delegate = self
        
        chartView.chartDescription?.enabled = false
        chartView.dragEnabled = false
        chartView.setScaleEnabled(false)
        chartView.pinchZoomEnabled = false
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.labelFont = UIFont(name: "HelveticaNeue-Light", size: 0)!
        chartView.xAxis.spaceMin = 0.5
        chartView.xAxis.spaceMax = 0.5
        
        chartView.backgroundColor = UIColor.groupTableViewBackground
        
        chartView.rightAxis.enabled = false
        
        chartView.legend.drawInside = true
        chartView.legend.horizontalAlignment = .right
        chartView.legend.verticalAlignment = .top
        chartView.legend.orientation = .horizontal
        
        let ll1 = ChartLimitLine(limit: highLimit, label: "")
        ll1.lineWidth = 2
        ll1.lineDashLengths = [5, 5]
        
        let ll2 = ChartLimitLine(limit: lowLimit, label: "")
        ll2.lineWidth = 2
        ll2.lineDashLengths = [5, 5]
        
        let leftAxis = chartView.leftAxis
        leftAxis.removeAllLimitLines()
        leftAxis.addLimitLine(ll1)
        leftAxis.addLimitLine(ll2)
        leftAxis.axisMaximum = max
        leftAxis.axisMinimum = min
        leftAxis.labelPosition = .insideChart
        leftAxis.gridLineDashLengths = [5, 5]
        leftAxis.drawLimitLinesBehindDataEnabled = true
    }
    
    func initOrderBookChart(chartView: LineChartView) {
        chartView.delegate = self
        
        chartView.chartDescription?.enabled = false
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
        chartView.pinchZoomEnabled = true
        chartView.xAxis.labelPosition = .bottom
        chartView.backgroundColor = UIColor.groupTableViewBackground
        chartView.rightAxis.enabled = false
        
        chartView.legend.drawInside = true
        chartView.legend.horizontalAlignment = .right
        chartView.legend.verticalAlignment = .top
        chartView.legend.orientation = .horizontal
        
        let leftAxis = chartView.leftAxis
        leftAxis.labelPosition = .insideChart
        leftAxis.gridLineDashLengths = [5, 5]
    }
    
    func updateOrderBookChart(chartView: LineChartView) {
        /// Verify we have market data
        guard let mSS = self.trade?.marketSnapshot else { return }
        
        let orderBook = mSS.orderBook
        
        let bids = orderBook.bids
        let bidsReversed = bids.reversed()
        let bidVals = bidsReversed.enumerated().map { (index, bid) -> ChartDataEntry in
            let price = bid.price
            let cumAmount = bids.prefix(bids.count - index - 1).map({$0.quantity}).reduce(0, +)
            return ChartDataEntry(x: price, y: cumAmount)
        }
        
        let askVals = orderBook.asks.enumerated().map { (index, ask) -> ChartDataEntry in
            let price = ask.price
            let cumAmount = orderBook.asks.prefix(index).map({$0.quantity}).reduce(0, +)
            return ChartDataEntry(x: price, y: cumAmount)
        }
        
        let bidsSet = LineChartDataSet(values: bidVals, label: "Bids")
        let asksSet = LineChartDataSet(values: askVals, label: "Asks")
        let sets = [bidsSet, asksSet]
        
        for set in sets {
            set.drawIconsEnabled = false
            set.setCircleColor(.clear)
            set.lineWidth = 2
            set.circleRadius = 0
            set.drawCircleHoleEnabled = false
            set.valueFont = .systemFont(ofSize: 0)
            set.formLineDashLengths = [5, 2.5]
            set.formLineWidth = 1
            set.formSize = 15
            set.drawFilledEnabled = true
            set.fillAlpha = 0.6
        }
        
        bidsSet.fillColor = .green
        bidsSet.setColor(.green)
        asksSet.fillColor = .red
        asksSet.setColor(.red)
        
        let data = LineChartData(dataSets: sets)
        
        chartView.data = data
    }
    
    func updateStochRSIChart() {
        /// Verify we have market data
        guard let mSS = self.trade?.marketSnapshot else { return }
        
        let kVals = mSS.candleSticks.suffix(30).enumerated().map {
            (index, stick) -> ChartDataEntry in
            let val = stick.stochRSIK
            return ChartDataEntry(x: Double(index), y: val ?? 0)
        }
        
        let dVals = mSS.candleSticks.suffix(30).enumerated().map {
            (index, stick) -> ChartDataEntry in
            let val = stick.stochRSID
            return ChartDataEntry(x: Double(index), y: val ?? 0)
        }
        
        let set1 = LineChartDataSet(values: kVals, label: "Stoch RSI K")
        set1.drawIconsEnabled = false
        set1.setColor(.blue)
        set1.setCircleColor(.clear)
        set1.lineWidth = 2
        set1.circleRadius = 0
        set1.drawCircleHoleEnabled = false
        set1.valueFont = .systemFont(ofSize: 0)
        set1.formLineDashLengths = [5, 2.5]
        set1.formLineWidth = 1
        set1.formSize = 15
        set1.drawFilledEnabled = false
        
        let set2 = LineChartDataSet(values: dVals, label: "Stoch RSI D")
        set2.drawIconsEnabled = false
        set2.setColor(.yellow)
        set2.setCircleColor(.clear)
        set2.lineWidth = 2
        set2.circleRadius = 0
        set2.drawCircleHoleEnabled = false
        set2.valueFont = .systemFont(ofSize: 0)
        set2.formLineDashLengths = [5, 2.5]
        set2.formLineWidth = 1
        set2.formSize = 15
        set2.drawFilledEnabled = false
        
        let data = LineChartData(dataSets: [set1, set2])
        
        lineChart1View.data = data
    }
    
    func updateRSIChart() {
        /// Verify we have market data
        guard let mSS = self.trade?.marketSnapshot else { return }
        
        let vals = mSS.candleSticks.suffix(30).enumerated().map {
            (index, stick) -> ChartDataEntry in
            let val = stick.rsi
            return ChartDataEntry(x: Double(index), y: val ?? 0)
        }
        
        let set1 = LineChartDataSet(values: vals, label: "RSI")
        set1.drawIconsEnabled = false
        set1.setColor(.blue)
        set1.setCircleColor(.clear)
        set1.lineWidth = 2
        set1.circleRadius = 0
        set1.drawCircleHoleEnabled = false
        set1.valueFont = .systemFont(ofSize: 0)
        set1.formLineDashLengths = [5, 2.5]
        set1.formLineWidth = 1
        set1.formSize = 15
        set1.drawFilledEnabled = false
        
        let data = LineChartData(dataSet: set1)
        
        lineChart2View.data = data
    }
    
    func startRegularUpdates() {
        self.updateTimer.invalidate()
        self.updateTimer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                                selector: #selector(self.regularUpdate),
                                                userInfo: nil, repeats: true)
    }
    
    @objc func regularUpdate() {
        updateCandleStickChart()
        updateStochRSIChart()
//        updateRSIChart()
        updateOrderBookChart(chartView: lineChart2View)
        
        guard let currentTrade = self.trade else { return }
        
        // set enter price
        let enterPrice = currentTrade.enterPrice
        let enterPriceString = enterPrice != nil ? enterPrice!.display8 : "?"
        
        // Set exit price
        let exitPrice = currentTrade.exitPrice ?? currentTrade.marketSnapshot.orderBook.topBidPrice
        let exitPriceString = exitPrice != nil ? exitPrice!.display8 : "?"
        
        self.entryPriceLabel.text = "Enter Price: \(enterPriceString)"
        self.exitPriceLabel.text = "Exit Price:   \(exitPriceString)"
        if let profitPercent = currentTrade.profitPercent {
            self.profitLabel.text = "Profit: \(profitPercent)%"
        }
        
        // Amount Trading
        let fillAmount = currentTrade.amountTradingPair
        let fillAmtString = fillAmount != nil ? fillAmount!.display3 : "?"
        self.tradeAmountLabel.text = "Amount: \(fillAmtString) \(currentTrade.tradingPairSymbol)"
        
        // Trade Status
        self.tradeStatusLabel.text = "Status: \(currentTrade.status.rawValue)"
    }
    
    func stopRegularUpdates() {
        self.updateTimer.invalidate()
    }

}
