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
    
    let healthKitManager = HealthKitManager.sharedInstance
    
    var dayData:[Double] = []
    var weekData:[Double] = []
    var monthData:[Double] = []
    var yearData:[Double] = []
    
    var latestEntry: String = ""
    var latestEntryTime: String = ""
    
    var currentDistanceUnit: String = ""
    
    @IBOutlet var graphView: UIGraphView!
    @IBOutlet var graphTimeFrameSegmentedControl: UISegmentedControl!
    
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
        
        healthKitManager.requestAuthorization()
        
        let lengthUnit = self.defaults.string(forKey: "lengthUnit")!
        switch lengthUnit {
        case "miles":
            self.currentDistanceUnit = "Mi"
        case "kilometers":
            self.currentDistanceUnit = "Km"
        default:
            break
        }
        
        healthKitManager.queryTodayDistanceSum {
            self.latestEntry = "\(self.healthKitManager.todayDistance.cleanValue) \(self.currentDistanceUnit)"
        }
        
        healthKitManager.queryLatestDistanceEntry {
            if self.healthKitManager.latestDistanceEntryTimeLabel == "--:--" {
                self.latestEntryTime = "Today"
            } else {
                self.latestEntryTime = "Today, \(self.healthKitManager.latestDistanceEntryTimeLabel)"
            }
        }
        
        healthKitManager.getDistanceHistory {
            self.dayData = self.healthKitManager.distanceDayHistory
            self.weekData = self.healthKitManager.distanceWeekHistory
            self.monthData = self.healthKitManager.distanceMonthHistory
            self.yearData = self.healthKitManager.distanceYearHistory
            self.setupGraphDisplay()
        }
        
        
    }
    
    @IBAction func refreshGraph(_ sender: Any) {
        healthKitManager.queryTodayDistanceSum {
            self.latestEntry = "\(self.healthKitManager.todayDistance.cleanValue) \(self.currentDistanceUnit)"
        }
        
        healthKitManager.queryLatestDistanceEntry {
            if self.healthKitManager.latestDistanceEntryTimeLabel == "--:--" {
                self.latestEntryTime = "Today"
            } else {
                self.latestEntryTime = "Today, \(self.healthKitManager.latestDistanceEntryTimeLabel)"
            }
        }
        
        healthKitManager.getDistanceHistory {
            self.dayData = self.healthKitManager.distanceDayHistory
            self.weekData = self.healthKitManager.distanceWeekHistory
            self.monthData = self.healthKitManager.distanceMonthHistory
            self.yearData = self.healthKitManager.distanceYearHistory
            self.setupGraphDisplay()
        }
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
    
    func setupGraphDisplay() {
        
        // Indicate that the graph needs to be redrawn
        graphView.setNeedsDisplay()
        
        let graphTimeFrame: String = self.defaults.string(forKey: "timeFrame")!
        
        let graphTitle: String = "Distance"
        var graphSubtitle: String = ""
        let latestEntry = self.latestEntry
        let latestEntryTime = self.latestEntryTime
        
        // Calculate Daily Average from graphPoints Array
        var graphData: [Double] = []
        switch graphTimeFrame {
        case "Day":
            graphSubtitle = ""
            graphData = self.dayData
        case "Week":
            let dailyAverage = self.healthKitManager.distanceWeekAverage
            graphSubtitle = "Daily Average: \(dailyAverage.cleanValue)"
            graphData = self.weekData
        case "Month":
            let dailyAverage = self.healthKitManager.distanceMonthAverage
            graphSubtitle = "Daily Average: \(dailyAverage.cleanValue)"
            graphData = self.monthData
        case "Year":
            let dailyAverage = self.healthKitManager.distanceYearAverage
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
