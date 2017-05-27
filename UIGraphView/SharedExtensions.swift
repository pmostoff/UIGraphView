//
//  SharedExtensions.swift
//  UIGraphView
//
//  Created by Peter Mostoff on 5/26/17.
//  Copyright © 2017 Peter Mostoff. All rights reserved.
//

import Foundation

extension Date {
    func beginningOfDay() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        return calendar.date(from: components)!
    }
    
    func beginningOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: self)
        return calendar.date(from: components)!
    }
    
    func beginningOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }
    
    func beginningOfYear() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components)!
    }
    
    func beginningOfTime() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([], from: self)
        return calendar.date(from: components)!
    }
}

extension Double {
    var cleanValue: String {
        
        let inputNumber = self
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        numberFormatter.maximumFractionDigits = 2
        
        let formattedValue = numberFormatter.string(from: inputNumber as NSNumber!)!
        
        return formattedValue
    }
}
