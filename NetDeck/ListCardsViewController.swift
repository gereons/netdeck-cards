//
//  ListCardsViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 17.12.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

final class ListCardsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var statusLabel: TickingLabel!
    
    @IBOutlet weak var toolBar: UIToolbar!
    
    private var keyboardObserver: KeyboardObserver!
    
    var deck: Deck!
    
    private var cards = [[Card]]()
    private var sections = [String]()
    private var cardList: CardList!
    private var filterText = ""
    private var searchScope = CardSearchScope.name
    
    private var filterViewController: FilterViewController!
    
    private let kSearchFieldValue = "searchField"
    private let kCancelButton = "cancelButton"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Cards".localized()
        
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = .clear
        
        self.statusLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: UIFont.Weight.regular)
        self.statusLabel.text = ""
        self.summaryLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: UIFont.Weight.regular)
        self.summaryLabel.text = ""
        
        // needed to make the 1 pixel separator show - wtf is this needed here but not elsewhere?
        self.view.bringSubviewToFront(self.toolBar)
        self.view.bringSubviewToFront(self.statusLabel)
        self.view.bringSubviewToFront(self.summaryLabel)
        
        self.tableView.register(UINib(nibName: "EditDeckCell", bundle: nil), forCellReuseIdentifier: "cardCell")
        
        let packUsage = Defaults[.deckbuilderPacks]
        self.cardList = CardList(role: self.deck.role, packUsage: packUsage, browser: false, legality: self.deck.legality)
        
        if let identity = self.deck.identity {
            if self.deck.role == .corp {
                self.cardList.preFilterForCorp(identity, self.deck.mwl)
            } else if self.deck.role == .runner {
                self.cardList.preFilterForRunner(identity, self.deck.mwl)
            }
        }
        
        self.keyboardObserver = KeyboardObserver(handler: self)
        
        if let textField = self.searchBar.value(forKey: kSearchFieldValue) as? UITextField {
            textField.returnKeyType = .done
        }
        
        self.tableView.scrollFix()

        if self.traitCollection.forceTouchCapability == .available {
            self.registerForPreviewing(with: self, sourceView: self.view)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let data = self.cardList.dataForTableView()
        self.sections = data.sections
        self.cards = data.values
        
        self.tableView.reloadData()
        self.updateFooter()
        
        let filterButton = UIBarButtonItem(image: UIImage(named: "798-filter-toolbar"), style: .plain, target: self, action: #selector(self.showFilters(_:)))
        let scopeButton = UIBarButtonItem(image: UIImage(named: "708-search-toolbar"), style: .plain, target: self, action: #selector(self.changeScope(_:)))
        
        self.navigationItem.rightBarButtonItems = [filterButton, scopeButton]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.tableView.flashScrollIndicators()
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            self.searchBar.text = ""
            self.filterText = ""
            self.cardList.clearFilters()
        }
    }
    
    @objc func showFilters(_ sender: UIBarButtonItem) {
        if self.filterViewController == nil {
            self.filterViewController = FilterViewController()
        }
        self.filterViewController.role = self.deck.role
        self.filterViewController.identity = self.deck.identity
        self.filterViewController.cardList = self.cardList
        
        if self.navigationController?.topViewController != self.filterViewController {
            self.navigationController?.pushViewController(self.filterViewController, animated: true)
        }
    }
    
    @objc func countChanged(_ stepper: UIStepper) {
        let section = stepper.tag / 1000
        let row = stepper.tag - (section * 1000)
        
        let card = self.cards[section][row]
        let cc = self.deck.findCard(card)
        let count = cc?.count ?? 0
        
        let copies = Int(stepper.value)
        let diff = copies - count
        self.deck.addCard(card, copies: diff)
        
        self.selectTextInSearchBar()
        self.tableView.reloadData()
        self.updateFooter()
    }
    
    func updateCards() {
        switch self.searchScope {
        case .name: self.cardList.filterByName(self.filterText)
        case .text: self.cardList.filterByText(self.filterText)
        case .all: self.cardList.filterByTextOrName(self.filterText)
        }
        
        let data = self.cardList.dataForTableView()
        self.sections = data.sections
        self.cards = data.values
        
        self.tableView.reloadData()
        self.updateFooter()
    }
    
    func updateFooter() {
        var summary = ""
        summary = String(format: "%ld %@", self.deck.size, self.deck.size == 1 ? "Card".localized() : "Cards".localized())
        let inf = self.deck.role == .corp ? "Inf".localized() : "Influence".localized()
        if self.deck.identity != nil && !self.deck.isDraft {
            summary += String(format: " · %ld/%ld %@", self.deck.influence, self.deck.influenceLimit, inf)
        } else {
            summary += String(format: " · %ld %@", self.deck.influence, inf)
        }
        
        if self.deck.role == .corp {
            summary += String(format: " · %ld %@", self.deck.agendaPoints, "AP".localized())
        }
        
        let reasons = self.deck.checkValidity()
        let status = reasons.first ?? "Deck is valid".localized()
        
        self.summaryLabel.text = summary
        self.summaryLabel.textColor = reasons.count == 0 ? .systemGray : .systemRed
            
        self.statusLabel.text = status
        self.statusLabel.strings = reasons
        self.statusLabel.textColor = reasons.count == 0 ? .systemGray : .systemRed
    }
    
    // MARK: - search bar
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filterText = searchText
        self.updateCards()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        if let button = searchBar.value(forKey: kCancelButton) as? UIButton {
            button.setTitle("Done".localized(), for: .normal)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.selectTextInSearchBar()
        
        if self.cards.count > 0 {
            if let card = self.cards.first?.first {
                self.deck.addCard(card, copies: 1)
                self.tableView.reloadData()
                
                self.updateFooter()
            }
        }
    }
    
    func selectTextInSearchBar() {
        if let textField = self.searchBar.value(forKey: kSearchFieldValue) as? UITextField {
            let range = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
            textField.selectedTextRange = range
        }
    }
    
    @objc func changeScope(_ btn: UIBarButtonItem) {
        let alert = UIAlertController(title: "Search in:".localized(), message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Name".localized().checked(self.searchScope == .name)) { action in
            self.searchScope = .name
            self.updateCards()
        })
        alert.addAction(UIAlertAction(title: "Text".localized().checked(self.searchScope == .text)) { action in
            self.searchScope = .text
            self.updateCards()
        })
        alert.addAction(UIAlertAction(title: "All".localized().checked(self.searchScope == .all)) { action in
            self.searchScope = .all
            self.updateCards()
        })
        alert.addAction(UIAlertAction.alertCancel(nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - tableview
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cards[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cardCell", for: indexPath) as! EditDeckCell
        
        cell.stepper.tag = indexPath.section * 1000 + indexPath.row
        cell.stepper.addTarget(self, action: #selector(self.countChanged(_:)), for: .valueChanged)
        
        let card = self.cards[indexPath.section][indexPath.row]
        let cardCounter = self.deck.findCard(card)
        
        cell.stepper.minimumValue = 0
        cell.stepper.maximumValue = Double(card.maxPerDeck)
        cell.stepper.value = Double(cardCounter?.count ?? 0)
        cell.stepper.isHidden = false
        cell.idButton.isHidden = true
        
        let weight: CGFloat
        let text: String
        if let cc = cardCounter {
            text = cc.displayName(self.deck.mwl)
            weight = UIFont.Weight.medium.rawValue
        } else {
            text = card.displayName(self.deck.mwl)
            weight = UIFont.Weight.regular.rawValue
        }
        cell.nameLabel.text = text
        cell.nameLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: UIFont.Weight(rawValue: weight))
        cell.nameLabel.textColor = card.owned == 0 ? .systemGray : .label

        let faction = Faction.name(for: card.faction)
        let subtype = card.subtype
        if subtype.count > 0 {
            let type = faction + " · " + subtype
            cell.typeLabel.text = type
        } else {
            cell.typeLabel.text = faction
        }
        
        let cc = cardCounter ?? CardCounter(card: card, count: 1)
        let influence = self.deck.influenceFor(cc)
        
        if influence > 0 {
            cell.influenceLabel.text = "\(influence)"
            cell.influenceLabel.textColor = card.factionColor
        } else {
            cell.influenceLabel.text = ""
        }
        
        cell.mwlLabel.text = ""
        let penalty = card.mwlPenalty(self.deck.mwl)
        let list = MWLManager.mwlBy(self.deck.mwl)
        if penalty > 0 && !list.universalInfluence {
            cell.mwlLabel.text = "\(min(-1, -cc.count * penalty))"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = self.cards[indexPath.section][indexPath.row]
        
        let img = CardImageViewController()
        img.setCards(self.cardList.allCards(), mwl: self.deck.mwl, deck: self.deck)
        img.selectedCard = card
        
        self.navigationController?.pushViewController(img, animated: true)
    }
}

extension ListCardsViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let imgController = viewControllerToCommit as? CardImageViewController {
            imgController.peeking = false
        }
        self.show(viewControllerToCommit, sender: self)
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let cellPosition = self.tableView.convert(location, from: self.view)
        guard
            let indexPath = self.tableView.indexPathForRow(at: cellPosition),
            let cell = tableView.cellForRow(at: indexPath)
        else {
            return nil
        }

        let card = self.cards[indexPath.section][indexPath.row]

        let imgController = CardImageViewController(peeking: true)
        imgController.setCards(self.cardList.allCards(), mwl: self.deck.mwl, deck: self.deck)
        imgController.selectedCard = card
        imgController.preferredContentSize = CGSize(width: 0, height: 436)

        previewingContext.sourceRect = self.tableView.convert(cell.frame, to: self.view)

        return imgController
    }
}

extension ListCardsViewController: KeyboardHandling {

    // MARK: - keyboard
    
    func keyboardWillShow(_ info: KeyboardInfo) {
        let screenHeight = UIScreen.main.bounds.size.height
        let kbHeight = screenHeight - info.endFrame.origin.y - self.toolBar.frame.size.height
        
        var inset = self.tableView.contentInset
        inset.bottom = kbHeight
        self.tableView.contentInset = inset
        self.tableView.scrollIndicatorInsets = inset
    }
    
    func keyboardWillHide(_ info: KeyboardInfo) {
        var inset = self.tableView.contentInset
        inset.bottom = 0
        self.tableView.contentInset = inset
        self.tableView.scrollIndicatorInsets = inset
    }
    
}
