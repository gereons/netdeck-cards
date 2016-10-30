//
//  SetSelectionViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 08.10.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

@objc(SetSelectionViewController) // need for IASK
class SetSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var sections = [String]()
    var values = [[Pack]]()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        let tableData = PackManager.allKnownPacksForSettings()
        self.sections = tableData.sections as! [String]
        self.values = tableData.values as! [[Pack]]
        
        if self.values.count > 1 {
            // add "number of core sets" fake entry
            let numCores = Pack(named: "Number of Core Sets".localized(), key: SettingsKeys.NUM_CORES)
            self.values[1].insert(numCores, at: 1)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        UserDefaults.standard.set(numCores, forKey: SettingsKeys.NUM_CORES)
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
        
        let settings = UserDefaults.standard
        if pack.settingsKey == SettingsKeys.NUM_CORES {
            let numCores = settings.integer(forKey: SettingsKeys.NUM_CORES)
            let button = UIButton(type: .system)
            button.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
            button.setTitle("\(numCores)", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFontWeightMedium)
            button.addTarget(self, action: #selector(self.coresAlert(_:)), for: .touchUpInside)
            cell.accessoryView = button
        } else {
            let on = settings.bool(forKey: pack.settingsKey)
            let sw = NRSwitch(initial: on) { on in
                settings.set(on, forKey: pack.settingsKey)
                PackManager.clearDisabledPacks()
            }
            
            cell.accessoryView = sw
        }
        
        return cell
    }
}
