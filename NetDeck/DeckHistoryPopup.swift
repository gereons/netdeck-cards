//
//  DeckHistoryPopup.swift
//  NetDeck
//
//  Created by Gereon Steffens on 02.01.17.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import UIKit

class DeckHistoryPopup: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    private var deck: Deck!
    private var dateFormatter: DateFormatter!
    
    static func showFor(deck: Deck, in viewController: UIViewController) {
        let popup = DeckHistoryPopup(deck: deck)
        
        Analytics.logEvent(.deckHistory, attributes: ["Device": "iPad"])
        
        viewController.present(popup, animated: false, completion: nil)
    }
    
    convenience init(deck: Deck) {
        self.init()
        self.deck = deck
        self.modalPresentationStyle = .formSheet
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateStyle = .medium
        self.dateFormatter.timeStyle = .medium
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = "Editing History".localized()
        self.closeButton.setTitle("Done".localized(), for: .normal)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    @IBAction func closeButtonClicked(_ sender: UIButton) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @objc func revertTo(_ sender: UIButton) {
        assert(sender.tag < self.deck.revisions.count, "invalid tag")
        Analytics.logEvent(.revert)
        let dcs = self.deck.revisions[sender.tag]
        self.deck.resetToCards(dcs.cards)
        
        NotificationCenter.default.post(name: Notifications.deckChanged, object: self)
        self.dismiss(animated: false, completion: nil)
    }
    
    // MARK: - table view
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.deck.revisions.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dcs = self.deck.revisions[section]
        return dcs.initial ? 1 : dcs.changes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "historyCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? {
            let c = UITableViewCell(style: .default, reuseIdentifier: identifier)
            c.selectionStyle = .none
            return c
        }()
        
        cell.textLabel?.text = ""
        
        let dcs = self.deck.revisions[indexPath.section]
        if dcs.initial {
            cell.textLabel?.text = "Initial Version".localized()
        } else {
            let dc = dcs.changes[indexPath.row]
            cell.textLabel?.text = String(format: "%+ld %@", dc.count, dc.card.name)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = DeckHistorySectionHeaderView.initFromNib()
        
        let dcs = self.deck.revisions[section]
        header.dateLabel.text = self.dateFormatter.string(from: dcs.timestamp!)
        
        header.revertButton.setTitle("Revert".localized(), for: .normal)
        header.revertButton.tag = section
        header.revertButton.addTarget(self, action: #selector(self.revertTo(_:)), for: .touchUpInside)
        
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dcs = self.deck.revisions[indexPath.section]
        
        if !dcs.initial {
            let dc = dcs.changes[indexPath.row]
                
            let rect = self.tableView.rectForRow(at: indexPath)
            CardImageViewPopover.show(for: dc.card, from: rect, in: self, subView: self.tableView)
        }
    }
     
}
