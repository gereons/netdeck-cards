//
//  DecksViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.01.17.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class DecksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var toolBarHeight: NSLayoutConstraint!

    var stateFilterButton: UIBarButtonItem!
    var sideFilterButton: UIBarButtonItem!
    var sortButton: UIBarButtonItem!

    var popup: UIAlertController!
    var decks = [[Deck]]()

    var filterText = ""
    
//    private var runnerDecks = [Deck]()
//    private var corpDecks = [Deck]()
    private var dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .medium
        return fmt
    }()
    
    var searchScope = DeckSearchScope.all
    
    // filterState, sortType and filterType look like normal properties, but are backed
    // by statics so that whenever we switch between views of subclasses, the filters
    // remain intact
    private static var _filterState = DeckState.none
    private static var _sortType = DeckListSort.byName
    private static var _filterType = Filter.all
    var filterState: DeckState {
        get { return DecksViewController._filterState }
        set { DecksViewController._filterState = newValue }
    }
    var sortType: DeckListSort {
        get { return DecksViewController._sortType }
        set { DecksViewController._sortType = newValue }
    }
    var filterType: Filter {
        get { return DecksViewController._filterType }
        set { DecksViewController._filterType = newValue }
    }
    
    private var sortStr: [DeckListSort: String] = [
        .byDate: "Date".localized(),
        .byFaction: "Faction".localized(),
        .byName: "A-Z".localized()
    ]
    private var sideStr: [Filter: String] = [
        .all: "Both".localized(),
        .runner: "Runner".localized(),
        .corp: "Corp".localized()
    ]

    convenience init() {
        self.init(nibName: "DecksViewController", bundle: nil)
    }
    
    convenience init(card: Card) {
        self.init()
        self.filterText = card.name
        self.searchScope = card.type == .identity ? .identity : .card
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.parent?.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        
        self.navigationController?.navigationBar.barTintColor = .white
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Decks".localized(), style: .plain, target: nil, action: nil)
        
        let arrow = DeckState.arrow
        self.sortButton = UIBarButtonItem(title: self.sortStr[self.sortType]! + arrow, style: .plain, target: self, action: #selector(self.changeSort(_:)))
        self.sortButton.possibleTitles = Set<String>(self.sortStr.values.map { $0 + arrow })
        
        self.sideFilterButton = UIBarButtonItem(title: self.sideStr[self.filterType]! + arrow, style: .plain, target: self, action: #selector(self.changeSideFilter(_:)))
        self.sideFilterButton.possibleTitles = Set<String>(self.sideStr.values.map { $0 + arrow })
        
        self.stateFilterButton = UIBarButtonItem(title: DeckState.buttonLabelFor(self.filterState), style: .plain, target: self, action: #selector(self.changeStateFilter(_:)))
        self.stateFilterButton.possibleTitles = Set<String>(DeckState.possibleTitles())
        
        let topItem = self.navigationController?.navigationBar.topItem
        topItem?.leftBarButtonItems = [ self.sortButton, self.sideFilterButton, self.stateFilterButton ]
        
        self.searchBar.placeholder = "Search for decks, identities or cards".localized()
        if self.filterText.length > 0 {
            self.searchBar.text = self.filterText
        }
        
        self.searchBar.scopeButtonTitles = [ "All".localized(), "Name".localized(), "Identity".localized(), "Card".localized()]
        self.searchBar.showsScopeBar = false
        self.searchBar.showsCancelButton = false
        self.searchBar.selectedScopeButtonIndex = self.searchScope.rawValue
        self.searchBar.sizeToFit()
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = .clear
        self.tableView.rowHeight = 44
        self.tableView.register(UINib(nibName: "DeckCell", bundle: nil), forCellReuseIdentifier: "deckCell")
        self.tableView.contentOffset = CGPoint(x: 0, y: self.searchBar.frame.size.height)
        
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let settings = UserDefaults.standard
        self.filterType = Filter(rawValue: settings.integer(forKey: SettingsKeys.DECK_FILTER_TYPE)) ?? .all
        self.sideFilterButton.title = sideStr[self.filterType]! + DeckState.arrow
        
        self.filterState = DeckState(rawValue: settings.integer(forKey: SettingsKeys.DECK_FILTER_STATE)) ?? .none
        self.stateFilterButton.title = DeckState.buttonLabelFor(self.filterState)
        
        self.sortType = DeckListSort(rawValue: settings.integer(forKey: SettingsKeys.DECK_FILTER_SORT)) ?? .byName
        self.sortButton.title = sortStr[self.sortType]! + DeckState.arrow
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.willShowKeyboard(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        nc.addObserver(self, selector: #selector(self.willHideKeyboard(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        self.updateDecks()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        let settings = UserDefaults.standard
        settings.set(self.filterType.rawValue, forKey: SettingsKeys.DECK_FILTER_TYPE)
        settings.set(self.filterState.rawValue, forKey: SettingsKeys.DECK_FILTER_STATE)
        settings.set(self.sortType.rawValue, forKey: SettingsKeys.DECK_FILTER_SORT)
    }
    
    func dismissPopup() {
        self.popup.dismiss(animated: false, completion: nil)
        self.popup = nil
    }
    
    func changeSort(_ sender: UIBarButtonItem) {
        if self.popup != nil {
            return self.dismissPopup()
        }
        
        self.popup = UIAlertController.actionSheet(title: "Sort by".localized(), message: nil)
        self.popup.addAction(UIAlertAction(title: "Date".localized()) { action in
            self.changeSortType(.byDate)
        })
        self.popup.addAction(UIAlertAction(title: "Faction".localized()) { action in
            self.changeSortType(.byFaction)
        })
        self.popup.addAction(UIAlertAction(title: "A-Z".localized()) { action in
            self.changeSortType(.byName)
        })
        self.popup.addAction(UIAlertAction.actionSheetCancel() { action in
            self.popup = nil
        })
        
        let popover = self.popup.popoverPresentationController
        popover?.barButtonItem = sender
        popover?.sourceView = self.view
        popover?.permittedArrowDirections = .any
        self.popup.view.layoutIfNeeded()
        
        self.present(self.popup, animated: false, completion: nil)
    }
    
    func changeSortType(_ type: DeckListSort) {
        self.sortType = type
        self.popup = nil
        self.updateDecks()
    }
    
    func changeSideFilter(_ sender: UIBarButtonItem) {
        if self.popup != nil {
            return self.dismissPopup()
        }
        
        self.popup = UIAlertController.actionSheet(title: "Show Side".localized(), message: nil)
        self.popup.addAction(UIAlertAction(title: "Both".localized()) { action in
            self.changeSide(.all)
        })
        self.popup.addAction(UIAlertAction(title: "Runner".localized()) { action in
            self.changeSide(.runner)
        })
        self.popup.addAction(UIAlertAction(title: "Corp".localized()) { action in
            self.changeSide(.corp)
        })
        self.popup.addAction(UIAlertAction.actionSheetCancel() { action in
            self.popup = nil
        })
        
        let popover = self.popup.popoverPresentationController
        popover?.barButtonItem = sender
        popover?.sourceView = self.view
        popover?.permittedArrowDirections = .any
        self.popup.view.layoutIfNeeded()
        
        self.present(self.popup, animated: false, completion: nil)
    }
    
    func changeSide(_ type: Filter) {
        self.filterType = type
        self.popup = nil
        self.updateDecks()
    }
    
    func changeStateFilter(_ sender: UIBarButtonItem) {
        if self.popup != nil {
            return self.dismissPopup()
        }
        
        self.popup = UIAlertController.actionSheet(title: "Show Status".localized(), message: nil)
        self.popup.addAction(UIAlertAction(title: "All".localized()) { action in
            self.changeState(.none)
        })
        self.popup.addAction(UIAlertAction(title: "Active".localized()) { action in
            self.changeState(.active)
        })
        self.popup.addAction(UIAlertAction(title: "Testing".localized()) { action in
            self.changeState(.testing)
        })
        self.popup.addAction(UIAlertAction(title: "Retired".localized()) { action in
            self.changeState(.retired)
        })
        self.popup.addAction(UIAlertAction.actionSheetCancel() { action in
            self.popup = nil
        })
        
        let popover = self.popup.popoverPresentationController
        popover?.barButtonItem = sender
        popover?.sourceView = self.view
        popover?.permittedArrowDirections = .any
        self.popup.view.layoutIfNeeded()
        
        self.present(self.popup, animated: false, completion: nil)
    }
    
    func changeState(_ state: DeckState) {
        self.filterState = state
        self.popup = nil
        self.updateDecks()
    }
    
    func updateDecks() {
        self.sortButton.title = sortStr[self.sortType]! + DeckState.arrow
        self.sideFilterButton.title = sideStr[self.filterType]! + DeckState.arrow
        self.stateFilterButton.title = DeckState.buttonLabelFor(self.filterState)
        
        var runnerDecks = self.filterType != .corp ? DeckManager.decksForRole(.runner) : []
        var corpDecks = self.filterType != .runner ? DeckManager.decksForRole(.corp) : []
        if BuildConfig.debug {
            self.checkDecks(decks: runnerDecks)
            self.checkDecks(decks: corpDecks)
        }
        
        let allDecks = runnerDecks + corpDecks
        NRDB.sharedInstance.updateDeckMap(allDecks)
        
        if self.sortType != .byDate {
            runnerDecks = self.sortDecks(runnerDecks)
            corpDecks = self.sortDecks(corpDecks)
        } else {
            runnerDecks = self.sortDecks(runnerDecks + corpDecks)
            corpDecks.removeAll()
        }
        
        if self.filterText.length > 0 {
            let namePredicate = NSPredicate(format: "name CONTAINS[cd] %@", self.filterText)
            let identityPredicate = NSPredicate(format: "(identity.name CONTAINS[cd] %@) or (identity.englishName CONTAINS[cd] %@)", self.filterText, self.filterText)
            let cardPredicate = NSPredicate(format: "(ANY cards.card.name CONTAINS[cd] %@) OR (ANY cards.card.englishName CONTAINS[cd] %@)", self.filterText, self.filterText)
            
            let predicate: NSPredicate
            switch (self.searchScope) {
            case .all: predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [namePredicate, identityPredicate, cardPredicate])
            case .name: predicate = namePredicate
            case .identity: predicate = identityPredicate
            case .card: predicate = cardPredicate
            }
            
            runnerDecks = runnerDecks.filter { predicate.evaluate(with: $0) }
            corpDecks = corpDecks.filter { predicate.evaluate(with: $0) }
        }
        
        if self.filterState != .none {
            let predicate = NSPredicate(format: "state == %d", self.filterState.rawValue)
            runnerDecks = runnerDecks.filter { predicate.evaluate(with: $0) }
            corpDecks = corpDecks.filter { predicate.evaluate(with: $0) }
        }
        
        self.decks = [ runnerDecks, corpDecks ]
        
        self.tableView.reloadData()
    }
    
    func checkDecks(decks: [Deck]) {
        for deck in decks {
            if let identity = deck.identity {
                assert(deck.role == identity.role, "role mismatch")
            }
        }
    }
    
    func sortDecks(_ decks: [Deck]) -> [Deck] {
        switch self.sortType {
        case .byName:
            return decks.sorted { deck1, deck2 in
                deck1.name.lowercased() < deck2.name.lowercased()
            }
        case .byDate:
            return decks.sorted { deck1, deck2 in
                guard let m1 = deck1.lastModified, let m2 = deck2.lastModified else {
                    return deck1.name.lowercased() < deck2.name.lowercased()
                }
                if m1 == m2 {
                    return deck1.name.lowercased() < deck2.name.lowercased()
                }
                return m1 > m2
            }
        case .byFaction:
            return decks.sorted { deck1, deck2 in
                let f1 = Faction.name(for: deck1.identity?.faction ?? .none)
                let f2 = Faction.name(for: deck2.identity?.faction ?? .none)
                if f1 == f2 {
                    let id1 = deck1.identity?.name.lowercased() ?? ""
                    let id2 = deck2.identity?.name.lowercased() ?? ""
                    
                    if id1 == id2 {
                        return deck1.name.lowercased() < deck2.name.lowercased()
                    }
                    return id1 < id2
                }
                return f1 < f2
            }
        }
    }
    
    // MARK: - search bar
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filterText = searchText
        self.updateDecks()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.searchScope = DeckSearchScope(rawValue: selectedScope) ?? .all
        self.updateDecks()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.showsScopeBar = false
        searchBar.sizeToFit()
        self.tableView.tableHeaderView = self.searchBar
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
        searchBar.showsScopeBar = true
        searchBar.sizeToFit()
        self.tableView.tableHeaderView = self.searchBar
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - table view
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "deckCell", for: indexPath) as! DeckCell
        let deck = self.decks[indexPath.section][indexPath.row]
        
        cell.nameLabel.text = deck.name
        
        if let identity = deck.identity {
            cell.identityLabel.text = identity.name
            cell.identityLabel.textColor = identity.factionColor
        } else {
            cell.identityLabel.text = "No Identity".localized()
            cell.identityLabel.textColor = .darkGray
        }
        
        let summary: String
        if deck.role == .runner {
            summary = String(format: "%d Cards · %d Influence".localized(), deck.size, deck.influence)
        } else {
            summary = String(format: "%d Cards · %d Influence · %d AP".localized(), deck.size, deck.influence, deck.agendaPoints)
        }
        cell.summaryLabel?.text = summary
        
        let valid = deck.checkValidity().count == 0
        cell.summaryLabel?.textColor = valid ? .black : .red
        
        let state = DeckState.labelFor(deck.state)
        let date = self.dateFormatter.string(from: deck.lastModified ?? Date())
        cell.dateLabel.text = state + " · " + date
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.decks[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.decks.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.sortType == .byDate {
            return nil
        }
        switch section {
        case 0: return self.decks[0].count > 0 ? "Runner".localized() : nil
        case 1: return self.decks[1].count > 0 ? "Corp".localized() : nil
        default: return nil
        }
    }
    
    // MARK: - keyboard show/hide
    
    func willShowKeyboard(_ notification: Notification) {
        guard let kbRect = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        let screenHeight = UIScreen.main.bounds.size.height
        let kbHeight = screenHeight - kbRect.cgRectValue.origin.y
        
        let contentInsets = UIEdgeInsets(top: 64, left: 0, bottom: kbHeight, right: 0)
        self.tableView.contentInset = contentInsets
        self.tableView.scrollIndicatorInsets = contentInsets
    }
    
    func willHideKeyboard(_ notification: Notification) {
        let contentInsets = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        self.tableView.contentInset = contentInsets
        self.tableView.scrollIndicatorInsets = contentInsets
    }
    
    // MARK: - empty dataset
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        if self.filterText.length > 0 {
            return nil
        }
        
        let attributes = [
            NSFontAttributeName: UIFont.systemFont(ofSize: 21),
            NSForegroundColorAttributeName: UIColor.lightGray
        ]
        return NSAttributedString(string: "No Decks".localized(), attributes: attributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        if self.filterText.length > 0 {
            return nil
        }
        let attributes = [
            NSFontAttributeName: UIFont.systemFont(ofSize: 14),
            NSForegroundColorAttributeName: UIColor.lightGray
        ]
        return NSAttributedString(string: "Your decks will be shown here".localized(), attributes: attributes)
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        return UIColor(patternImage: ImageCache.hexTileLight)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -64
    }

}

