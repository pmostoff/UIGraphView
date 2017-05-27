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
    
    // Variable that will be set based on timeFrame passed in configure
    // Set to sample timeFrame for interface builder preview
    var graphTimeFrame = "Week"
    
    // Variable that will be set based on graphData passed in configure
    // Filled with sample graphData for interface builder preview
    var graphData:[Double] = [1, 2, 3, 4, 5, 4, 3]
    
    // Array of X-Axis labels based on timeFrame; Set when setXAxisTitleArrays() is called
    var xAxisLabels:[String] = []
    
    var graphTitle: String = "Graph Title"
    var graphSubtitle: String = "Graph Subtitle"
    var graphLatestEntry: String = "Latest Entry"
    var graphLatestEntryTime: String = "Latest Entry Time"
    
    // IBInspectable properties can be changed in Interface Builder.
    // Use bar graph style == true ; Use line graph style == false
    @IBInspectable var barGraph: Bool = true
    // Round corners of graph: yes or no.
    @IBInspectable var cornerRounding: Bool = false
    @IBInspectable var cornerRadius: Double = 8.0
    // Properties for the graph's background gradient.
    @IBInspectable var gradientTop: UIColor = UIColor.red
    @IBInspectable var gradientBottom: UIColor = UIColor.green
    // Colors for graph data and font
    @IBInspectable var graphDataColor: UIColor = UIColor.white
    @IBInspectable var fontColor: UIColor = UIColor.white
    
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
    }
    
    override func draw(_ Graph: CGRect) {
        
        let width = Graph.width
        let height = Graph.height
        
        // If cornerRounding is ON, round corners based on cornerRadius value
        if cornerRounding == true {
            // Set up background clipping area to round corners.
            let path = UIBezierPath(roundedRect: Graph,
                                    byRoundingCorners: UIRectCorner.allCorners,
                                    cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
            path.addClip()
        }
        
        // Set the Context
        let context = UIGraphicsGetCurrentContext()
        
        // Create Gradient
        let colors = [gradientTop.cgColor, gradientBottom.cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations:[CGFloat] = [0.0, 1.0]
        let gradient = CGGradient(colorsSpace: colorSpace,
                                  colors: colors as CFArray,
                                  locations: colorLocations)
        
        // Draw Gradient
        var startPoint = CGPoint.zero
        var endPoint = CGPoint(x:0, y:self.bounds.height)
        context?.drawLinearGradient(gradient!,
                                    start: startPoint,
                                    end: endPoint,
                                    options: CGGradientDrawingOptions(rawValue: 0))
        
        // Calculate the X-Axis Location of Each Data Point
        let margin:CGFloat = 20.0
        let columnXPoint = { (column:Int) -> CGFloat in
            // Calculate Horizontal Gap Between Points
            let spacer = (width - margin*2 - 40) /
                CGFloat((self.graphData.count - 1))
            var x:CGFloat = CGFloat(column) * spacer
            x += margin + 10
            return x
        }
        
        // Calculate the Y-Axis Location of Each Data Point
        let topBorder:CGFloat = 60
        let bottomBorder:CGFloat = 50
        let graphHeight = height - topBorder - bottomBorder
        let maxValue = graphData.max()
        let columnYPoint = { (graphPoint:Double) -> CGFloat in
            var y:CGFloat = CGFloat(graphPoint) /
                CGFloat(maxValue!) * graphHeight
            y = graphHeight + topBorder - y
            return y
        }
        
        graphDataColor.setFill()
        graphDataColor.setStroke()
        
        // Draw Data Points On Graph
        for i in 0..<graphData.count {
            if graphData[i] != 0 {
                var point = CGPoint(x:columnXPoint(i), y:columnYPoint(graphData[i]))
                point.x -= 5.0/2
                point.y -= 5.0/2
                
                let circle = UIBezierPath(ovalIn: CGRect(origin: point,
                                                         size: CGSize(width: 5.0, height: 5.0)))
                circle.fill()
            }
        }
        
        if barGraph == false {
            //set up the points line
            let graphPath = UIBezierPath()
            //go to start of line
            for i in 0..<graphData.count {
                if graphData[i] != 0 {
                    graphPath.move(to: CGPoint(x:columnXPoint(i),
                                               y:columnYPoint(graphData[i])))
                    break
                }
            }
            
            
            //add points for each item in the graphData array
            //at the correct (x, y) for the point
            for i in 0..<graphData.count {
                if graphData[i] != 0 {
                    let nextPoint = CGPoint(x:columnXPoint(i),
                                            y:columnYPoint(graphData[i]))
                    graphPath.addLine(to: nextPoint)
                }
            }
            
            //Create the clipping path for the graph gradient
            
            //1 - save the state of the context (commented out for now)
            context?.saveGState()
            
            //2 - make a copy of the path
            let clippingPath = graphPath.copy() as! UIBezierPath
            
            //3 - add lines to the copied path to complete the clip area
            clippingPath.addLine(to: CGPoint(
                x: columnXPoint(graphData.count - 1),
                y:height))
            clippingPath.addLine(to: CGPoint(
                x:columnXPoint(0),
                y:height))
            clippingPath.close()
            
            //4 - add the clipping path to the context
            clippingPath.addClip()
            
            let highestYPoint = columnYPoint(maxValue!)
            startPoint = CGPoint(x:margin, y: highestYPoint)
            endPoint = CGPoint(x:margin, y:self.bounds.height)
            
            context?.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))
            context?.restoreGState()
            
            //draw the line on top of the clipped gradient
            graphPath.lineWidth = 2.0
            graphPath.stroke()
        }
        
        if barGraph == true {
            
            // Draw Vertical Bars Under Each Graph Point
            for i in 0..<graphData.count {
                let barLine = UIBezierPath()
                barLine.move(to: CGPoint(x:columnXPoint(i),
                                         y:columnYPoint(graphData[i])))
                
                let barLineBottom = CGPoint(x: columnXPoint(i),
                                            y: height - bottomBorder)
                barLine.addLine(to: barLineBottom)
                
                let color = graphDataColor.withAlphaComponent(0.3)
                color.setStroke()
                
                barLine.lineWidth = 4.0
                barLine.stroke()
            }
            
        }
        
        //MARK: - Draw Graph's Titles
        
        let graphTitle = self.graphTitle
        let graphTitleSize: CGSize = graphTitle.size(attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17)])
        drawText(text: graphTitle, textColor: fontColor, FontSize: 17, inRect: CGRect(x: margin, y: topBorder - 50, width: graphTitleSize.width, height: graphTitleSize.height))
        
        let graphSubtitle = self.graphSubtitle
        let graphSubtitleSize: CGSize = graphSubtitle.size(attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 10)])
        drawText(text: graphSubtitle, textColor: fontColor, FontSize: 10, inRect: CGRect(x: margin, y: topBorder - 30, width: graphSubtitleSize.width, height: graphSubtitleSize.height))
        
        let graphLatestEntry = self.graphLatestEntry
        let graphLatestEntrySize: CGSize = graphLatestEntry.size(attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17)])
        drawText(text: graphLatestEntry, textColor: fontColor, FontSize: 17, inRect: CGRect(x: width - margin - graphLatestEntrySize.width, y: topBorder - 50, width: graphLatestEntrySize.width, height: graphLatestEntrySize.height))
        
        let graphLatestEntryTime = self.graphLatestEntryTime
        let graphLatestEntryTimeSize: CGSize = graphLatestEntryTime.size(attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 10)])
        drawText(text: graphLatestEntryTime, textColor: fontColor, FontSize: 10, inRect: CGRect(x: width - margin - graphLatestEntryTimeSize.width, y: topBorder - 30, width: graphLatestEntryTimeSize.width, height: graphLatestEntryTimeSize.height))
        
        //MARK: - Draw Graph's Min and Max Labels
        
        // Set Max Label
        var maxLabel = "MAX"
        if graphData.max() != nil {
            maxLabel = "\(graphData.max()!.cleanValue)"
        }
        // Draw Max Label Along Bottom Line of Graph
        let maxLabelSize: CGSize = maxLabel.size(attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 10)])
        drawText(text: maxLabel, textColor: fontColor, FontSize: 10, inRect: CGRect(x: width - margin - maxLabelSize.width, y: topBorder + 2, width: maxLabelSize.width, height: maxLabelSize.height))
        
        // Draw Min Label Along Bottom Line of Graph
        let minLabel = "0"
        let minLabelSize: CGSize = minLabel.size(attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 10)])
        drawText(text: minLabel, textColor: fontColor, FontSize: 10, inRect: CGRect(x: width - margin - minLabelSize.width, y: height - bottomBorder - 14, width: minLabelSize.width, height: minLabelSize.height))
        
        //MARK: - Draw Graph's Horizontal Lines
        
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
        
        let color = graphDataColor.withAlphaComponent(0.3)
        color.setStroke()
        
        linePath.lineWidth = 1.0
        linePath.stroke()
        
        //MARK: - Draw Graph's X-Axis Labels
        
        // Set the array based on timeFrame and Date()
        setXAxisTitleArrays()
        
        // Determine Location and Spacing of X-Axis Labels
        let xMargin:CGFloat = 20.0
        let xColumnXPoint = { (column:Int) -> CGFloat in
            //Calculate gap between points
            let spacer = (width - xMargin*2 - 40) /
                CGFloat((self.xAxisLabels.count - 1))
            var x:CGFloat = CGFloat(column) * spacer
            x += margin + 10
            return x
        }
        
        // Draw the X-Axis Labels
        for i in 0..<xAxisLabels.count {
            var point = CGPoint(x: xColumnXPoint(i), y: height - bottomBorder + 5)
            let label = xAxisLabels[i]
            let labelSize: CGSize = label.size(attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 10)])
            point.x -= labelSize.width/2
            
            let labelLocation = CGRect(origin: point, size: CGSize(width: labelSize.width, height: labelSize.height))
            drawText(text: label, textColor: fontColor, FontSize: 10, inRect: labelLocation)
        }
        
    }
    
    
    func drawText(text:String,textColor:UIColor, FontSize:CGFloat, inRect:CGRect){
        
        let textFont = UIFont.systemFont(ofSize: FontSize)
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            ] as [String : Any]
        
        text.draw(in: inRect, withAttributes: textFontAttributes)
    }
    
    func setXAxisTitleArrays() {
        
        // Arrays of strings for x-axis labels
        var dayTimes:[String] = []
        var weekDays:[String] = []
        var monthDays:[String] = []
        var yearMonths:[String] = []
        
        let calendar = Calendar.current
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        let shortMonthName = dateFormatter.shortMonthSymbols!
        
        let time = dateFormatter.string(from: Date())
        
        switch time.substring(from: time.index(time.endIndex, offsetBy: -2)) {
        case "AM":
            dayTimes = ["12 AM", "12 PM", "11 PM"]
        case "PM":
            dayTimes = ["12 AM", "12 PM", "11 PM"]
        default:
            dayTimes = ["0", "12", "23"]
        }
        
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
        
        //        let timeFrame = defaults.string(forKey: "timeFrame")!
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
        
    }
    
}
