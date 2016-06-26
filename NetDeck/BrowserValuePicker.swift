//
//  BrowserValuePicker.swift
//  NetDeck
//
//  Created by Gereon Steffens on 10.04.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit

class BrowserValuePicker: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var data: TableData!
    var selected = Set<NSIndexPath>()

    var preselected = Set<String>()
    var setResult: ((Set<String>) -> Void)!
    
    convenience init(title: String) {
        self.init()
        self.title = title
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = UIColor.clearColor()
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        for sec in 0 ..< data.sections.count {
            let packs = data.values[sec] as! [Pack]
            for row in 0 ..< packs.count {
                let pack = packs[row]
                if self.preselected.contains(pack.name) {
                    let idx = NSIndexPath(forRow: row, inSection: sec)
                    self.selected.insert(idx)
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let topItem = self.navigationController?.navigationBar.topItem {
            
            let clearButton = UIBarButtonItem(title: "Clear".localized(), style: .Plain, target: self, action: #selector(BrowserValuePicker.clearSelections(_:)))
            topItem.rightBarButtonItem = clearButton
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        var result = Set<String>()
        for idx in self.selected {
            let packs = self.data.values[idx.section] as! [Pack]
            let text = packs[idx.row].name
            result.insert(text)
        }
        
        self.setResult(result)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.data.sections.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.values[section].count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.data.sections[section] as? String
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "pickerCell"
        
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
            cell?.selectionStyle = .None
        }
        
        let packs = self.data.values[indexPath.section] as! [Pack]
        let pack = packs[indexPath.row]
        cell!.textLabel?.text = pack.name
        
        let sel = self.selected.contains(indexPath)
        cell?.accessoryType = sel ? .Checkmark : .None
    
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // special case for "Any", which is always at section 0, row 0
        let packs = self.data.values[indexPath.section] as! [Pack]
        let text = packs[indexPath.row].name
        if indexPath.section == 0 && indexPath.row == 0 && text == Constant.kANY {
            self.selected.removeAll()
            self.tableView.reloadData()
            return
        }
        
        let sel = selected.contains(indexPath)
        if !sel {
            selected.insert(indexPath)
        } else {
            selected.remove(indexPath)
        }
        
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            cell.accessoryType = sel ? .None : .Checkmark
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        }
    }
    
    func clearSelections(sender: UIBarButtonItem) {
        self.selected.removeAll()
        self.tableView.reloadData()
    }
}
