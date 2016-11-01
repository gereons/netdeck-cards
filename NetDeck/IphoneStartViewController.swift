//
//  IphoneStartViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.10.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class IphoneStartViewController: UINavigationController, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UISearchBarDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {

    @IBOutlet weak var tableViewController: UITableViewController!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var runnerDecks = [Deck]()
    private var corpDecks = [Deck]()
    private var decks = [[Deck]]()
    private var settings: SettingsViewController!
    private var addButton: UIBarButtonItem!
    private var importButton: UIBarButtonItem!
    private var settingsButton: UIBarButtonItem!
    private var sortButton: UIBarButtonItem!
    private var deckListSort = NRDeckListSort.byName
    private var filterText = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        self.title = "Net Deck"
        self.tableViewController.title = "Net Deck"
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.loadCards(_:)), name: Notifications.loadCards, object: nil)
        nc.addObserver(self, selector: #selector(self.importDeckFromClipboard(_:)), name: Notifications.importDeck, object: nil)
        
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = UIColor.clear
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        
        self.searchBar.delegate = self
        
        let cardsAvailable = CardManager.cardsAvailable
        self.addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.createNewDeck(_:)))
        self.addButton.isEnabled = cardsAvailable
        
        self.importButton = UIBarButtonItem(image: UIImage(named: "702-import"), style: .plain, target: self, action: #selector(self.importDecks(_:)))
        self.importButton.isEnabled = cardsAvailable
        
        self.settingsButton = UIBarButtonItem(image: UIImage(named: "740-gear"), style: .plain, target: self, action: #selector(self.openSettings(_:)))
        
        self.sortButton = UIBarButtonItem(image: UIImage(named: "890-sort-ascending-toolbar"), style: .plain, target: self, action: #selector(self.changeSort(_:)))
        
        let sort = UserDefaults.standard.integer(forKey: SettingsKeys.DECK_FILTER_SORT)
        self.deckListSort = NRDeckListSort(rawValue: sort) ?? .byName
        
        if cardsAvailable && PackManager.packsAvailable {
            self.initializeDecks()
        }
        
        self.tableView.contentInset = UIEdgeInsets.zero
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let _ = CardUpdateCheck.checkCardUpdateAvailable(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // this is my poor man's replacement for viewWillAppear - I can't figure out why this isn't called when this view is
    // back on top :(
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController != self.tableViewController {
            return
        }
        
        assert(navigationController.viewControllers.count == 1, "nav oops")
        if CardManager.cardsAvailable && PackManager.packsAvailable {
            self.initializeDecks()
        }
        
        self.tableView.reloadData()
        
        let topItem = self.navigationBar.topItem
        topItem?.leftBarButtonItems = [ self.settingsButton, self.sortButton ]
        topItem?.rightBarButtonItems = [ self.addButton, self.importButton ]
    }
    
    func initializeDecks() {
        self.runnerDecks = DeckManager.decksForRole(.runner)
        self.corpDecks = DeckManager.decksForRole(.corp)
        
        if self.filterText.length > 0 {
            let namePredicate = NSPredicate(format: "name CONTAINS[cd] %@", self.filterText)
            self.runnerDecks = self.runnerDecks.filter { namePredicate.evaluate(with: $0) }
            self.corpDecks = self.corpDecks.filter { namePredicate.evaluate(with: $0) }
        }
        
        if self.deckListSort == .byDate {
            self.runnerDecks = self.sortDecks(self.runnerDecks)
            self.corpDecks = self.sortDecks(self.corpDecks)
            self.decks = [ self.runnerDecks, self.corpDecks ]
        } else {
            var decks = self.runnerDecks
            decks.append(contentsOf: self.corpDecks)
            self.runnerDecks = self.sortDecks(decks)
            self.corpDecks.removeAll()
            self.decks = [ self.runnerDecks ]
        }
        
        let cardsAvailable = CardManager.cardsAvailable
        self.addButton.isEnabled = cardsAvailable
        self.importButton.isEnabled = cardsAvailable
        self.sortButton.isEnabled = cardsAvailable
        
        var allDecks = Array(self.runnerDecks)
        allDecks.append(contentsOf: self.corpDecks)
        
        NRDB.sharedInstance.updateDeckMap(allDecks)
    }
    
    func loadCards(_ notification: Notification) {
        self.initializeDecks()
        self.tableView.reloadData()
    }
    
    // MARK: - import deck

    func importDeckFromClipboard(_ notification: Notification) {
        guard let deck = notification.userInfo?["deck"] as? Deck else {
            return
        }
        
        deck.saveToDisk()
        
        let edit = EditDeckViewController()
        edit.deck = deck
        
        if self.viewControllers.count > 1 {
            self.popToRootViewController(animated: false)
        }
        self.pushViewController(edit, animated: true)
    }
    
    // MARK: - add new deck
    
    func createNewDeck(_ sender: Any) {
        self.createNewDeck()
    }
    
    func createNewDeck() {
        let alert = UIAlertController.actionSheet(withTitle: "New Deck".localized(), message: nil)
        
        alert.addAction(UIAlertAction(title: "New Runner Deck".localized()) { action in
            self.addNewDeck(.runner)
        })
        alert.addAction(UIAlertAction(title: "New Corp Deck".localized()) { action in
            self.addNewDeck(.corp)
        })
        alert.addAction(UIAlertAction(title: "Cancel".localized(), handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func addNewDeck(_ role: NRRole) {
        let idvc = IphoneIdentityViewController()
        idvc.role = role
        self.pushViewController(idvc, animated: true)
    }
    
    // MARK: - import
    
    func importDecks(_ sender: UIButton) {
        let settings = UserDefaults.standard
        let useNrdb = settings.bool(forKey: SettingsKeys.USE_NRDB)
        let useDropbox = settings.bool(forKey: SettingsKeys.USE_DROPBOX)
        
        if useNrdb && useDropbox {
            let alert = UIAlertController.alert(withTitle: "Import Decks".localized(), message:nil)
            
            alert.addAction(UIAlertAction(title: "From Dropbox".localized()) { action in
                self.importDecksFrom(.dropbox)
            })
            alert.addAction(UIAlertAction(title: "From NetrunnerDB.com".localized()) { action in
                self.importDecksFrom(.netrunnerDb)
            })
            
            alert.addAction(UIAlertAction(title: "Cancel".localized(), handler: nil))
            
            self.present(alert, animated:false, completion:nil)
        } else if useNrdb {
            self.importDecksFrom(.netrunnerDb)
        } else if useDropbox {
            self.importDecksFrom(.dropbox)
        } else {
            let alert = UIAlertController.alert(withTitle: "Import Decks".localized(),
                message: "Connect to your Dropbox and/or NetrunnerDB.com account first.".localized())
            
            alert.addAction(UIAlertAction(title: "OK".localized(), handler: nil))
            
            self.present(alert, animated:false, completion:nil)
        }
    }
    
    func importDecksFrom(_ importSource: NRImportSource) {
        let importVc = ImportDecksViewController()
        importVc.source = importSource.rawValue
        self.pushViewController(importVc, animated: true)
    }
    
    // MARK: - sort
    
    func changeSort(_ sender: UIBarButtonItem) {
        let alert = UIAlertController.alert(withTitle: "Sort by".localized(), message:nil)
        
        alert.addAction(UIAlertAction(title: "Date".localized()) { action in
            self.changeSortType(.byDate)
        })
        alert.addAction(UIAlertAction(title: "Faction".localized()) { action in
            self.changeSortType(.byFaction)
        })
        alert.addAction(UIAlertAction(title: "A-Z".localized()) { action in
            self.changeSortType(.byName)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(), handler: nil))
        
        self.present(alert, animated:false, completion:nil)
    }
    
    func changeSortType(_ sort: NRDeckListSort) {
        UserDefaults.standard.set(sort.rawValue, forKey: SettingsKeys.DECK_FILTER_SORT)
        self.deckListSort = sort
        
        self.initializeDecks()
        self.tableView.reloadData()
    }
    
    func sortDecks(_ decks: [Deck]) -> [Deck] {
        let result: [Deck]
        switch self.deckListSort {
        case .byName:
            result = decks.sorted { $1.name.lowercased() > $0.name.lowercased() }
        case .byDate:
            result = decks.sorted {
                let d1 = $0.lastModified ?? Date()
                let d2 = $1.lastModified ?? Date()
                if d1 == d2 {
                    return $1.name.lowercased() > $0.name.lowercased()
                } else {
                    return d1 > d2
                }
            }
        case .byFaction:
            result = decks.sorted {
                let faction1 = Faction.name(for: $0.identity?.faction ?? .none) ?? ""
                let faction2 = Faction.name(for: $1.identity?.faction ?? .none) ?? ""
                if faction1 == faction2 {
                    return $1.name.lowercased() > $0.name.lowercased()
                } else {
                    return faction1 > faction2
                }
            }
        }
        
        return result
    }
    
    // MARK: - settings
    
    func openSettings(_ sender: UIBarButtonItem) {
        self.settings = SettingsViewController()
        self.pushViewController(self.settings.iask, animated: true)
    }
    
    // MARK: - browser
    
    func titleButtonTapped(_ sender: UIBarButtonItem) {
        self.openBrowser()
    }
    
    func openBrowser() {
        let browser = BrowserViewController(nibName: "BrowserViewController", bundle: nil)
        self.pushViewController(browser, animated: true)
    }
    
    // MARK: - table view
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.decks.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.decks[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "deckCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? {
            let c = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
            c.selectionStyle = .none
            c.accessoryType = .disclosureIndicator
            return c
        }()
        
        let deck = self.decks[indexPath.section][indexPath.row]
        cell.textLabel?.text = deck.name
        
        if let identity = deck.identity {
            cell.detailTextLabel?.text = identity.name
            cell.detailTextLabel?.textColor = identity.factionColor
        } else {
            cell.detailTextLabel?.text = "No Identity".localized()
            cell.detailTextLabel?.textColor = UIColor.black
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let deck = self.decks[indexPath.section][indexPath.row]
        
        let edit = EditDeckViewController()
        edit.deck = deck
        
        self.pushViewController(edit, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.decks.count == 1 {
            return nil
        }
        return section == 0 ? "Runner".localized() : "Corp".localized()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            var decks = self.decks[indexPath.section]
            let deck = decks[indexPath.row]
            
            decks.remove(at: indexPath.row)
            NRDB.sharedInstance.deleteDeck(deck.netrunnerDbId)
            DeckManager.removeFile(deck.filename!)
            
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [ indexPath ], with: .left)
            self.tableView.endUpdates()
        }
    }
    
    // MARK: - search bar
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filterText = searchText
        self.initializeDecks()
        self.tableView.reloadData()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = false
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
    }

    // MARK: - empty dataset
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        if self.filterText.length > 0 {
            return nil
        }
        
        let attrs: [String: Any] = [ NSFontAttributeName: UIFont.systemFont(ofSize: 21.0), NSForegroundColorAttributeName: UIColor.lightGray ]
        
        let cardsAvailable = CardManager.cardsAvailable && PackManager.packsAvailable
        let title = cardsAvailable ? "No Decks" : "No Card Data"
        
        return NSAttributedString(string: title.localized(), attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        if self.filterText.length > 0 {
            return nil
        }
        
        let cardsAvailable = CardManager.cardsAvailable && PackManager.packsAvailable
        
        let text = cardsAvailable ? "Your decks will be shown here" : "To use this app, you must first download card data."
        
        let attrs: [String: Any] = [ NSFontAttributeName: UIFont.systemFont(ofSize: 14.0), NSForegroundColorAttributeName: UIColor.lightGray ]
        
        return NSAttributedString(string: text.localized(), attributes: attrs)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        if self.filterText.length > 0 {
            return nil
        }
        
        let color = self.tableView.tintColor ?? UIColor.blue
        let attrs: [String: Any] = [ NSFontAttributeName: UIFont.systemFont(ofSize: 17.0), NSForegroundColorAttributeName: color ]
        
        let cardsAvailable = CardManager.cardsAvailable && PackManager.packsAvailable
        let text = cardsAvailable ? "New Deck" : "Download"
        
        return NSAttributedString(string: text.localized(), attributes: attrs)
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        return UIColor(patternImage: ImageCache.hexTileLight)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        let cardsAvailable = CardManager.cardsAvailable && PackManager.packsAvailable
        if cardsAvailable {
            self.createNewDeck()
        } else {
            DataDownload.downloadCardData()
        }
    }
    
}
