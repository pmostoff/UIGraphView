//
//  SharedExtensions.swift
//  UIGraphView
//
//  Created by Peter Mostoff on 5/26/17.
//  Copyright © 2017 Peter Mostoff. All rights reserved.
//

import Foundation

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
