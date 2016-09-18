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
    var selected = Set<IndexPath>()

    var preselected = Set<String>()
    var setResult: ((Set<String>) -> Void)!
    
    convenience init(title: String) {
        self.init()
        self.title = title
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = UIColor.clear
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        for sec in 0 ..< data.sections.count {
            let strings = data.values[sec] as! [String]
            for row in 0 ..< strings.count {
                let str = strings[row]
                if self.preselected.contains(str) {
                    let idx = IndexPath(row: row, section: sec)
                    self.selected.insert(idx)
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let topItem = self.navigationController?.navigationBar.topItem {
            
            let clearButton = UIBarButtonItem(title: "Clear".localized(), style: .plain, target: self, action: #selector(BrowserValuePicker.clearSelections(_:)))
            topItem.rightBarButtonItem = clearButton
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        var result = Set<String>()
        for idx in self.selected {
            let strings = self.data.values[(idx as NSIndexPath).section] as! [String]
            let str = strings[(idx as NSIndexPath).row]
            result.insert(str)
        }
        
        self.setResult(result)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.data.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let arr = self.data.values[section] as! NSArray
        return arr.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.data.sections[section] as? String
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "pickerCell"
        
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
            cell?.selectionStyle = .none
        }
        
        let strings = self.data.values[(indexPath as NSIndexPath).section] as! [String]
        let str = strings[(indexPath as NSIndexPath).row]
        let first = (indexPath as NSIndexPath).section == 0 && (indexPath as NSIndexPath).row == 0 // the "any" cell
        cell!.textLabel?.text = first ? str.localized() : str
        
        let sel = self.selected.contains(indexPath)
        cell?.accessoryType = sel ? .checkmark : .none
    
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // special case for "Any", which is always at section 0, row 0
        if (indexPath as NSIndexPath).section == 0 && (indexPath as NSIndexPath).row == 0 {
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
        
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = sel ? .none : .checkmark
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    func clearSelections(_ sender: UIBarButtonItem) {
        self.selected.removeAll()
        self.tableView.reloadData()
    }
}
