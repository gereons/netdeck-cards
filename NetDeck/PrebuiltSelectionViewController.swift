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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PrebuiltManager.allPrebuilts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier = "cellIdentifier"
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier) ?? {
            let c = UITableViewCell(style: .Default, reuseIdentifier: identifier)
            c.selectionStyle = .None
            return c
        }()
        
        let prebuilt = PrebuiltManager.allPrebuilts[indexPath.row]
        cell.textLabel?.text = prebuilt.name

        let settings = NSUserDefaults.standardUserDefaults()
        let sw = NRSwitch(handler: {
            PrebuiltManager.resetSelected()
            settings.setBool($0, forKey: prebuilt.settingsKey)
        })
        sw.on = settings.boolForKey(prebuilt.settingsKey)
        
        cell.accessoryView = sw
        
        return cell
    }
 
    // MARK: - empty state
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Please reload card data".localized())
    }
}
