//
//  UIGraphView.swift
//  UIGraphView
//
//  Created by Peter Mostoff on 5/26/17.
//  Copyright © 2017 Peter Mostoff. All rights reserved.
//

import UIKit

@IBDesignable
class UIGraphView: UIView {
    
    // IBInspectable Properties Can Be Changed in Interface Builder
    // barGraph Style: true = Bar Graph, false = Line Graph
    @IBInspectable var barGraph: Bool = true
    // Round Corners of Graph: Yes or No, By What Radius?
    @IBInspectable var cornerRounding: Bool = false
    @IBInspectable var cornerRadius: Double = 8.0
    // Colors For Graph's Background Gradient
    @IBInspectable var gradientTop: UIColor = UIColor(red:0.39, green:0.39, blue:0.39, alpha:1.0)
    @IBInspectable var gradientBottom: UIColor = UIColor.black
    // Colors For Graph's Data and Text
    @IBInspectable var graphLineColor: UIColor = UIColor.white
    @IBInspectable var graphDataColor: UIColor = UIColor.white
    @IBInspectable var graphFontColor: UIColor = UIColor.white
    
    // Variables Set When Graph is Drawn
    var width: CGFloat = 0
    var height: CGFloat = 0
    var margin: CGFloat = 0
    var topBorder: CGFloat = 0
    var bottomBorder: CGFloat = 0
    var graphHeight: CGFloat = 0
    
    // Variable to Share Context Access
    var context: CGContext!
    
    // Variables for Drawing Gradient
    var gradient: CGGradient!
    var startPoint: CGPoint!
    var endPoint: CGPoint!
    
    // Variables that Will be Set Based on Data Passed in Configure
    // Sample Data for Interface Builder Preview
    var graphTimeFrame = "Week"
    var graphData: [Double] = []
    var graphTitle: String = "Graph Title"
    var graphSubtitle: String = "Graph Subtitle"
    var graphLatestEntry: String = "Latest Entry"
    var graphLatestEntryTime: String = "Latest Entry Time"
    
    // Call this Function From ViewController to Pass in Data
    func configure(graphData: [Double],
                   graphTimeFrame: String,
                   graphTitle: String,
                   graphSubtitle: String,
                   latestEntry: String,
                   latestEntryTime: String) {
        self.graphData = graphData
        self.graphTimeFrame = graphTimeFrame
        self.graphTitle = graphTitle
        self.graphSubtitle = graphSubtitle
        self.graphLatestEntry = latestEntry
        self.graphLatestEntryTime = latestEntryTime
        
        // Erase and Previous Content - This Keeps Performance from Dropping
        self.layer.sublayers?.removeAll()
        // Redraw with New Data
        setNeedsDisplay()
    }
    
    override func draw(_ Graph: CGRect) {
        
        // Set up Spacing of Graph
        width = Graph.width
        height = Graph.height
        margin = 20
        topBorder = 60
        bottomBorder = 50
        graphHeight = height - topBorder - bottomBorder
        
        // Set the Context
        context = UIGraphicsGetCurrentContext()!
        
        // If cornerRounding is ON, round corners based on cornerRadius value
        if cornerRounding == true {
            let path = UIBezierPath(roundedRect: Graph, cornerRadius: CGFloat(cornerRadius))
            path.addClip()
        }
        
        // Draw Different Components of Graph
        // Drawing in this Order Prevents Bad Layering
        
        drawGradient()
        
        // If barGraph is ON, draw a bar graph, if OFF, draw a line graph
        if barGraph == true {
            drawBarGraph()
        } else if barGraph == false {
            drawLineGraph()
        }
        
        drawGraphLines()
        
        drawGraphPoints()
        
        drawGraphTitles()
        
        drawMinMaxLabels()
        
        drawXAxisLabels()
    }
    
    //MARK: - Define How to Draw Text
    func drawText(text: String,
                  textColor: UIColor,
                  FontSize: CGFloat,
                  inRect: CGRect) {
        
        let textFont = UIFont.systemFont(ofSize: FontSize)
        let textFontAttributes = [
            NSAttributedStringKey.font: textFont,
            NSAttributedStringKey.foregroundColor: textColor]
        
        text.draw(in: inRect,
                  withAttributes: textFontAttributes)
    }
    
    //MARK: - Draw Background Gradient
    func drawGradient() {
        // Create Gradient
        let colors = [gradientTop.cgColor, gradientBottom.cgColor] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations:[CGFloat] = [0.0, 1.0]
        gradient = CGGradient(colorsSpace: colorSpace,
                              colors: colors,
                              locations: colorLocations)
        
        // Draw Gradient
        startPoint = CGPoint.zero
        endPoint = CGPoint(x:0, y:self.bounds.height)
        context?.drawLinearGradient(gradient!,
                                    start: startPoint,
                                    end: endPoint,
                                    options: CGGradientDrawingOptions(rawValue: 0))
    }
    
    //MARK: - Draw Bar Graph
    func drawBarGraph() {
        
        let maxValue = graphData.max()
        
        // Calculate the X-Axis Location of Each Data Point
        let columnXPoint = { (column:Int) -> CGFloat in
            // Calculate Horizontal Gap Between Points
            let spacer = (self.width - self.margin*2 - 40) /
                CGFloat((self.graphData.count - 1))
            var x:CGFloat = CGFloat(column) * spacer
            x = x + self.margin + 10
            return x
        }
        
        // Calculate the Y-Axis Location of Each Data Point
        let columnYPoint = { (graphPoint:Double) -> CGFloat in
            var y:CGFloat = CGFloat(graphPoint) /
                CGFloat(maxValue!) * self.graphHeight
            y = self.graphHeight + self.topBorder - y
            return y
        }
        
        // Draw Vertical Bars Under Each Graph Point
        for i in 0..<graphData.count {
            let barLine = UIBezierPath()
            barLine.move(to: CGPoint(x:columnXPoint(i),
                                     y:columnYPoint(graphData[i])))
            
            barLine.addLine(to: CGPoint(x: columnXPoint(i),
                                        y: height - bottomBorder))
            
            let color = graphDataColor.withAlphaComponent(0.5)
            color.setStroke()
            
            barLine.lineWidth = 4.0
            barLine.stroke()
        }
    }
    
    //MARK: - Draw Line Graph
    func drawLineGraph() {
        
        let maxValue = graphData.max()
        
        // Calculate the X-Axis Location of Each Data Point
        let columnXPoint = { (column:Int) -> CGFloat in
            // Calculate Horizontal Gap Between Points
            let spacer = (self.width - self.margin*2 - 40) /
                CGFloat((self.graphData.count - 1))
            var x:CGFloat = CGFloat(column) * spacer
            x = x + self.margin + 10
            return x
        }
        
        // Calculate the Y-Axis Location of Each Data Point
        let columnYPoint = { (graphPoint:Double) -> CGFloat in
            var y:CGFloat = CGFloat(graphPoint) /
                CGFloat(maxValue!) * self.graphHeight
            y = self.graphHeight + self.topBorder - y
            return y
        }
        
        // Set Up the Points Line
        let graphPath = UIBezierPath()
        // Begin the line at the first non-zero point
        for i in 0..<graphData.count {
            if graphData[i] != 0 {
                graphPath.move(to: CGPoint(x:columnXPoint(i),
                                           y:columnYPoint(graphData[i])))
                break
            }
        }
        
        // Add Points for Each Item in graphData Array
        for i in 0..<graphData.count {
            if graphData[i] != 0 {
                let nextPoint = CGPoint(x:columnXPoint(i),
                                        y:columnYPoint(graphData[i]))
                
                graphPath.addLine(to: nextPoint)
            }
        }
        
        // Save Context State
        context?.saveGState()
        
        if maxValue != nil {
            // Make Copy of Path
            let clippingPath = graphPath.copy() as! UIBezierPath
            
            // Add Lines to Clipping Path
            clippingPath.addLine(to: CGPoint(x: columnXPoint(graphData.count - 1),
                                             y:height))
            clippingPath.addLine(to: CGPoint(x:columnXPoint(0),
                                             y:height))
            clippingPath.close()
            
            // Add Clipping Path
            clippingPath.addClip()
            
            let highestYPoint = columnYPoint(maxValue!)
            startPoint = CGPoint(x:margin, y: highestYPoint)
            endPoint = CGPoint(x:margin, y:height - bottomBorder)
            
            context?.drawLinearGradient(gradient!,
                                        start: startPoint,
                                        end: endPoint,
                                        options: CGGradientDrawingOptions(rawValue: 0))
            context?.restoreGState()
        }
        
        // Draw Graph Line on Top of Clipped Gradient
        let color = graphDataColor.withAlphaComponent(0.5)
        color.setStroke()
        graphPath.lineWidth = 2.0
        graphPath.stroke()
        
    }
    
    //MARK: - Draw Graph Data
    func drawGraphPoints() {
        
        let maxValue = graphData.max()
        
        // Calculate the X-Axis Location of Each Data Point
        let columnXPoint = { (column:Int) -> CGFloat in
            // Calculate Horizontal Gap Between Points
            let spacer = (self.width - self.margin*2 - 40) /
                CGFloat((self.graphData.count - 1))
            var x:CGFloat = CGFloat(column) * spacer
            x = x + self.margin + 10
            return x
        }
        
        // Calculate the Y-Axis Location of Each Data Point
        let columnYPoint = { (graphPoint:Double) -> CGFloat in
            var y:CGFloat = CGFloat(graphPoint) /
                CGFloat(maxValue!) * self.graphHeight
            y = self.graphHeight + self.topBorder - y
            return y
        }
        
        // Draw Data Points On Graph
        for i in 0..<graphData.count {
            if graphData[i] != 0 {
                var point = CGPoint(x:columnXPoint(i),
                                    y:columnYPoint(graphData[i]))
                point.x -= 5.0/2
                point.y -= 5.0/2
                
                let circle = UIBezierPath(ovalIn: CGRect(origin: point,
                                                         size: CGSize(width: 5.0, height: 5.0)))
                
                let color = graphDataColor
                color.setFill()
                circle.fill()
            }
        }
    }
    
    //MARK: - Draw Graph's Horizontal Lines
    func drawGraphLines() {
        
        let linePath = UIBezierPath()
        
        // Draw Top Line of Graph
        linePath.move(to: CGPoint(x:margin, y: topBorder))
        linePath.addLine(to: CGPoint(x: width - margin,
                                     y:topBorder))
        
        // Draw Center Line of Graph
        linePath.move(to: CGPoint(x:margin,
                                  y: graphHeight/2 + topBorder))
        linePath.addLine(to: CGPoint(x:width - margin,
                                     y:graphHeight/2 + topBorder))
        
        // Draw Bottom Line of Graph
        linePath.move(to: CGPoint(x:margin,
                                  y:height - bottomBorder))
        linePath.addLine(to: CGPoint(x:width - margin,
                                     y:height - bottomBorder))
        
        let lineColor = graphLineColor.withAlphaComponent(0.3)
        lineColor.setStroke()
        
        linePath.lineWidth = 1.0
        linePath.stroke()

    }
    
    //MARK: - Draw Graph's Titles
    func drawGraphTitles() {
        
        // Draw Top Left Large Label
        let graphTitle = self.graphTitle
        let graphTitleSize: CGSize = graphTitle.size(withAttributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17)])
        drawText(text: graphTitle,
                 textColor: graphFontColor,
                 FontSize: 17,
                 inRect: CGRect(x: margin,
                                y: topBorder - 50,
                                width: graphTitleSize.width,
                                height: graphTitleSize.height))
        
        // Draw Top Left Small Label
        let graphSubtitle = self.graphSubtitle
        let graphSubtitleSize: CGSize = graphSubtitle.size(withAttributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 10)])
        drawText(text: graphSubtitle,
                 textColor: graphFontColor,
                 FontSize: 10,
                 inRect: CGRect(x: margin,
                                y: topBorder - 30,
                                width: graphSubtitleSize.width,
                                height: graphSubtitleSize.height))
        
        // Draw Top Right Large Label
        let graphLatestEntry = self.graphLatestEntry
        let graphLatestEntrySize: CGSize = graphLatestEntry.size(withAttributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17)])
        drawText(text: graphLatestEntry,
                 textColor: graphFontColor,
                 FontSize: 17,
                 inRect: CGRect(x: width - margin - graphLatestEntrySize.width,
                                y: topBorder - 50,
                                width: graphLatestEntrySize.width,
                                height: graphLatestEntrySize.height))
        
        // Draw Top Right Small Label
        let graphLatestEntryTime = self.graphLatestEntryTime
        let graphLatestEntryTimeSize: CGSize = graphLatestEntryTime.size(withAttributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 10)])
        drawText(text: graphLatestEntryTime,
                 textColor: graphFontColor,
                 FontSize: 10,
                 inRect: CGRect(x: width - margin - graphLatestEntryTimeSize.width,
                                y: topBorder - 30,
                                width: graphLatestEntryTimeSize.width,
                                height: graphLatestEntryTimeSize.height))
    }
    
    //MARK: - Draw Graph's Min and Max Labels
    func drawMinMaxLabels() {
        
        // Set Max Label
        var maxLabel = "MAX"
        if graphData.max() != nil {
            maxLabel = "\(graphData.max()!.cleanValue)"
        }
        // Draw Max Label Along Top Line of Graph
        let maxLabelSize: CGSize = maxLabel.size(withAttributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 10)])
        drawText(text: maxLabel,
                 textColor: graphFontColor,
                 FontSize: 10,
                 inRect: CGRect(x: width - margin - maxLabelSize.width,
                                y: topBorder + 2,
                                width: maxLabelSize.width,
                                height: maxLabelSize.height))
        
        // Draw Min Label Along Bottom Line of Graph
        let minLabel = "0"
        let minLabelSize: CGSize = minLabel.size(withAttributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 10)])
        drawText(text: minLabel,
                 textColor: graphFontColor,
                 FontSize: 10,
                 inRect: CGRect(x: width - margin - minLabelSize.width,
                                y: height - bottomBorder - 14,
                                width: minLabelSize.width,
                                height: minLabelSize.height))
    }
    
    //MARK: - Draw Graph's X-Axis Labels
    func drawXAxisLabels() {
        
        // Array of X-Axis labels; Filled Based on graphTimeFrame
        var xAxisLabels:[String] = []
        
        // Arrays of Strings for X-Axis Labels
        var dayTimes:[String] = []
        var weekDays:[String] = []
        var monthDays:[String] = []
        var yearMonths:[String] = []
        
        let calendar = Calendar.current
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        let shortMonthName = dateFormatter.shortMonthSymbols!
        
        let time = dateFormatter.string(from: Date())
        
        // Fill dayTimes Array
        // Fill Properly If 12-Hour Time; If 24-Hour Time
        switch String(time[time.index(time.endIndex, offsetBy: -2)...]) {
        case "AM":
            dayTimes = ["12 AM", "12 PM", "11 PM"]
        case "PM":
            dayTimes = ["12 AM", "12 PM", "11 PM"]
        default:
            dayTimes = ["0", "12", "23"]
        }
        
        // Fill weekDays Array
        for i in 0...6 {
            let previousDay = calendar.date(byAdding: .day, value: (i * -1), to: Date())!
            let day = calendar.component(.day, from: previousDay)
            let month = calendar.component(.month, from: previousDay)
            
            let monthSymbol = shortMonthName[month - 1].uppercased()
            var dayToAdd = "\(day)"
            
            if day == 1 || i == 6 {
                dayToAdd = "\(monthSymbol) \(day)"
            }
            
            weekDays.insert(dayToAdd, at: 0)
        }
        
        // Fill monthTimes Array
        for i in 0...30 {
            let previousDay = calendar.date(byAdding: .day, value: (i * -1), to: Date())!
            let day = calendar.component(.day, from: previousDay)
            let month = calendar.component(.month, from: previousDay)
            
            let monthSymbol = shortMonthName[month - 1].uppercased()
            var dayToAdd = "\(day)"
            
            if ((i == 0 || i == 7 || i == 14 || i == 21) && day < 8) || i == 28 {
                dayToAdd = "\(monthSymbol) \(day)"
            }
            
            monthDays.insert(dayToAdd, at: 0)
        }
        
        // Fill yearMonths Array
        for i in 0...11 {
            let previousMonth = calendar.date(byAdding: .month, value: (i * -1), to: Date())!
            let month = calendar.component(.month, from: previousMonth)
            let year = calendar.component(.year, from: previousMonth)
            
            let monthSymbol = shortMonthName[month - 1].uppercased()
            var monthToAdd = "\(monthSymbol)"
            
            if ((i == 0 || i == 3 || i == 6) && month < 4) || i == 9 {
                monthToAdd = "\(monthSymbol) \(year)"
            }
            
            yearMonths.insert(monthToAdd, at: 0)
            
        }
        
        // Fill xAxisLabels Array Based on graphTimeFrame
        // Empty Strings Ensure Proper Spacing in View
        switch self.graphTimeFrame {
        case "Day":
            xAxisLabels = [dayTimes[0], "", "", "", "", "", "", "", "", "", "", "",
                           dayTimes[1], "", "", "", "", "", "", "", "", "", "",
                           dayTimes[2]]
        case "Week":
            xAxisLabels = [weekDays[0],
                           weekDays[1],
                           weekDays[2],
                           weekDays[3],
                           weekDays[4],
                           weekDays[5],
                           weekDays[6]]
        case "Month":
            xAxisLabels = ["", "",
                           monthDays[2], "", "", "", "", "", "",
                           monthDays[9], "", "", "", "", "", "",
                           monthDays[16], "", "", "", "", "", "",
                           monthDays[23], "", "", "", "", "", "",
                           monthDays[30]]
        case "Year":
            xAxisLabels = ["", "",
                           yearMonths[2], "", "",
                           yearMonths[5], "", "",
                           yearMonths[8], "", "",
                           yearMonths[11]]
        default:
            break
        }
        
        // Determine Location and Spacing of X-Axis Labels
        let xMargin:CGFloat = 20.0
        let xColumnXPoint = { (column:Int) -> CGFloat in
            //Calculate Gap Between Points
            let spacer = (self.width - xMargin*2 - 40) /
                CGFloat((xAxisLabels.count - 1))
            var x:CGFloat = CGFloat(column) * spacer
            x += self.margin + 10
            return x
        }
        
        // Draw the X-Axis Labels
        for i in 0..<xAxisLabels.count {
            var point = CGPoint(x: xColumnXPoint(i), y: height - bottomBorder + 5)
            let label = xAxisLabels[i]
            let labelSize: CGSize = label.size(withAttributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 10)])
            point.x = point.x - labelSize.width/2
            
            let labelLocation = CGRect(origin: point,
                                       size: CGSize(width: labelSize.width, height: labelSize.height))
            drawText(text: label,
                     textColor: graphFontColor,
                     FontSize: 10,
                     inRect: labelLocation)
        }
        
    }
    
}
