//
//  CompareDecksList.swift
//  NetDeck
//
//  Created by Gereon Steffens on 03.01.17.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import UIKit

class CompareDecksList: DecksViewController {
    
    private var decksToDiff = [String]()
    private var names = [String]()
    private var diffButton: UIBarButtonItem!
    private var footerButton: UIBarButtonItem!
    private var selectedRole = Role.none
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.diffButton = UIBarButtonItem(title: "Compare".localized(), style: .plain, target: self, action: #selector(self.diffDecks(_:)))
        self.diffButton.isEnabled = false
        
        self.navigationItem.rightBarButtonItem = self.diffButton
        
        let title = "Select two decks to compare them".localized()
        self.footerButton = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(self.footerClicked(_:)))
        self.footerButton.tintColor = .label
        let fontName = [ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)]
        self.footerButton.setTitleTextAttributes(fontName, for: .normal)
        
        self.toolBar.items = [ self.footerButton ]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        var scrollTo: IndexPath?
        if self.decks.count > 0 && self.decks[0].count > 0 {
            scrollTo = IndexPath(row: 0, section: 0)
        } else if self.decks.count > 1 && self.decks[1].count > 0 {
            scrollTo = IndexPath(row: 0, section: 1)
        }

        if let top = scrollTo {
            self.tableView.scrollToRow(at: top, at: .top, animated: false)
        }
    }

    @objc func diffDecks(_ sender: UIBarButtonItem) {
        if self.popup != nil {
            return self.dismissPopup()
        }
        
        assert(self.decksToDiff.count == 2, "count must be 2")
        
        let d1 = DeckManager.loadDeckFromPath(self.decksToDiff[0])
        let d2 = DeckManager.loadDeckFromPath(self.decksToDiff[1])
        
        guard let deck1 = d1, let deck2 = d2 else {
            return
        }
        
        if deck1.role != deck2.role {
            UIAlertController.alert(withTitle: nil, message: "Both decks must be for the same side.".localized(), button: "OK".localized())
            return
        }
        
        DeckDiffViewController.showForDecks(deck1, deck2: deck2, inViewController: self)
    }
    
    @objc func footerClicked(_ sender: UIBarButtonItem) {
        if self.decksToDiff.count == 2 {
            self.diffDecks(sender)
        }
    }
    
    // MARK: - table view
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath) as! DeckCell
        
        let deck = self.decks[indexPath.section][indexPath.row]
        
        cell.infoButton?.isHidden = true
        cell.accessoryType = .none
        
        if self.decksToDiff.contains(deck.filename!) {
            cell.infoButton?.isHidden = false
            cell.infoButton?.isUserInteractionEnabled = false
            
            let img = UIImage(named: "888-checkmark-selected")?.withRenderingMode(.alwaysTemplate)
            cell.infoButton?.setImage(img, for: .normal)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let deck = self.decks[indexPath.section][indexPath.row]
        let filename = deck.filename!
        
        if self.selectedRole != deck.role {
            self.decksToDiff.removeAll()
            self.names.removeAll()
        }
        self.selectedRole = deck.role
        
        if let index = self.decksToDiff.firstIndex(of: filename) {
            self.decksToDiff.remove(at: index)
            
            for i in 0 ..< self.names.count {
                if self.names[i] == deck.name {
                    self.names.remove(at: i)
                    break
                }
            }
        } else {
            self.decksToDiff.append(filename)
            self.names.append(deck.name)
        }
        
        while self.decksToDiff.count > 2 {
            self.decksToDiff.remove(at: 0)
            self.names.remove(at: 0)
        }
        
        assert(self.decksToDiff.count == self.names.count, "count mismatch")
        self.diffButton.isEnabled = self.decksToDiff.count == 2
        
        switch self.decksToDiff.count {
        case 1:
            self.footerButton.title = String(format: "Selected ‘%@’, select one more to compare".localized(), self.names[0])
            self.footerButton.tintColor = .label
        case 2:
            self.footerButton.title = String(format: "Selected ‘%@’ and ‘%@’, tap to compare".localized(), self.names[0], self.names[1])
            self.footerButton.tintColor = self.diffButton.tintColor
        default:
            self.footerButton.title = "Select two decks to compare them".localized()
            self.footerButton.tintColor = .label
        }
        
        self.tableView.reloadData()
    }
}

// MARK: - Empty state
extension CompareDecksList {
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControl.State) -> NSAttributedString! {
        return nil
    }
    
}
