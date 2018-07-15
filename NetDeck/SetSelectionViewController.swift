//
//  SetSelectionViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 08.10.16.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
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
            let numCores = Pack(named: "Number of Core Sets".localized(), key: DefaultsKeys.numOriginalCore._key)
            self.values[self.coreSection].insert(numCores, at: 1)

            let numCore2s = Pack(named: "Number of Revised Core Sets".localized(), key: DefaultsKeys.numRevisedCore._key)
            self.values[self.coreSection].append(numCore2s)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Presets".localized(), style: .plain, target: self, action: #selector(self.showPresets(_:)))
    }
    
    @objc func showPresets(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "All".localized()) { action in
            self.enableAll()
        })
        alert.addAction(UIAlertAction(title: "Cache Refresh C&C".localized()) { action in
            self.setCacheRefresh(PackManager.creationAndControl)
        })
        alert.addAction(UIAlertAction(title: "Cache Refresh H&P".localized()) { action in
            self.setCacheRefresh(PackManager.honorAndProfit)
        })
        alert.addAction(UIAlertAction(title: "Cache Refresh O&C".localized()) { action in
            self.setCacheRefresh(PackManager.orderAndChaos)
        })
        alert.addAction(UIAlertAction(title: "Cache Refresh D&D".localized()) { action in
            self.setCacheRefresh(PackManager.dataAndDestiny)
        })
        alert.addAction(UIAlertAction(title: "Cache Refresh R&R".localized()) { action in
            self.setCacheRefresh(PackManager.reignAndReverie)
        })
        alert.addAction(UIAlertAction(title: "Modded".localized()) { action in
            self.setModded()
        })
        alert.addAction(UIAlertAction.actionSheetCancel(nil))

        let popover = alert.popoverPresentationController
        popover?.barButtonItem = sender
        popover?.sourceView = self.view
        alert.view.layoutIfNeeded()
        
        self.present(alert, animated: false, completion: nil)
    }
    
    @objc func coresAlert(_ sender: UIButton) {
        self.showCoresAlert(revised: false)
    }

    @objc func core2sAlert(_ sender: UIButton) {
        self.showCoresAlert(revised: true)
    }

    private func showCoresAlert(revised: Bool) {
        let title = revised ? "Number of Revised Core Sets" : "Number of Core Sets"
        let alert = UIAlertController(title: title.localized(), message: nil, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "0") { action in
            self.changeCoreSets(revised, 0)
        })
        alert.addAction(UIAlertAction(title: "1") { action in
            self.changeCoreSets(revised, 1)
        })
        alert.addAction(UIAlertAction(title: "2") { action in
            self.changeCoreSets(revised, 2)
        })
        alert.addAction(UIAlertAction(title: "3") { action in
            self.changeCoreSets(revised, 3)
        })
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))

        self.present(alert, animated: false, completion: nil)
    }
    
    private func changeCoreSets(_ revised: Bool, _ numCores: Int) {
        Defaults[revised ? .numRevisedCore : .numOriginalCore] = numCores

        if numCores == 0 {
            Defaults[revised ? .useCore2 : .useCore ] = false
        }
        self.tableView.reloadData()
    }
    
    private func enableAll() {
        self.changeCoreSets(true, 3)
        self.changeCoreSets(false, 3)
        
        for pack in PackManager.allPacks {
            Defaults.set(pack.released, forKey: pack.settingsKey)
        }
        
        if Defaults[.rotationActive] {
            self.changeCoreSets(false, 0)
            PackManager.rotatedPackKeys().forEach {
                Defaults.set(false, forKey: $0)
            }
        } else {
            self.changeCoreSets(true, 0)
            Defaults.set(false, forKey: DefaultsKeys.useCore2._key)
        }
        
        Defaults.set(false, forKey: Pack.use + PackManager.draft)
        
        self.tableView.reloadData()
    }

    private func setModded() {
        self.changeCoreSets(false, 0)
        self.changeCoreSets(true, 3)

        for pack in PackManager.allPacks {
            Defaults.set(false, forKey: pack.settingsKey)
        }

        if let cycle = PackManager.cacheRefreshCycles.first {
            let keys = PackManager.keysForCycle(cycle)
            for key in keys {
                let released = PackManager.allPacks.filter { $0.settingsKey == key }.first?.released ?? false
                Defaults.set(released, forKey: key)
            }
        }

        Defaults.set(false, forKey: Pack.use + PackManager.core)
        Defaults.set(false, forKey: Pack.use + PackManager.draft)
        Defaults.set(true, forKey: Pack.use + PackManager.core2)

        for box in PackManager.bigBoxes {
            Defaults.set(false, forKey: Pack.use + box)
        }

        self.tableView.reloadData()
    }
    
    private func setCacheRefresh(_ deluxe: String) {
        self.changeCoreSets(true, 1)
        self.changeCoreSets(false, 0)
        
        for pack in PackManager.allPacks {
            Defaults.set(false, forKey: pack.settingsKey)
        }
        
        for cycle in PackManager.cacheRefreshCycles {
            let keys = PackManager.keysForCycle(cycle)
            for key in keys {
                let released = PackManager.allPacks.filter { $0.settingsKey == key }.first?.released ?? false
                Defaults.set(released, forKey: key)
            }
        }

        Defaults.set(false, forKey: Pack.use + PackManager.core)
        Defaults.set(true, forKey: Pack.use + PackManager.core2)
        Defaults.set(true, forKey: Pack.use + PackManager.terminalDirective)
        Defaults.set(true, forKey: Pack.use + deluxe)
        Defaults.set(false, forKey: Pack.use + PackManager.draft)
        
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
        
        if pack.settingsKey == DefaultsKeys.numOriginalCore._key {
            let numCores = Defaults[.numOriginalCore]
            let button = UIButton(type: .system)
            button.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
            button.setTitle("\(numCores)", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)
            button.addTarget(self, action: #selector(self.coresAlert(_:)), for: .touchUpInside)
            cell.accessoryView = button
        } else if pack.settingsKey == DefaultsKeys.numRevisedCore._key {
            let numCores = Defaults[.numRevisedCore]
            let button = UIButton(type: .system)
            button.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
            button.setTitle("\(numCores)", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)
            button.addTarget(self, action: #selector(self.core2sAlert(_:)), for: .touchUpInside)
            cell.accessoryView = button
        } else {
            let on = Defaults.bool(forKey: pack.settingsKey)
            let sw = NRSwitch(initial: on) { on in
                self.toggleSetting(on, for: pack.settingsKey)
                tableView.reloadData()
            }
            
            cell.accessoryView = sw
        }
        
        return cell
    }
    
    func toggleSetting(_ value: Bool, for key: String) {
        let settings = UserDefaults.standard
        settings.set(value, forKey: key)

        if key == DefaultsKeys.useCore._key && value == true && Defaults[.numOriginalCore] == 0 {
            self.showCoresAlert(revised: false)
        }
        if key == DefaultsKeys.useCore2._key && value == true && Defaults[.numRevisedCore] == 0 {
            self.showCoresAlert(revised: true)
        }
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
