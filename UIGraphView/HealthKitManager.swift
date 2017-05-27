//
//  HealthKitManager.swift
//  UIGraphView
//
//  Created by Peter Mostoff on 5/26/17.
//  Copyright © 2017 Peter Mostoff. All rights reserved.
//

import HealthKit

class HealthKitManager {
    
    // Pull in UserDefaults
    let defaults = UserDefaults.standard
    
    // Initialize a shared singletone instance of HealthKitManager to be referenced in other files
    class var sharedInstance: HealthKitManager {
        struct Singleton {
            static let instance = HealthKitManager()
        }
        return Singleton.instance
    }
    
    let healthStore: HKHealthStore? = {
        if HKHealthStore.isHealthDataAvailable() {
            return HKHealthStore()
        } else {
            return nil
        }
    }()
    
    let distance = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)
    
    // Initialize variables for statisticQueries to report back to. These are then read in requestHealthKitAuthorization
    var todayDistance: Double = 0
    var thisWeekDistance: Double = 0
    var thisMonthDistance: Double = 0
    var thisYearDistance: Double = 0
    var onRecordDistance: Double = 0
    // requestHealthKitAuthorization reports back to these varaibles
    var todayLabel: String = "--"
    var thisWeekLabel: String = "--"
    var thisMonthLabel: String = "--"
    var thisYearLabel: String = "--"
    var onRecordLabel: String = "--"
    
    var latestDistanceEntryTimeLabel: String = "--:--"
    
    var distanceDayHistory:[Double] = []
    var distanceWeekHistory:[Double] = []
    var distanceMonthHistory:[Double] = []
    var distanceYearHistory:[Double] = []
    
    var distanceWeekAverage: Double = 0
    var distanceMonthAverage: Double = 0
    var distanceYearAverage: Double = 0
    // Var for dailyGoal in Summary view
    var dailyGoalLabel: String = "-- / --"
    // Var for percentages in Summary view
    var percentageLabel: String = "--%"
    var percentageBar: Float = 0
    // Var for averageLabels in Summary view
    var thisWeekAverageLabel: String = "--"
    var thisMonthAverageLabel: String = "--"
    var thisYearAverageLabel: String = "--"
    
    //MARK: - HealthKit function called to retrieve information
    
    func requestAuthorization() {
        let dataTypesToRead = [distance!] as Set<HKObjectType>
        healthStore?.requestAuthorization(toShare: nil, read: dataTypesToRead, completion: { success, error in
            if success {
                return
            } else {
                print("HealthKit Authorization Error")
            }
        })
    }
    
    func queryLatestDistanceEntry(_ completion: @escaping () -> Void) {
        
        let todayPredicate = HKQuery.predicateForSamples(withStart: Date().beginningOfDay(), end: Date())
        
        let latestWaterIntakeEntryQuery = HKSampleQuery(sampleType: distance!, predicate: todayPredicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) { query, results, error in
            
            DispatchQueue.main.async(execute: {
                
                // error with query
                if error != nil {
                    print(error!)
                    completion()
                    return
                }
                
                // check for valid results
                guard let results = results else {
                    print("Query Returned No Results")
                    completion()
                    return
                }
                
                // If there are no entries, return the function - this prevents crashes if there are no readings for the day
                if results.count == 0 {
                    print("Zero Distance Samples Found")
                    completion()
                    return
                }
                
                // extract the one sample
                guard let latestDistanceEntryResult = results.last as? HKQuantitySample else {
                    print("Type Problem With Distance")
                    completion()
                    return
                }
                
                let latestDistanceEntryTime = latestDistanceEntryResult.startDate
                
                let dateFormatter = DateFormatter()
                dateFormatter.timeStyle = .short
                
                self.latestDistanceEntryTimeLabel = dateFormatter.string(from: latestDistanceEntryTime)
                
                completion()
            })
        }
        
        healthStore?.execute(latestWaterIntakeEntryQuery)
        
    }
    
    func queryTodayDistanceSum(_ completion: @escaping () -> Void) {
        
        let todayPredicate = HKQuery.predicateForSamples(withStart: Date().beginningOfDay(), end: Date())
        
        let statisticsSumQuery = HKStatisticsQuery(quantityType: distance!, quantitySamplePredicate: todayPredicate, options: .cumulativeSum) { query, result, error in
            if let sumQuantity = result?.sumQuantity() {
                DispatchQueue.main.async(execute: {
                    
                    var lengthUnit: String = ""
                    var dailyGoal: Double = 0
                    var totalDistance:Double = 0
                    switch self.defaults.string(forKey: "lengthUnit")! {
                    case "miles":
                        lengthUnit = "mi"
                        dailyGoal = self.defaults.double(forKey: "dailyGoalMiles")
                        totalDistance = sumQuantity.doubleValue(for: HKUnit.mile())
                    case "kilometers":
                        lengthUnit = "km"
                        dailyGoal = self.defaults.double(forKey: "dailyGoalKilometers")
                        totalDistance = sumQuantity.doubleValue(for: HKUnit.meterUnit(with: .kilo))
                    default:
                        break
                    }
                    
                    self.todayDistance = totalDistance
                    self.todayLabel = "\(totalDistance.cleanValue) \(lengthUnit)"
                    self.dailyGoalLabel = "\(totalDistance.cleanValue) / \(dailyGoal.cleanValue) \(lengthUnit)"
                    
                    let percentageComplete = round((totalDistance / dailyGoal) * 100) / 100
                    self.percentageLabel = String(Int(percentageComplete * 100)) + "%"
                    self.percentageBar = Float(percentageComplete)
                    
                    completion()
                })
            } else { // If there is no data for the given time frame, zero out labels
                DispatchQueue.main.async(execute: {
                    
                    var lengthUnit: String = ""
                    var dailyGoal: Double = 0
                    switch self.defaults.string(forKey: "lengthUnit")! {
                    case "miles":
                        lengthUnit = "mi"
                        dailyGoal = self.defaults.double(forKey: "dailyGoalMiles")
                    case "kilometers":
                        lengthUnit = "km"
                        dailyGoal = self.defaults.double(forKey: "dailyGoalKilometers")
                    default:
                        break
                    }
                    
                    self.todayLabel = "0 " + lengthUnit
                    self.dailyGoalLabel = "0 / \((round((dailyGoal) * 100) / 100).cleanValue) " + lengthUnit
                    
                    self.percentageLabel = "0%"
                    self.percentageBar = Float(0)
                    
                    completion()
                })
            }
        }
        healthStore?.execute(statisticsSumQuery)
    }
    
    func queryThisWeekDistanceSum(_ completion: @escaping () -> Void) {
        
        let thisWeekPredicate = HKQuery.predicateForSamples(withStart: Date().beginningOfWeek(), end: Date())
        
        let statisticsSumQuery = HKStatisticsQuery(quantityType: distance!, quantitySamplePredicate: thisWeekPredicate, options: .cumulativeSum) { query, result, error in
            if let sumQuantity = result?.sumQuantity() {
                DispatchQueue.main.async(execute: {
                    
                    // Set up days to divide by for average
                    let dayOfWeek = ceil(Double(Date().timeIntervalSince(Date().beginningOfWeek())) / 60 / 60 / 24)
                    
                    var lengthUnit: String = ""
                    var totalDistance:Double = 0
                    switch self.defaults.string(forKey: "lengthUnit")! {
                    case "miles":
                        lengthUnit = "mi"
                        totalDistance = sumQuantity.doubleValue(for: HKUnit.mile())
                    case "kilometers":
                        lengthUnit = "km"
                        totalDistance = sumQuantity.doubleValue(for: HKUnit.meterUnit(with: .kilo))
                    default:
                        break
                    }
                    
                    self.thisWeekDistance = totalDistance
                    let thisWeekString = (round(totalDistance * 100) / 100).cleanValue
                    self.thisWeekLabel = thisWeekString + " " + lengthUnit
                    self.thisWeekAverageLabel = (totalDistance / dayOfWeek).cleanValue + " " + lengthUnit
                    
                    completion()
                })
            } else { // If there is no data for the given time frame, zero out labels
                DispatchQueue.main.async(execute: {
                    
                    var lengthUnit: String = ""
                    switch self.defaults.string(forKey: "lengthUnit")! {
                    case "miles":
                        lengthUnit = "mi"
                    case "kilometers":
                        lengthUnit = "km"
                    default:
                        break
                    }
                    
                    self.thisWeekLabel = "0 " + lengthUnit
                    self.thisWeekAverageLabel = "0 " + lengthUnit
                    
                    completion()
                })
            }
        }
        healthStore?.execute(statisticsSumQuery)
    }
    
    func queryThisMonthDistanceSum(_ completion: @escaping () -> Void) {
        
        let thisMonthPredicate = HKQuery.predicateForSamples(withStart: Date().beginningOfMonth(), end: Date())
        
        let statisticsSumQuery = HKStatisticsQuery(quantityType: distance!, quantitySamplePredicate: thisMonthPredicate, options: .cumulativeSum) { query, result, error in
            if let sumQuantity = result?.sumQuantity() {
                DispatchQueue.main.async(execute: {
                    
                    // Set up days to divide by for average
                    let dayOfMonth = ceil(Double(Date().timeIntervalSince(Date().beginningOfMonth())) / 60 / 60 / 24)
                    
                    var lengthUnit: String = ""
                    var totalDistance:Double = 0
                    switch self.defaults.string(forKey: "lengthUnit")! {
                    case "miles":
                        lengthUnit = "mi"
                        totalDistance = sumQuantity.doubleValue(for: HKUnit.mile())
                    case "kilometers":
                        lengthUnit = "km"
                        totalDistance = sumQuantity.doubleValue(for: HKUnit.meterUnit(with: .kilo))
                    default:
                        break
                    }
                    
                    self.thisMonthDistance = totalDistance
                    let thisMonthString = (round(self.thisMonthDistance * 100) / 100).cleanValue
                    self.thisMonthLabel = thisMonthString + " " + lengthUnit
                    self.thisMonthAverageLabel = String(round((self.thisMonthDistance / dayOfMonth) * 100) / 100) + " " + lengthUnit
                    
                    completion()
                })
            } else { // If there is no data for the given time frame, zero out labels
                DispatchQueue.main.async(execute: {
                    
                    var lengthUnit: String = ""
                    switch self.defaults.string(forKey: "lengthUnit")! {
                    case "miles":
                        lengthUnit = "mi"
                    case "kilometers":
                        lengthUnit = "km"
                    default:
                        break
                    }
                    
                    self.thisMonthLabel = "0 " + lengthUnit
                    self.thisMonthAverageLabel = "0 " + lengthUnit
                    
                    completion()
                })
            }
        }
        healthStore?.execute(statisticsSumQuery)
    }
    
    func queryThisYearDistanceSum(_ completion: @escaping () -> Void) {
        
        let thisYearPredicate = HKQuery.predicateForSamples(withStart: Date().beginningOfYear(), end: Date())
        
        let statisticsSumQuery = HKStatisticsQuery(quantityType: distance!, quantitySamplePredicate: thisYearPredicate, options: .cumulativeSum) { query, result, error in
            if let sumQuantity = result?.sumQuantity() {
                DispatchQueue.main.async(execute: {
                    
                    // Set up days to divide by for average
                    let dayOfYear = ceil(Double(Date().timeIntervalSince(Date().beginningOfYear())) / 60 / 60 / 24)
                    
                    var lengthUnit: String = ""
                    var totalDistance:Double = 0
                    switch self.defaults.string(forKey: "lengthUnit")! {
                    case "miles":
                        lengthUnit = "mi"
                        totalDistance = sumQuantity.doubleValue(for: HKUnit.mile())
                    case "kilometers":
                        lengthUnit = "km"
                        totalDistance = sumQuantity.doubleValue(for: HKUnit.meterUnit(with: .kilo))
                    default:
                        break
                    }
                    
                    self.thisYearDistance = totalDistance
                    let thisYearString = (round(totalDistance * 100) / 100).cleanValue
                    self.thisYearLabel = thisYearString + " " + lengthUnit
                    self.thisYearAverageLabel = (totalDistance / dayOfYear).cleanValue + " " + lengthUnit
                    
                    completion()
                })
            } else { // If there is no data for the given time frame, zero out labels
                DispatchQueue.main.async(execute: {
                    
                    var lengthUnit: String = ""
                    switch self.defaults.string(forKey: "lengthUnit")! {
                    case "miles":
                        lengthUnit = "mi"
                    case "kilometers":
                        lengthUnit = "km"
                    default:
                        break
                    }
                    
                    self.thisYearLabel = "0 " + lengthUnit
                    self.thisYearAverageLabel = "0 " + lengthUnit
                    
                    completion()
                })
            }
        }
        healthStore?.execute(statisticsSumQuery)
    }
    
    func queryOnRecordDistanceSum(_ completion: @escaping () -> Void) {
        
        let onRecordPredicate = HKQuery.predicateForSamples(withStart: Date().beginningOfTime(), end: Date())
        
        let statisticsSumQuery = HKStatisticsQuery(quantityType: distance!, quantitySamplePredicate: onRecordPredicate, options: .cumulativeSum) { query, result, error in
            if let sumQuantity = result?.sumQuantity() {
                DispatchQueue.main.async(execute: {
                    
                    var lengthUnit: String = ""
                    var totalDistance:Double = 0
                    switch self.defaults.string(forKey: "lengthUnit")! {
                    case "miles":
                        lengthUnit = "mi"
                        totalDistance = sumQuantity.doubleValue(for: HKUnit.mile())
                    case "kilometers":
                        lengthUnit = "km"
                        totalDistance = sumQuantity.doubleValue(for: HKUnit.meterUnit(with: .kilo))
                    default:
                        break
                    }
                    
                    self.onRecordDistance = totalDistance
                    let onRecordString = (round(self.onRecordDistance * 100) / 100).cleanValue
                    self.onRecordLabel = onRecordString + " " + lengthUnit
                    
                    completion()
                })
            } else { // If there is no data for the given time frame, zero out labels
                DispatchQueue.main.async(execute: {
                    
                    var lengthUnit: String = ""
                    switch self.defaults.string(forKey: "lengthUnit")! {
                    case "miles":
                        lengthUnit = "mi"
                    case "kilometers":
                        lengthUnit = "km"
                    default:
                        break
                    }
                    
                    self.onRecordLabel = "0 " + lengthUnit
                    
                    completion()
                })
            }
        }
        healthStore?.execute(statisticsSumQuery)
    }
    
    func getDistanceHistory(_ completion: @escaping () -> Void) {
        
        // Reset the arrays to emtpy to deal with any changes
        distanceDayHistory = []
        distanceWeekHistory = []
        distanceMonthHistory = []
        distanceYearHistory = []
        
        let dayOptions: HKStatisticsOptions = [.cumulativeSum]
        let weekOptions: HKStatisticsOptions = [.cumulativeSum]
        let monthOptions: HKStatisticsOptions = [.cumulativeSum]
        let yearOptions: HKStatisticsOptions = [.cumulativeSum]
        
        var dayInterval: DateComponents = DateComponents()
        dayInterval.hour = 1
        var weekInterval: DateComponents = DateComponents()
        weekInterval.day = 1
        var monthInterval: DateComponents = DateComponents()
        monthInterval.day = 1
        var yearInterval: DateComponents = DateComponents()
        yearInterval.month = 1
        
        let dayBeginningDate = Date().beginningOfDay()
        let weekBeginningDate = Calendar.current.date(byAdding: .day, value: -6, to: Date().beginningOfDay())!
        let monthBeginningDate = Calendar.current.date(byAdding: .day, value: -30, to: Date().beginningOfDay())!
        let yearBeginningDate = Calendar.current.date(byAdding: .month, value: -11, to: Date().beginningOfMonth())!
        
        let dayPredicate = HKQuery.predicateForSamples(withStart: dayBeginningDate, end: Date())
        let weekPredicate = HKQuery.predicateForSamples(withStart: weekBeginningDate, end: Date())
        let monthPredicate = HKQuery.predicateForSamples(withStart: monthBeginningDate, end: Date())
        let yearPredicate = HKQuery.predicateForSamples(withStart: yearBeginningDate, end: Date())
        
        let dayQuery = HKStatisticsCollectionQuery(quantityType: distance!, quantitySamplePredicate: dayPredicate, options: dayOptions, anchorDate: dayBeginningDate, intervalComponents: dayInterval)
        let weekQuery = HKStatisticsCollectionQuery(quantityType: distance!, quantitySamplePredicate: weekPredicate, options: weekOptions, anchorDate: weekBeginningDate, intervalComponents: weekInterval)
        let monthQuery = HKStatisticsCollectionQuery(quantityType: distance!, quantitySamplePredicate: monthPredicate, options: monthOptions, anchorDate: monthBeginningDate, intervalComponents: monthInterval)
        let yearQuery = HKStatisticsCollectionQuery(quantityType: distance!, quantitySamplePredicate: yearPredicate, options: yearOptions, anchorDate: yearBeginningDate, intervalComponents: yearInterval)
        
        dayQuery.initialResultsHandler = { query, results, error in
            DispatchQueue.main.async(execute: {
                if error != nil {
                    print(error?.localizedDescription as Any)
                    return
                }
                
                if let myResults = results{
                    myResults.enumerateStatistics(from: dayBeginningDate, to: Date()) {
                        statistics, stop in
                        if let quantity = statistics.sumQuantity() {
                            var distance:Double = 0
                            switch self.defaults.string(forKey: "lengthUnit")! {
                            case "miles":
                                distance = quantity.doubleValue(for: HKUnit.mile())
                            case "kilometers":
                                distance = quantity.doubleValue(for: HKUnit.meterUnit(with: .kilo))
                            default:
                                break
                            }
                            self.distanceDayHistory.append(distance)
                        } else {
                            self.distanceDayHistory.append(0)
                        }
                    }
                }
                
                let currentHour = Calendar.current.dateComponents([.hour], from: Date()).hour
                let hoursRemaining = 23 - currentHour!
                for _ in 0...hoursRemaining {
                    self.distanceDayHistory.append(0)
                }
                completion()
            })
        }
        
        weekQuery.initialResultsHandler = { query, results, error in
            DispatchQueue.main.async(execute: {
                if error != nil {
                    print(error?.localizedDescription as Any)
                    return
                }
                
                if let myResults = results{
                    myResults.enumerateStatistics(from: weekBeginningDate, to: Date()) {
                        statistics, stop in
                        if let quantity = statistics.sumQuantity() {
                            var distance:Double = 0
                            switch self.defaults.string(forKey: "lengthUnit")! {
                            case "miles":
                                distance = quantity.doubleValue(for: HKUnit.mile())
                            case "kilometers":
                                distance = quantity.doubleValue(for: HKUnit.meterUnit(with: .kilo))
                            default:
                                break
                            }
                            self.distanceWeekHistory.append(distance)
                        } else {
                            self.distanceWeekHistory.append(0)
                        }
                    }
                }
                self.distanceWeekAverage = self.distanceWeekHistory.reduce(0, +) / Double(self.distanceWeekHistory.count)
                completion()
            })
        }
        
        monthQuery.initialResultsHandler = { query, results, error in
            DispatchQueue.main.async(execute: {
                if error != nil {
                    print(error?.localizedDescription as Any)
                    return
                }
                
                if let myResults = results{
                    myResults.enumerateStatistics(from: monthBeginningDate, to: Date()) {
                        statistics, stop in
                        if let quantity = statistics.sumQuantity() {
                            var distance:Double = 0
                            switch self.defaults.string(forKey: "lengthUnit")! {
                            case "miles":
                                distance = quantity.doubleValue(for: HKUnit.mile())
                            case "kilometers":
                                distance = quantity.doubleValue(for: HKUnit.meterUnit(with: .kilo))
                            default:
                                break
                            }
                            self.distanceMonthHistory.append(distance)
                        } else {
                            self.distanceMonthHistory.append(0)
                        }
                    }
                }
                self.distanceMonthAverage = self.distanceMonthHistory.reduce(0, +) / Double(self.distanceMonthHistory.count)
                completion()
            })
        }
        
        yearQuery.initialResultsHandler = { query, results, error in
            DispatchQueue.main.async(execute: {
                if error != nil {
                    print(error?.localizedDescription as Any)
                    return
                }
                
                if let myResults = results{
                    myResults.enumerateStatistics(from: yearBeginningDate, to: Date()) {
                        statistics, stop in
                        
                        var numberOfDays: Int
                        if Calendar.current.component(.month, from: statistics.startDate) == Calendar.current.component(.month, from: Date()) {
                            numberOfDays = Calendar.current.component(.day, from: Date())
                        } else {
                            numberOfDays = Calendar.current.range(of: .day, in: .month, for: statistics.startDate)!.count
                        }
                        
                        if let quantity = statistics.sumQuantity() {
                            var distance:Double = 0
                            switch self.defaults.string(forKey: "lengthUnit")! {
                            case "miles":
                                distance = quantity.doubleValue(for: HKUnit.mile())
                            case "kilometers":
                                distance = quantity.doubleValue(for: HKUnit.meterUnit(with: .kilo))
                            default:
                                break
                            }
                            let distanceAverage = distance / Double(numberOfDays)
                            self.distanceYearHistory.append(distanceAverage)
                        } else {
                            self.distanceYearHistory.append(0)
                        }
                        
                    }
                }
                self.distanceYearAverage = self.distanceYearHistory.reduce(0, +) / Double(self.distanceYearHistory.count)
                completion()
            })
        }
        
        healthStore?.execute(dayQuery)
        healthStore?.execute(weekQuery)
        healthStore?.execute(monthQuery)
        healthStore?.execute(yearQuery)
        
    }
    
}
