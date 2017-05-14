//
//  SetSelectionViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 08.10.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

@objc(SetSelectionViewController) // needed for IASK
class SetSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var sections = [String]()
    private var values = [[Pack]]()
    
    private let coreSection = 1
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)

        let tableData = PackManager.allKnownPacksForSettings()
        self.sections = tableData.sections 
        self.values = tableData.values
        
        if self.values.count > 1 {
            // add "number of core sets" fake entry
            let numCores = Pack(named: "Number of Core Sets".localized(), key: DefaultsKeys.numCores._key)
            self.values[self.coreSection].insert(numCores, at: 1)
        }
    }
    
    func coresAlert(_ sender: UIButton) {
        let alert = UIAlertController(title: "Number of Core Sets".localized(), message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "1") { action in
            self.changeCoreSets(1)
        })
        alert.addAction(UIAlertAction(title: "2") { action in
            self.changeCoreSets(2)
        })
        alert.addAction(UIAlertAction(title: "3") { action in
            self.changeCoreSets(3)
        })
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        
        self.present(alert, animated: false, completion: nil)
    }
    
    func changeCoreSets(_ numCores: Int) {
        Defaults[.numCores] = numCores
        self.tableView.reloadData()
    }
    
    // MARK: table view
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.values[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "setCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? {
            let cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
            cell.selectionStyle = .none
            cell.accessoryType = .none
            return cell
        }()
        
        let pack = self.values[indexPath.section][indexPath.row]
        
        cell.textLabel?.text = pack.name
        cell.accessoryView = nil
        
        if pack.settingsKey == DefaultsKeys.numCores._key {
            let numCores = Defaults[.numCores]
            let button = UIButton(type: .system)
            button.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
            button.setTitle("\(numCores)", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFontWeightMedium)
            button.addTarget(self, action: #selector(self.coresAlert(_:)), for: .touchUpInside)
            cell.accessoryView = button
        } else {
            let settings = UserDefaults.standard
            let on = settings.bool(forKey: pack.settingsKey)
            let sw = NRSwitch(initial: on) { on in
                settings.set(on, forKey: pack.settingsKey)
                PackManager.clearDisabledPacks()
                tableView.reloadSections([indexPath.section], with: .none)
            }
            
            cell.accessoryView = sw
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let width = tableView.frame.width
        let view = UITableViewHeaderFooterView(frame: CGRect(x: 0, y: 0, width: width, height: 50))
        
        if self.values[section].count > 1 && section != self.coreSection {
            let cycle = self.values[section][0].cycleCode
            let keys = PackManager.keysForCycle(cycle)
            let enabledKeys = keys.filter { UserDefaults.standard.bool(forKey: $0) }
            
            let sw = NRSwitch(initial: enabledKeys.count > 0) { on in
                for key in keys {
                    UserDefaults.standard.set(on, forKey: key)
                }
                tableView.reloadSections([section], with: .none)
            }
            sw.frame = CGRect(x: width-66, y: 4, width: 51, height: 31)
            view.addSubview(sw)
        }
        
        return view
    }
    
}
