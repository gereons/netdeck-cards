//
//  BrowserViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 09.04.16.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class BrowserViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var subtypeButton: UIButton!
    @IBOutlet weak var setButton: UIButton!
    @IBOutlet weak var factionButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    private var scopeButton: UIBarButtonItem!
    private var role = Role.none
    private var cardList: CardList!
    private var cards = [[Card]]()
    private var sections = [String]()
    
    // filter criteria
    private var searchText = ""
    private var searchScope = CardSearchScope.name
    private var types: FilterValue?
    private var subtypes: FilterValue?
    private var sets: FilterValue?
    private var factions: FilterValue?
    
    private var keyboardObserver: KeyboardObserver!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Browser".localized()
        Analytics.logEvent(.browser, attributes: [ "Device": "iPhone" ])
        
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.tableView.tableFooterView = UIView(frame:CGRect.zero)
        self.tableView.backgroundColor = .clear
        self.tableView.scrollFix()
        
        self.searchBar.scopeButtonTitles = [ "Both".localized(), "Runner".localized(), "Corp".localized() ]
        self.searchBar.showsCancelButton = false
        self.searchBar.showsScopeBar = true
        
        self.typeButton.setTitle("Type".localized(), for: .normal)
        self.subtypeButton.setTitle("Subtype".localized(), for: .normal)
        self.setButton.setTitle("Set".localized(), for: .normal)
        self.factionButton.setTitle("Faction".localized(), for: .normal)
        self.clearButton.setTitle("Clear".localized(), for: .normal)
        
        self.keyboardObserver = KeyboardObserver(handler: self)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress(_:)))
        self.tableView.addGestureRecognizer(longPress)

        let img = UIImage(named: "708-search-toolbar")?.withRenderingMode(.alwaysTemplate)
        self.scopeButton = UIBarButtonItem(image: img, style: .plain, target: self, action: #selector(self.scopeButtonTapped(_:)))
        
        self.navigationItem.rightBarButtonItem = self.scopeButton

        if self.traitCollection.forceTouchCapability == .available {
            self.registerForPreviewing(with: self, sourceView: self.view)
        }

        let packUsage = Defaults[.browserPacks]
        self.cardList = CardList(role: self.role, packUsage: packUsage, browser: true, legality: .casual)
        
        self.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let filtersActive = CardManager.cardsAvailable
        
        self.typeButton.isEnabled = filtersActive
        self.setButton.isEnabled = filtersActive
        self.factionButton.isEnabled = filtersActive
        self.clearButton.isEnabled = filtersActive
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func refresh() {
        self.cardList.clearFilters()
        if self.searchText.count > 0 {
            switch self.searchScope {
            case .all:
                self.cardList.filterByTextOrName(self.searchText)
            case .name:
                self.cardList.filterByName(self.searchText)
            case .text:
                self.cardList.filterByText(self.searchText)
            }
        }
        
        if let types = self.types {
            self.cardList.filterByType(types)
        }
        
        if let subtypes = self.subtypes {
            self.cardList.filterBySubtype(subtypes)
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
        let mwl = Defaults[.defaultMWL]

        cell.textLabel?.text = card.displayName(mwl)
    
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
    
        let penalty = card.mwlPenalty(mwl)
        pips.backgroundColor = penalty > 0 ? UIColor(rgb: 0xf5f5f5) : .white
         
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = self.cards[indexPath.section][indexPath.row]
        let imgView = self.imageViewControllerFor(card)
        self.navigationController?.pushViewController(imgView, animated:true)
    }

    fileprivate func imageViewControllerFor(_ card: Card, peeking: Bool = false) -> CardImageViewController {
        let imgView = CardImageViewController(peeking: peeking)

        // flatten our 2d cards array into a single list
        var cards = [Card]()
        for c in self.cards {
            cards.append(contentsOf: c)
        }
        imgView.setCards(cards, mwl: Defaults[.defaultMWL], deck: nil)
        imgView.selectedCard = card

        return imgView
    }
    
    // MARK: - search bar
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.role = Role(rawValue: selectedScope - 1)!

        let packUsage = Defaults[.browserPacks]
        self.cardList = CardList(role: self.role, packUsage: packUsage, browser: true, legality: .casual)
        self.refresh()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        self.refresh()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
        self.searchBar.setShowsCancelButton(false, animated: true)
    }
    
    // MARK: type, faction & set buttons
    @IBAction func typeButtonTapped(_ btn: UIButton) {
        let picker = BrowserValuePicker(title: "Type".localized())
        if self.role == .none {
            picker.data = CardType.allTypes
        } else {
            let types = CardType.typesFor(role: role)
            picker.data = TableData(values: types)
        }
        
        picker.preselected = self.types
        picker.setResult = { result in
            self.types = result
            self.subtypes = nil
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
    
    @IBAction func subtypeButtonTapped(_ btn: UIButton) {
        let picker = BrowserValuePicker(title: "Subtype".localized())
        
        let types = self.types?.strings ?? Set<String>()
        if self.role == .none {
            var runner = CardManager.subtypesFor(role: .runner, andTypes: types, includeIdentities: true)
            var corp = CardManager.subtypesFor(role: .corp, andTypes: types, includeIdentities: true)

            let common = Array(Set(runner).intersection(Set(corp))).sorted()
            common.forEach {
                if let index = runner.index(of: $0) {
                    runner.remove(at: index)
                }
                if let index = corp.index(of: $0) {
                    corp.remove(at: index)
                }
            }
            
            picker.data = TableData(sections: ["Both".localized(), "Runner".localized(), "Corp".localized()], values: [common, runner, corp])
        } else {
            let subtypes = CardManager.subtypesFor(role: self.role, andTypes: types, includeIdentities: true)
            picker.data = TableData(values: subtypes)
        }
        
        picker.preselected = self.subtypes
        picker.setResult = { result in
            self.subtypes = result
            self.refresh()
        }
        
        self.navigationController?.pushViewController(picker, animated: true)
    }
    
    @objc func scopeButtonTapped(_ btn: UIBarButtonItem) {
        let alert = UIAlertController(title: "Search in:".localized(), message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Name".localized().checked(self.searchScope == .name)) { action in
            self.searchScope = .name
            self.refresh()
        })
        alert.addAction(UIAlertAction(title: "Text".localized().checked(self.searchScope == .text)) { action in
            self.searchScope = .text
            self.refresh()
        })
        alert.addAction(UIAlertAction(title: "All".localized().checked(self.searchScope == .all)) { action in
            self.searchScope = .all
            self.refresh()
        })
        alert.addAction(UIAlertAction.alertCancel(nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: clear button
    
    @IBAction func clearButtonTapped(_ btn: UIButton) {
        self.sets = nil
        self.types = nil
        self.subtypes = nil
        self.factions = nil
        self.searchText = ""
        
        self.refresh()
    }

    // MARK: long press
    @objc func longPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: point) {
                let card = self.cards[indexPath.section][indexPath.row]
                
                let msg = String(format:"Open web page for\n%@?".localized(), card.name)
                
                let alert = UIAlertController.alert(title: nil, message: msg)
                alert.addAction(UIAlertAction(title:"NetrunnerDB".localized()) { action in
                    if let url = URL(string: card.nrdbLink) {
                        UIApplication.shared.open(url)
                    }
                })
                
                alert.addAction(UIAlertAction(title:"Cancel".localized(), style: .cancel, handler: nil))
                
                self.present(alert, animated:false, completion:nil)
            }
        }
    }
}

extension BrowserViewController: KeyboardHandling {
    // MARK: keyboard show/hide
    func keyboardWillShow(_ info: KeyboardInfo) {
        let kbHeight = info.endFrame.size.height
        
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

extension BrowserViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let imgViewController = viewControllerToCommit as? CardImageViewController {
            imgViewController.peeking = false
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
        let imgView = self.imageViewControllerFor(card, peeking: true)
        imgView.preferredContentSize = CGSize(width: 0, height: 436)

        previewingContext.sourceRect = self.tableView.convert(cell.frame, to: self.view) 

        return imgView
    }
}
