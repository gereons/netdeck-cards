//
//  Stats.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.12.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import CorePlot

class Stats: NSObject, CPTPieChartDataSource, CPTPlotDelegate {
    
    // color swatches from http://colorbrewer2.org
    static let paired = [
        UIColor.colorWithRGB(0xa6cee3),
        UIColor.colorWithRGB(0x1f78b4),
        UIColor.colorWithRGB(0xb2df8a),
        UIColor.colorWithRGB(0x33a02c),
        UIColor.colorWithRGB(0xfdbf6f),
        UIColor.colorWithRGB(0xff7f00),
        UIColor.colorWithRGB(0xe31a1c),
        UIColor.colorWithRGB(0xfb9a99)
    ]
    
    static let blues = [
        // UIColor.colorWithRGB(0xf7fbff), // too bright
        UIColor.colorWithRGB(0xdeebf7),
        UIColor.colorWithRGB(0xc6dbef),
        UIColor.colorWithRGB(0x9ecae1),
        UIColor.colorWithRGB(0x6baed6),
        UIColor.colorWithRGB(0x4292c6),
        UIColor.colorWithRGB(0x2171b5),
        UIColor.colorWithRGB(0x08519c),
        UIColor.colorWithRGB(0x08306b)
    ]
    
    var useBlues = false
    
    var tableData: TableData!
    
    var height: CGFloat {
        return self.tableData.sections.count == 0 ? 0 : 300
    }
    
    func sliceFill(for pieChart: CPTPieChart, record index: UInt) -> CPTFill? {
        let colors = self.useBlues ? Stats.blues : Stats.paired
        let color = colors[Int(index) % colors.count]
        return CPTFill(color: CPTColor(cgColor: color.cgColor))
    }
    
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        return UInt(self.tableData.sections.count)
    }
    
    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        return self.tableData.values[Int(idx)]
    }
    
    func hostingView(for delegate: Stats, identifier: String) -> CPTGraphHostingView {
        let frame = CGRect(x: 0, y: 0, width: 500, height: self.height)
        let hostView = CPTGraphHostingView(frame: frame)
        hostView.allowPinchScaling = false
        
        // add a graph
        let graph = CPTXYGraph(frame: hostView.bounds)
        hostView.hostedGraph = graph
        graph.paddingLeft = 0
        graph.paddingTop = 0
        graph.paddingRight = 0
        graph.paddingBottom = 0
        graph.axisSet = nil
        
        // set theme
        graph.apply(CPTTheme(named: CPTThemeName.plainWhiteTheme))
        
        graph.plotAreaFrame?.borderLineStyle = nil
        
        let pieChart = CPTPieChart()
        pieChart.dataSource = delegate
        pieChart.delegate = delegate
        pieChart.pieRadius = hostView.bounds.size.height * 0.35
        pieChart.identifier = identifier as NSString
        pieChart.startAngle = CGFloat(M_PI_2)
        pieChart.sliceDirection = .clockwise
        
        graph.add(pieChart)
        
        return hostView
    }
    
    func cardsString(_ c: Int) -> String {
        return c == 1 ? "Card".localized() : "Cards".localized()
    }
    
    func credString(_ c: String) -> String {
        return c == "1" ? "Credit".localized() : "Credits".localized()
    }

}
