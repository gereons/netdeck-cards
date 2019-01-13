//
//  BrowserValuePicker.swift
//  NetDeck
//
//  Created by Gereon Steffens on 10.04.16.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import UIKit

class BrowserValuePicker: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var data: TableData<String>!
    var selected = Set<IndexPath>()

    var preselected: FilterValue?
    var setResult: ((FilterValue) -> Void)!
    
    convenience init(title: String) {
        self.init()
        self.title = title
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = .clear
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let clearButton = UIBarButtonItem(title: "Clear".localized(), style: .plain, target: self, action: #selector(self.clearSelections(_:)))
        self.navigationItem.rightBarButtonItem = clearButton
        
        guard let preselectedSet = self.preselected?.strings else {
            return
        }
        
        for sec in 0 ..< data.sections.count {
            let strings = data.values[sec]
            for row in 0 ..< strings.count {
                let str = strings[row]
                if preselectedSet.contains(str) {
                    let idx = IndexPath(row: row, section: sec)
                    self.selected.insert(idx)
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        var result = Set<String>()
        for idx in self.selected {
            let strings = self.data.values[idx.section]
            let str = strings[idx.row]
            result.insert(str)
        }
        
        self.setResult(FilterValue.strings(result))
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.data.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.values[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.data.sections[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "pickerCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? {
            let cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
            cell.selectionStyle = .none
            return cell
        }()
        
        let str = self.data.values[indexPath.section][indexPath.row]
        let first = indexPath.section == 0 && indexPath.row == 0 // the "any" cell
        cell.textLabel?.text = first ? str.localized() : str
        
        let sel = self.selected.contains(indexPath)
        cell.accessoryType = sel ? .checkmark : .none
    
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // special case for "Any", which is always at section 0, row 0
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
    
    @objc func clearSelections(_ sender: UIBarButtonItem) {
        self.selected.removeAll()
        self.tableView.reloadData()
    }
}
