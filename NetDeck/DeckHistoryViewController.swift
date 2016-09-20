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
    var deck: Deck?
    var dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .medium
        return fmt
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Editing History".localized()
        
        Analytics.logEvent("Deck History", attributes: ["Device": "iPhone"])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = UIColor.clear
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)        
    }
    
    func revertTapped(_ sender: UIButton) {
        guard let deck = self.deck else { return }
        
        assert(sender.tag < deck.revisions.count, "invalid tag")
        
        let dcs = deck.revisions[sender.tag]
        // NSLog(@"revert to %d %@", sender.tag, [self.dateFormatter stringFromDate:dcs.timestamp]);
        
        if let cards = dcs.cards {
            deck.resetToCards(cards)
        
            NotificationCenter.default.post(name: Notifications.deckChanged, object:self)
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }

    // MARK: table view
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.deck?.revisions.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let deck = self.deck else { return 0 }
        let dcs = deck.revisions[section]
        return dcs.initial ? 1 : dcs.changes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "historyCell"
        
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
            cell?.selectionStyle = .none
        }
        cell?.textLabel?.text = ""
        
        if let dcs = self.deck?.revisions[indexPath.section] {
            if dcs.initial {
                cell?.textLabel?.text = "Initial Version".localized()
            } else if indexPath.row < dcs.changes.count {
                let dc = dcs.changes[indexPath.row]
                cell?.textLabel?.text = String(format: "%+ld %@", dc.count, dc.card?.name ?? "")
            }
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = DeckHistorySectionHeaderView.initFromNib()
        
        if let dcs = self.deck?.revisions[section] {
            if let timestamp = dcs.timestamp {
                header.dateLabel.text = self.dateFormatter.string(from: timestamp as Date)
            } else {
                header.dateLabel.text = "n/a"
            }
        }
        
        header.revertButton.setTitle("Revert".localized(), for: UIControlState())
        header.revertButton.tag = section
        header.revertButton.addTarget(self, action: #selector(DeckHistoryViewController.revertTapped(_:)), for: .touchUpInside)
        
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let dcs = self.deck?.revisions[indexPath.section] else { return }
        
        if !dcs.initial {
            if indexPath.row < dcs.changes.count {
                
                var ccs = [CardCounter]()
                for dc in dcs.changes {
                    if let card = dc.card {
                        let cc = CardCounter(card: card, count: dc.count)
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
