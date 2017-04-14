//
//  BrowserViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 09.04.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class BrowserViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var setButton: UIButton!
    @IBOutlet weak var factionButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    private var role = Role.none
    private var cardList: CardList!
    private var cards = [[Card]]()
    private var sections = [String]()
    
    // filter criteria
    private var searchText = ""
    private var types: FilterValue?
    private var sets: FilterValue?
    private var factions: FilterValue?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Browser".localized()
        Analytics.logEvent(.browser, attributes: [ "Device": "iPhone" ])
        
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.tableView.tableFooterView = UIView(frame:CGRect.zero)
        self.tableView.backgroundColor = .clear
        
        self.searchBar.scopeButtonTitles = [ "Both".localized(), "Runner".localized(), "Corp".localized() ]
        self.searchBar.showsCancelButton = false
        self.searchBar.showsScopeBar = true
        
        self.typeButton.setTitle("Type".localized(), for: UIControlState())
        self.setButton.setTitle("Set".localized(), for: UIControlState())
        self.factionButton.setTitle("Faction".localized(), for: UIControlState())
        self.clearButton.setTitle("Clear".localized(), for: UIControlState())
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector:#selector(BrowserViewController.showKeyboard(_:)), name: Notification.Name.UIKeyboardWillShow, object:nil)
        nc.addObserver(self, selector:#selector(BrowserViewController.hideKeyboard(_:)), name: Notification.Name.UIKeyboardWillHide, object:nil)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress(_:)))
        self.tableView.addGestureRecognizer(longPress)

        self.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let filtersActive = CardManager.cardsAvailable && PackManager.packsAvailable
        
        self.typeButton.isEnabled = filtersActive
        self.setButton.isEnabled = filtersActive
        self.factionButton.isEnabled = filtersActive
        self.clearButton.isEnabled = filtersActive
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // NotificationCenter.default.removeObserver(self)
    }
    
    func refresh() {
        let packUsage = Defaults[.browserPacks]
        self.cardList = CardList.browserInitForRole(self.role, packUsage: packUsage)
        if self.searchText.length > 0 {
            self.cardList.filterByName(self.searchText)
        }
        
        if let types = self.types {
            self.cardList.filterByType(types)
        }
        
        if let sets = self.sets {
            self.cardList.filterBySet(sets)
        }
        
        if let factions = self.factions {
            self.cardList.filterByFaction(factions)
        }
        
        let data = self.cardList.dataForTableView()
        self.sections = data.sections
        self.cards = data.values
        
        self.tableView.reloadData()
    }
    
    // MARK: table view
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let arr = self.cards[section]
        return arr.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let arr = self.cards[section]
    
        return String(format:"%@ (%ld)", self.sections[section], arr.count)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "browserCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier:cellIdentifier)
            cell.selectionStyle = .none
            cell.accessoryType = .disclosureIndicator
            
            let pips = SmallPipsView.create()
            pips.layer.cornerRadius = 2
            pips.layer.masksToBounds = true
            cell.accessoryView = pips
            return cell
        }()
    
        let card = self.cards[indexPath.section][indexPath.row]
        cell.textLabel?.text = card.name
    
        switch card.type {
        
        case .identity:
            let inf = card.influenceLimit == -1 ? "∞" : "\(card.influenceLimit)"
            cell.detailTextLabel?.text = String(format: "%@ · %ld/%@", card.factionStr, card.minimumDecksize, inf)
        
        case .agenda:
            cell.detailTextLabel?.text = String(format: "%@ · %ld/%ld", card.factionStr, card.advancementCost, card.agendaPoints)
            
        default:
            cell.detailTextLabel?.text = String(format: "%@ · %l@ Cr", card.factionStr, card.costString)
        }
    
        let pips = cell.accessoryView as! SmallPipsView
        pips.set(value: card.influence, color: card.factionColor)
    
        let mwl = Defaults[.defaultMwl]
        let penalty = card.mwlPenalty(mwl)
        pips.backgroundColor = penalty > 0 ? UIColor(rgb: 0xf5f5f5) : .white
         
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = self.cards[indexPath.section][indexPath.row]
    
        let img = CardImageViewController()
    
        // flatten our 2d cards array into a single list
        var cards = [Card]()
        for c in self.cards {
            cards.append(contentsOf: c)
        }
        img.setCards(cards)
        img.selectedCard = card
    
        self.navigationController?.pushViewController(img, animated:true)
    }
    
    // MARK: - search bar
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.role = Role(rawValue: selectedScope - 1)!
        self.refresh()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        self.refresh()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = false
        self.searchBar.resignFirstResponder()
    }
    
    // MARK: type, factio & set buttons
    @IBAction func typeButtonTapped(_ btn: UIButton) {
        
        let picker = BrowserValuePicker(title: "Type".localized())
        if role == .none {
            picker.data = CardType.allTypes
        } else {
            let types = CardType.typesFor(role: role)
            picker.data = TableData(values: types)
        }
        
        picker.preselected = self.types
        picker.setResult = { result in
            self.types = result
            self.refresh()
        }
    
        self.navigationController?.pushViewController(picker, animated: true)
    }
    
    @IBAction func setButtonTapped(_ btn: UIButton) {
        let picker = BrowserValuePicker(title: "Set".localized())
        let packUsage = Defaults[.browserPacks]
        picker.data = PackManager.packsForTableView(packUsage: packUsage)
        picker.preselected = self.sets
        picker.setResult = { result in
            self.sets = result
            self.refresh()
        }
        
        self.navigationController?.pushViewController(picker, animated: true)
    }
    
    @IBAction func factionButtonTapped(_ btn: UIButton) {
        let packUsage = Defaults[.browserPacks]
        let picker = BrowserValuePicker(title: "Faction".localized())
        picker.data = Faction.factionsForBrowser(packUsage: packUsage)
        picker.preselected = self.factions
        picker.setResult = { result in
            self.factions = result
            self.refresh()
        }
        
        self.navigationController?.pushViewController(picker, animated: true)
    }
    
    // MARK: clear button
    
    @IBAction func clearButtonTapped(_ btn: UIButton) {
        self.sets = nil
        self.types = nil
        self.factions = nil
        self.searchText = ""
        
        self.refresh()
    }

    // MARK: keyboard show/hide
    func showKeyboard(_ notification: Notification) {
        guard let kbRect = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        let kbHeight = kbRect.cgRectValue.size.height
        
        var inset = self.tableView.contentInset
        inset.bottom = kbHeight
        self.tableView.contentInset = inset
        self.tableView.scrollIndicatorInsets = inset
    }
    
    func hideKeyboard(_ nta: Notification) {
        var inset = self.tableView.contentInset
        inset.bottom = 0
        self.tableView.contentInset = inset
        self.tableView.scrollIndicatorInsets = inset
    }
    
    // MARK: long press
    func longPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: point) {
                let card = self.cards[indexPath.section][indexPath.row]
                
                let msg = String(format:"Open web page for\n%@?".localized(), card.name)
                
                let alert = UIAlertController.alert(title: nil, message: msg)
                alert.addAction(UIAlertAction(title:"ANCUR".localized()) { action in
                    if let url = URL(string: card.ancurLink) {
                        UIApplication.shared.openURL(url)
                    }
                })
                alert.addAction(UIAlertAction(title:"NetrunnerDB".localized()) { action in
                    if let url = URL(string: card.nrdbLink) {
                        UIApplication.shared.openURL(url)
                    }
                })
                
                alert.addAction(UIAlertAction(title:"Cancel".localized(), style: .cancel, handler: nil))
                
                self.present(alert, animated:false, completion:nil)
            }
        }
    }
}

