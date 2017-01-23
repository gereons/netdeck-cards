//
//  ListCardsViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 17.12.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

class ListCardsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var toolBar: UIToolbar!
    
    var deck: Deck!
    
    private var cards = [[Card]]()
    private var sections = [String]()
    private var cardList: CardList!
    private var filterText = ""
    
    private var filterViewController: FilterViewController!
    
    private let kSearchFieldValue = "searchField"
    private let kCancelButton = "cancelButton"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Cards".localized()
        
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = .clear
        
        self.statusLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: UIFontWeightRegular)
        self.statusLabel.text = ""
        
        // needed to make the 1 pixel separator show - wtf is this needed here but not elsewhere?
        self.view.bringSubview(toFront: self.toolBar)
        self.view.bringSubview(toFront: self.statusLabel)
        
        self.tableView.register(UINib(nibName: "EditDeckCell", bundle: nil), forCellReuseIdentifier: "cardCell")
        
        let packs = UserDefaults.standard.integer(forKey: SettingsKeys.DECKBUILDER_PACKS)
        let packUsage = NRPackUsage(rawValue: packs) ?? .all
        
        self.cardList = CardList(forRole: self.deck.role, packUsage: packUsage)
        
        if let identity = self.deck.identity {
            if self.deck.role == .corp {
                self.cardList.preFilterForCorp(identity)
            } else if self.deck.role == .runner {
                self.cardList.preFilterForRunner(identity)
            }
        }
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.showKeyboard(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        nc.addObserver(self, selector: #selector(self.hideKeyboard(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
    
        if let textField = self.searchBar.value(forKey: kSearchFieldValue) as? UITextField {
            textField.returnKeyType = .done
        }
        
        self.tableView.tableHeaderView = self.searchBar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let data = self.cardList.dataForTableView()
        self.sections = data.sections
        self.cards = data.values
        
        self.tableView.reloadData()
        self.updateFooter()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        assert(self.navigationController?.viewControllers.count == 3, "nav oops")
        
        if let topItem = self.navigationController?.navigationBar.topItem {
            let filterButton = UIBarButtonItem(image: UIImage(named: "798-filter-toolbar"), style: .plain, target: self, action: #selector(self.showFilters(_:)))
            
            topItem.rightBarButtonItem = filterButton
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParentViewController {
            self.searchBar.text = ""
            self.filterText = ""
            self.cardList.clearFilters()
        }
    }
    
    func showFilters(_ sender: UIBarButtonItem) {
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
    
    func countChanged(_ stepper: UIStepper) {
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
        self.cardList.filterByName(self.filterText)
        
        let data = self.cardList.dataForTableView()
        self.sections = data.sections
        self.cards = data.values
        
        self.tableView.reloadData()
        self.updateFooter()
    }
    
    func updateFooter() {
        var footer = ""
        footer = String(format: "%ld %@", self.deck.size, self.deck.size == 1 ? "Card".localized() : "Cards".localized())
        let inf = self.deck.role == .corp ? "Inf".localized() : "Influence".localized()
        if self.deck.identity != nil && !self.deck.isDraft {
            footer += String(format: " · %ld/%ld %@", self.deck.influence, self.deck.influenceLimit, inf)
        } else {
            footer += String(format: " · %ld %@", self.deck.influence, inf)
        }
        
        if self.deck.role == .corp {
            footer += String(format: " · %ld %@", self.deck.agendaPoints, "AP".localized())
        }
        
        footer += "\n"
        
        let reasons = self.deck.checkValidity()
        if reasons.count > 0 {
            footer += reasons[0]
        }
        
        self.statusLabel.text = footer
        self.statusLabel.textColor = reasons.count == 0 ? .darkGray : .red
    }
    
    // MARK: - search bar
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filterText = searchText
        self.updateCards()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
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
        let cc = self.deck.findCard(card)
        
        cell.stepper.minimumValue = 0
        cell.stepper.maximumValue = Double(card.maxPerDeck)
        cell.stepper.value = Double(cc?.count ?? 0)
        cell.stepper.isHidden = false
        cell.idButton.isHidden = true
        
        let weight: CGFloat
        var text = ""
        if let cc = cc {
            text = String(format: "%lu× %@", cc.count, card.name)
            weight = UIFontWeightMedium
        } else {
            text = String(format: "%@", card.name)
            weight = UIFontWeightRegular
        }
        if card.unique {
            text += " •"
        }
        cell.nameLabel.text = text
        cell.nameLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: weight)
        
        var influence = self.deck.influenceFor(cc)
        
        if cc?.count == 0 && self.deck.identity?.faction != card.faction {
            influence = card.influence
        }
        
        if influence > 0 {
            cell.influenceLabel.text = "\(influence)"
            cell.influenceLabel.textColor = card.factionColor
        } else {
            cell.influenceLabel.text = ""
        }
        
        let mwl = card.isMostWanted(self.deck.mwl)
        if mwl {
            cell.mwlLabel.text = "\(min(-1, -(cc?.count ?? 0)))"
        }
        cell.mwlLabel.isHidden = !mwl
        
        let faction = Faction.name(for: card.faction)
        let subtype = card.subtype
        if subtype.length > 0 {
            let type = faction + " · " + subtype
            cell.typeLabel.text = type
        } else {
            cell.typeLabel.text = faction
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = self.cards[indexPath.section][indexPath.row]
        
        let img = CardImageViewController()
        img.setCards(self.cardList.allCards())
        img.selectedCard = card
        
        self.navigationController?.pushViewController(img, animated: true)
    }
    
    // MARK: - keyboard
    
    func showKeyboard(_ notification: Notification) {
        guard let kbRect = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        let screenHeight = UIScreen.main.bounds.size.height
        let kbHeight = screenHeight - kbRect.cgRectValue.origin.y - self.toolBar.frame.size.height
        
        var inset = self.tableView.contentInset
        inset.bottom = kbHeight
        self.tableView.contentInset = inset
        self.tableView.scrollIndicatorInsets = inset
    }
    
    func hideKeyboard(_ notification: Notification) {
        var inset = self.tableView.contentInset
        inset.bottom = 0
        self.tableView.contentInset = inset
        self.tableView.scrollIndicatorInsets = inset
    }
    
}
