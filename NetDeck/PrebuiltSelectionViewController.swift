//
//  PrebuiltSelectionViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 26.08.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit

@objc(PrebuiltSelectionViewController) // need for IASK
class PrebuiltSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PrebuiltManager.allPrebuilts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cellIdentifier"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? {
            let c = UITableViewCell(style: .default, reuseIdentifier: identifier)
            c.selectionStyle = .none
            return c
        }()
        
        let prebuilt = PrebuiltManager.allPrebuilts[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = prebuilt.name

        let settings = UserDefaults.standard
        let sw = NRSwitch(handler: {
            PrebuiltManager.resetSelected()
            settings.set($0, forKey: prebuilt.settingsKey)
        })
        sw?.isOn = settings.bool(forKey: prebuilt.settingsKey)
        
        cell.accessoryView = sw
        
        return cell
    }
 
    // MARK: - empty state
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Please reload card data".localized())
    }
}
