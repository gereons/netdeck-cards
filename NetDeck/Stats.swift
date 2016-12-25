//
//  Stats.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.12.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import CorePlot

class Stats: NSObject, CPTPlotDataSource, CPTPlotDelegate {
    
    static let colors = [ UIColor.red, UIColor.blue, UIColor.green ]
    var tableData: TableData!
    
    var height: CGFloat {
        return self.tableData.sections.count == 0 ? 0 : 300
    }
    
    func sliceFill(for pieChart: CPTPieChart, record index: UInt) -> CPTFill {
        let color = Stats.colors[Int(index) % Stats.colors.count]
        return CPTFill(color: CPTColor(cgColor: color.cgColor))
    }
    
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        return UInt(self.tableData.sections.count)
    }
    
    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        return self.tableData.values[Int(idx)]
    }
    
    func hostingView(forDelegate: Stats, identifier: String) -> CPTGraphHostingView {
        let hostView = CPTGraphHostingView(frame: CGRect(x: 0, y: 0, width: 400, height: self.height))
        return hostView
    }
    
}
