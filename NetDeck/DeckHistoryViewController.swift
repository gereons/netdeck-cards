//
//  DeckHistoryViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 17.04.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit

class DeckHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var deck: Deck!
    var dateFormatter: NSDateFormatter = {
        let fmt = NSDateFormatter()
        fmt.dateStyle = .MediumStyle
        fmt.timeStyle = .MediumStyle
        return fmt
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Editing History".localized()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = UIColor.clearColor()
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)        
    }
    
    func revertTapped(sender: UIButton) {
        assert(sender.tag < self.deck.revisions.count, "invalid tag")
        
        let dcs = self.deck.revisions[sender.tag]
        // NSLog(@"revert to %d %@", sender.tag, [self.dateFormatter stringFromDate:dcs.timestamp]);
        
        if let cards = dcs.cards {
            self.deck.resetToCards(cards)
        
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.DECK_CHANGED, object:self)
            self.navigationController?.popViewControllerAnimated(true)
        }
    }

    // MARK: table view
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.deck.revisions.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dcs = self.deck.revisions[section]
        return dcs.initial ? 1 : dcs.changes.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "historyCell"
        
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
            cell?.selectionStyle = .None
        }
        cell?.textLabel?.text = ""
        
        let dcs = self.deck.revisions[indexPath.section]
        if dcs.initial {
            cell?.textLabel?.text = "Initial Version".localized()
        } else if indexPath.row < dcs.changes.count {
            let dc = dcs.changes[indexPath.row]
            cell?.textLabel?.text = String(format: "%+ld %@", dc.count, dc.card?.name ?? "")
        }
        
        return cell!
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = DeckHistorySectionHeaderView.initFromNib()
        
        let dcs = self.deck.revisions[section]
        header.dateLabel.text = self.dateFormatter.stringFromDate(dcs.timestamp!)
        
        header.revertButton.setTitle("Revert".localized(), forState: .Normal)
        header.revertButton.tag = section
        header.revertButton.addTarget(self, action: #selector(DeckHistoryViewController.revertTapped(_:)), forControlEvents: .TouchUpInside)
        
        return header
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let dcs = self.deck.revisions[indexPath.section]
        
        if !dcs.initial {
            if indexPath.row < dcs.changes.count {
                
                var ccs = [CardCounter]()
                for dc in dcs.changes {
                    if let card = dc.card {
                        let cc = CardCounter(card: card, andCount: dc.count)
                        ccs.append(cc)
                    }
                }
                assert(ccs.count == dcs.changes.count)
                if let selectedCard = dcs.changes[indexPath.row].card {
                
                    let imgController = CardImageViewController()
                    imgController.setCardCounters(ccs)
                    imgController.selectedCard = selectedCard
                    imgController.showAsDifferences = true
                    
                    self.navigationController?.pushViewController(imgController, animated: true)
                }
            }
        }
    }
}
