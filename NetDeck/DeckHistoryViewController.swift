//
//  DeckHistoryViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 17.04.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import UIKit

final class DeckHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var deck: Deck!
    var dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .medium
        return fmt
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Editing History".localized()
        self.tableView.scrollFix()
        
        Analytics.logEvent(.deckHistory, attributes: ["Device": "iPhone"])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = .clear
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.tableView.flashScrollIndicators()
    }
    
    @objc func revertTapped(_ sender: UIButton) {
        Analytics.logEvent(.revert)
        assert(sender.tag < deck.revisions.count, "invalid tag")
        
        let dcs = deck.revisions[sender.tag]
        // NSLog(@"revert to %d %@", sender.tag, [self.dateFormatter stringFromDate:dcs.timestamp]);
        
        deck.resetToCards(dcs.cards)
        
        NotificationCenter.default.post(name: Notifications.deckChanged, object:self)
        _ = self.navigationController?.popViewController(animated: true)
    }

    // MARK: table view
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.deck.revisions.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dcs = self.deck.revisions[section]
        return dcs.initial ? 1 : dcs.changes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "historyCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? {
            let cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
            cell.selectionStyle = .none
            return cell
        }()
        cell.textLabel?.text = ""
        
        let dcs = self.deck.revisions[indexPath.section]
        if dcs.initial {
            cell.textLabel?.text = "Initial Version".localized()
        } else if indexPath.row < dcs.changes.count {
            let dc = dcs.changes[indexPath.row]
            cell.textLabel?.text = String(format: "%+ld %@", dc.count, dc.card.name)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = DeckHistorySectionHeaderView.initFromNib()
        
        let dcs = self.deck.revisions[section]
        if let timestamp = dcs.timestamp {
            header.dateLabel.text = self.dateFormatter.string(from: timestamp as Date)
        } else {
            header.dateLabel.text = "n/a"
        }
        
        header.revertButton.setTitle("Revert".localized(), for: .normal)
        header.revertButton.tag = section
        header.revertButton.addTarget(self, action: #selector(DeckHistoryViewController.revertTapped(_:)), for: .touchUpInside)
        
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dcs = self.deck.revisions[indexPath.section]
        
        if !dcs.initial {
            if indexPath.row < dcs.changes.count {
                
                var ccs = [CardCounter]()
                for dc in dcs.changes {
                    if !dc.card.isNull {
                        let cc = CardCounter(card: dc.card, count: dc.count)
                        ccs.append(cc)
                    }
                }
                assert(ccs.count == dcs.changes.count)
                let selectedCard = dcs.changes[indexPath.row].card
                if !selectedCard.isNull {
                    let imgController = CardImageViewController()
                    imgController.setCardCounters(ccs, mwl: self.deck.mwl)
                    imgController.selectedCard = selectedCard
                    imgController.showAsDifferences = true
                    
                    self.navigationController?.pushViewController(imgController, animated: true)
                }
            }
        }
    }
}
