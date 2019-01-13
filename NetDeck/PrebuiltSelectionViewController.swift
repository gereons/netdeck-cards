//
//  PrebuiltSelectionViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 26.08.16.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import UIKit

@objc(PrebuiltSelectionViewController) // need for IASK
class PrebuiltSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Prebuilt.allPrebuilts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cellIdentifier"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? {
            let c = UITableViewCell(style: .default, reuseIdentifier: identifier)
            c.selectionStyle = .none
            return c
        }()
        
        let prebuilt = Prebuilt.allPrebuilts[indexPath.row]
        cell.textLabel?.text = prebuilt.name.localized()

        let settings = UserDefaults.standard
        let on = settings.bool(forKey: prebuilt.settingsKey)
        let sw = NRSwitch(initial: on) {
            settings.set($0, forKey: prebuilt.settingsKey)
            Prebuilt.initialize()
        }
        
        cell.accessoryView = sw
        
        return cell
    }
 
    // MARK: - empty state
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Please reload card data".localized())
    }
}
