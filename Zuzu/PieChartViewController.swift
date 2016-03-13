//
//  BarChartViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import Charts

class PieChartViewController: UIViewController {

    @IBOutlet var pieChartView: PieChartView!
    var months: [String]!
    
    func setChart(dataPoints: [String], values: [Double]) {

        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(value: values[i], xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        let pieChartDataSet = PieChartDataSet(yVals: dataEntries, label: "服務狀態")
        let pieChartData = PieChartData(xVals: dataPoints, dataSet: pieChartDataSet)
        pieChartView.data = pieChartData
        pieChartDataSet.drawValuesEnabled = false
        pieChartView.drawMarkers = false
        pieChartView.drawSliceTextEnabled = false
        pieChartView.drawSlicesUnderHoleEnabled = false
        pieChartView.centerText = "10天"
        
        var colors: [UIColor] = []
        
        let usedDays = UIColor.colorWithRGB(0xFF6666)
        let remainingDays = UIColor.colorWithRGB(0x4990E2)
        
        
//        for i in 0..<dataPoints.count {
//            let red = Double(arc4random_uniform(256))
//            let green = Double(arc4random_uniform(256))
//            let blue = Double(arc4random_uniform(256))
//            
//            let color = UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
//            
//            colors.append(color)
//        }
        
        pieChartDataSet.colors = [usedDays, remainingDays]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        months = ["", "剩餘天數"]
        let unitsSold = [20.0, 10.0]
        
        setChart(months, values: unitsSold)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
