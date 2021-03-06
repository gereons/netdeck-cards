//
//  SetSelectionViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 08.10.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
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

            if self.values[self.coreSection].count >= 3 {
                let numCore2s = Pack(named: "Number of Revised Core Sets".localized(), key: DefaultsKeys.numRevisedCore._key)
                self.values[self.coreSection].insert(numCore2s, at: 3)
            }

            if self.values[self.coreSection].count >= 5 {
                let numSC19s = Pack(named: "Number of System Core 2019 Sets".localized(), key: DefaultsKeys.numSC19._key)
                self.values[self.coreSection].insert(numSC19s, at: 5)
            }
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
        self.showCoresAlert(.useCore, .numOriginalCore)
    }

    @objc func core2sAlert(_ sender: UIButton) {
        self.showCoresAlert(.useCore2, .numRevisedCore)
    }

    @objc func coreSC19Alert(_ sender: UIButton) {
        self.showCoresAlert(.useSC19, .numSC19)
    }

    private func showCoresAlert(_ useKey: DefaultsKey<Bool>, _ numKey: DefaultsKey<Int>) {
        let titles = [
            DefaultsKeys.numOriginalCore._key: "Number of Core Sets",
            DefaultsKeys.numRevisedCore._key: "Number of Revised Core Sets",
            DefaultsKeys.numSC19._key: "Number of System Core 2019 Sets"
        ]
        guard let title = titles[numKey._key] else {
            return
        }

        let alert = UIAlertController(title: title.localized(), message: nil, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "0") { action in
            self.changeCoreSets(useKey, numKey, 0)
        })
        alert.addAction(UIAlertAction(title: "1") { action in
            self.changeCoreSets(useKey, numKey, 1)
        })
        alert.addAction(UIAlertAction(title: "2") { action in
            self.changeCoreSets(useKey, numKey, 2)
        })
        alert.addAction(UIAlertAction(title: "3") { action in
            self.changeCoreSets(useKey, numKey, 3)
        })
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))

        self.present(alert, animated: false, completion: nil)
    }
    
    private func changeCoreSets(_ useKey: DefaultsKey<Bool>, _ numKey: DefaultsKey<Int>, _ numCores: Int) {
        Defaults[numKey] = numCores

        if numCores == 0 {
            Defaults[useKey] = false
        }
        self.tableView.reloadData()
    }
    
    private func enableAll() {
        self.changeCoreSets(.useCore, .numOriginalCore, 3)
        self.changeCoreSets(.useCore2, .numRevisedCore, 3)
        self.changeCoreSets(.useSC19, .numSC19, 3)
        
        for pack in PackManager.allPacks {
            Defaults.set(pack.released, forKey: pack.settingsKey)
        }
        
        if Defaults[.rotationActive] {
            switch Defaults[.rotationIndex] {
            case RotationManager.r2017:
                self.changeCoreSets(.useCore, .numOriginalCore, 0)
                self.changeCoreSets(.useSC19, .numSC19, 0)
                Defaults[.useCore2] = true
            default:
                self.changeCoreSets(.useCore, .numOriginalCore, 0)
                self.changeCoreSets(.useCore2, .numRevisedCore, 0)
                Defaults[.useSC19] = true
            }
            PackManager.rotatedPackKeys().forEach {
                Defaults.set(false, forKey: $0)
            }
        } else {
            self.changeCoreSets(.useCore2, .numRevisedCore, 0)
            self.changeCoreSets(.useSC19, .numSC19, 0)
        }
        
        Defaults.set(false, forKey: Pack.use + PackManager.draft)
        Defaults.set(false, forKey: Pack.use + PackManager.uprisingBooster)
        Defaults.set(false, forKey: Pack.use + PackManager.magnumOpusReprint)
        Defaults.set(false, forKey: Pack.use + PackManager.napd)
        Defaults.set(false, forKey: Pack.use + PackManager.terminalDirectiveCampaign)
        
        self.tableView.reloadData()
    }

    private func setModded() {
        self.changeCoreSets(.useCore, .numOriginalCore, 0)
        self.changeCoreSets(.useCore2, .numRevisedCore, 0)
        self.changeCoreSets(.useSC19, .numSC19, 3)

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
        self.changeCoreSets(.useCore, .numOriginalCore, 0)
        self.changeCoreSets(.useCore2, .numRevisedCore, 0)
        self.changeCoreSets(.useSC19, .numSC19, 3)
        
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
        Defaults.set(false, forKey: Pack.use + PackManager.core2)
        Defaults.set(true, forKey: Pack.use + PackManager.sc19)
        Defaults.set(false, forKey: Pack.use + PackManager.terminalDirective)
        Defaults.set(false, forKey: Pack.use + PackManager.terminalDirectiveCampaign)
        Defaults.set(true, forKey: Pack.use + deluxe)
        Defaults.set(true, forKey: Pack.use + PackManager.reignAndReverie)
        Defaults.set(true, forKey: Pack.use + PackManager.magnumOpus)
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
            cell.accessoryView = self.makeCoreButton(Defaults[.numOriginalCore], #selector(self.coresAlert(_:)))
        } else if pack.settingsKey == DefaultsKeys.numRevisedCore._key {
            cell.accessoryView = self.makeCoreButton(Defaults[.numRevisedCore], #selector(self.core2sAlert(_:)))
        } else if pack.settingsKey == DefaultsKeys.numSC19._key {
            cell.accessoryView = self.makeCoreButton(Defaults[.numSC19], #selector(self.coreSC19Alert(_:)))
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

    private func makeCoreButton(_ number: Int, _ action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
        button.setTitle("\(number)", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    func toggleSetting(_ value: Bool, for key: String) {
        let settings = UserDefaults.standard
        settings.set(value, forKey: key)

        if key == DefaultsKeys.useCore._key && value == true && Defaults[.numOriginalCore] == 0 {
            self.showCoresAlert(.useCore, .numOriginalCore)
        }
        if key == DefaultsKeys.useCore2._key && value == true && Defaults[.numRevisedCore] == 0 {
            self.showCoresAlert(.useCore2, .numRevisedCore)
        }
        if key == DefaultsKeys.useSC19._key && value == true && Defaults[.numSC19] == 0 {
            self.showCoresAlert(.useSC19, .numSC19)
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
