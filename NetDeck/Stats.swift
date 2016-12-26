//
//  Stats.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.12.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import CorePlot

class Stats: NSObject, CPTPieChartDataSource, CPTPlotDelegate {
    
    static let colors = [
        UIColor(r: 231, g: 13, b: 0),
        UIColor(r: 240, g: 9, b: 254),
        UIColor(r: 60, g: 2, b: 243),
        UIColor(r: 0, g: 250, b: 214),
        UIColor(r: 8, g: 227, b: 34),
        UIColor(r: 192, g: 253, b: 2),
        UIColor(r: 243, g: 183, b: 8),
        UIColor(r: 254, g: 118, b: 13),
        UIColor(r: 235, g: 80, b: 71),
        UIColor(r: 204, g: 72, b: 212),
        UIColor(r: 114, g: 74, b: 246),
        UIColor(r: 75, g: 143, b: 223),
        UIColor(r: 76, g: 251, b: 224),
        UIColor(r: 77, g: 228, b: 94),
        UIColor(r: 212, g: 253, b: 77),
        UIColor(r: 246, g: 198, b: 62),
        UIColor(r: 212, g: 122, b: 53)
    ]
    var tableData: TableData!
    
    var height: CGFloat {
        return self.tableData.sections.count == 0 ? 0 : 300
    }
    
    func sliceFill(for pieChart: CPTPieChart, record index: UInt) -> CPTFill? {
        let color = Stats.colors[Int(index) % Stats.colors.count]
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
        
        let gradient = CPTGradient()
            .addColorStop(CPTColor.black().withAlphaComponent(0.0), atPosition: 0.9)
            .addColorStop(CPTColor.black().withAlphaComponent(0.2), atPosition: 1.0)
        gradient.gradientType = .radial
        pieChart.overlayFill = CPTFill(gradient: gradient)
        
        graph.add(pieChart)
        
        return hostView
    }
    
}
