//
//  ViewController.swift
//  UIGraphView
//
//  Created by Peter Mostoff on 5/26/17.
//  Copyright © 2017 Peter Mostoff. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let defaults = UserDefaults.standard
    
    var dayData:[Double] = [1, 2, 3, 4, 5, 4, 3, 0, 2, 3, 4, 5, 4, 3, 0, 2, 3, 4, 5, 4, 3, 0, 2, 3]
    var weekData:[Double] = [1, 2, 3, 4, 5, 4, 3]
    var monthData:[Double] = [1, 2, 3, 4, 5, 4, 3, 0, 2, 3, 4, 5, 4, 3, 0, 2, 3, 4, 5, 4, 3, 0, 2, 3, 4, 5, 4, 3, 0, 2, 3]
    var yearData:[Double] = [1, 2, 3, 4, 5, 4, 3, 0, 2, 3, 4, 5]
    
    var latestEntry: String = ""
    var latestEntryTime: String = ""
    
    var currentDistanceUnit: String = ""
    
    @IBOutlet var graphView: UIGraphView!
    @IBOutlet var graphTimeFrameSegmentedControl: UISegmentedControl!
    @IBOutlet var graphStyleSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        switch defaults.string(forKey: "timeFrame")! {
        case "Day":
            graphTimeFrameSegmentedControl.selectedSegmentIndex = 0
        case "Week":
            graphTimeFrameSegmentedControl.selectedSegmentIndex = 1
        case "Month":
            graphTimeFrameSegmentedControl.selectedSegmentIndex = 2
        case "Year":
            graphTimeFrameSegmentedControl.selectedSegmentIndex = 3
        default:
            break
        }
        
        switch defaults.bool(forKey: "barGraph") {
        case true:
            graphStyleSegmentedControl.selectedSegmentIndex = 0
            graphView.barGraph = true
        case false:
            graphStyleSegmentedControl.selectedSegmentIndex = 1
            graphView.barGraph = false
        }
        
        setupGraphDisplay()
        
    }
    
    @IBAction func setGraphTimeFrame(_ sender: Any) {
        switch graphTimeFrameSegmentedControl.selectedSegmentIndex {
        case 0:
            defaults.set("Day", forKey: "timeFrame")
        case 1:
            defaults.set("Week", forKey: "timeFrame")
        case 2:
            defaults.set("Month", forKey: "timeFrame")
        case 3:
            defaults.set("Year", forKey: "timeFrame")
        default:
            break
        }
        
        self.setupGraphDisplay()
    }
    
    @IBAction func setGraphStyle(_ sender: Any) {
        switch graphStyleSegmentedControl.selectedSegmentIndex {
        case 0:
            defaults.set(true, forKey: "barGraph")
            graphView.barGraph = true
        case 1:
            defaults.set(false, forKey: "barGraph")
            graphView.barGraph = false
        default:
            break
        }
        
        self.setupGraphDisplay()
    }
    
    func setupGraphDisplay() {
        
        let graphTitle: String = "Data"
        var graphSubtitle: String = ""
        let latestEntry = "3"
        let latestEntryTime = "Today"
        
        // Calculate Daily Average from graphPoints Array
        var graphData: [Double] = []
        let graphTimeFrame: String = self.defaults.string(forKey: "timeFrame")!
        switch graphTimeFrame {
        case "Day":
            graphSubtitle = ""
            graphData = self.dayData
        case "Week":
            let dailyAverage = Double(weekData.reduce(0, +)) / Double(weekData.count)
            graphSubtitle = "Daily Average: \(dailyAverage.cleanValue)"
            graphData = self.weekData
        case "Month":
            let dailyAverage = Double(monthData.reduce(0, +)) / Double(monthData.count)
            graphSubtitle = "Daily Average: \(dailyAverage.cleanValue)"
            graphData = self.monthData
        case "Year":
            let dailyAverage = Double(yearData.reduce(0, +)) / Double(yearData.count)
            graphSubtitle = "Daily Average: \(dailyAverage.cleanValue)"
            graphData = self.yearData
        default:
            break
        }
        
        graphView.configure(graphData: graphData,
                            graphTimeFrame: graphTimeFrame,
                            graphTitle: graphTitle,
                            graphSubtitle: graphSubtitle,
                            latestEntry: latestEntry,
                            latestEntryTime: latestEntryTime)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
