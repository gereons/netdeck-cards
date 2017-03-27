//
//  IphoneStartViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.10.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import SwiftyUserDefaults

class IphoneStartViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, StartViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
//    private var runnerDecks = [Deck]()
//    private var corpDecks = [Deck]()
    private var decks = [[Deck]]()
    
    private var addButton: UIBarButtonItem!
    private var importButton: UIBarButtonItem!
    private var settingsButton: UIBarButtonItem!
    private var sortButton: UIBarButtonItem!
    private var titleButton: UIButton!
    
    private var deckListSort = DeckListSort.byName
    private var filterText = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Net Deck"
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.loadCards(_:)), name: Notifications.loadCards, object: nil)
        nc.addObserver(self, selector: #selector(self.importDeckFromClipboard(_:)), name: Notifications.importDeck, object: nil)
        
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = .clear
        
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
        
        self.titleButton = UIButton(type: .system)
        self.titleButton.setTitle("Net Deck", for: .normal)
        self.titleButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFontWeightMedium)
        self.titleButton.addTarget(self, action: #selector(self.openBrowser), for: .touchUpInside)
        
        self.deckListSort = Defaults[.deckFilterSort]
        
        self.tableView.contentInset = UIEdgeInsets.zero
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.leftBarButtonItems = [ self.settingsButton, self.sortButton ]
        self.navigationItem.rightBarButtonItems = [ self.addButton, self.importButton ]
        
        self.navigationItem.titleView = self.titleButton
        
        if CardManager.cardsAvailable && PackManager.packsAvailable {
            self.initializeDecks()
        }
        
        self.tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let _ = CardUpdateCheck.checkCardUpdateAvailable(self)
    }
    
    func initializeDecks() {
        var runnerDecks = DeckManager.decksForRole(.runner)
        var corpDecks = DeckManager.decksForRole(.corp)
        
        if self.filterText.length > 0 {
            let namePredicate = NSPredicate(format: "name CONTAINS[cd] %@", self.filterText)
            runnerDecks = runnerDecks.filter { namePredicate.evaluate(with: $0) }
            corpDecks = corpDecks.filter { namePredicate.evaluate(with: $0) }
        }
        
        if self.deckListSort != .byDate {
            runnerDecks = self.sortDecks(runnerDecks)
            corpDecks = self.sortDecks(corpDecks)
            self.decks = [ runnerDecks, corpDecks ]
        } else {
            let decks = runnerDecks + corpDecks
            runnerDecks = self.sortDecks(decks)
            self.decks = [ runnerDecks ]
        }
        
        let cardsAvailable = CardManager.cardsAvailable
        self.addButton.isEnabled = cardsAvailable
        self.importButton.isEnabled = cardsAvailable
        self.sortButton.isEnabled = cardsAvailable
        
        let allDecks = runnerDecks + corpDecks
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
        
        if let nav = self.navigationController {
            if nav.viewControllers.count > 1 {
                nav.popToRootViewController(animated: false)
            }
            nav.pushViewController(edit, animated: true)
        }
    }
    
    // MARK: - add new deck
    
    func createNewDeck(_ sender: Any) {
        self.createNewDeck()
    }
    
    func createNewDeck() {
        let alert = UIAlertController.actionSheet(title: "New Deck".localized(), message: nil)
        
        alert.addAction(UIAlertAction(title: "New Runner Deck".localized()) { action in
            self.addNewDeck(.runner)
        })
        alert.addAction(UIAlertAction(title: "New Corp Deck".localized()) { action in
            self.addNewDeck(.corp)
        })
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func addNewDeck(_ role: Role) {
        let idvc = IphoneIdentityViewController()
        idvc.role = role
        self.navigationController?.pushViewController(idvc, animated: true)
    }
    
    // MARK: - import
    
    func importDecks(_ sender: UIButton) {
        let useNrdb = Defaults[.useNrdb]
        let useDropbox = Defaults[.useDropbox]
        
        if useNrdb && useDropbox {
            let alert = UIAlertController.actionSheet(title: "Import Decks".localized(), message:nil)
            
            alert.addAction(UIAlertAction(title: "From Dropbox".localized()) { action in
                self.importDecksFrom(.dropbox)
            })
            alert.addAction(UIAlertAction(title: "From NetrunnerDB.com".localized()) { action in
                self.importDecksFrom(.netrunnerDb)
            })
            
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        } else if useNrdb {
            self.importDecksFrom(.netrunnerDb)
        } else if useDropbox {
            self.importDecksFrom(.dropbox)
        } else {
            let alert = UIAlertController.alert(title: "Import Decks".localized(),
                message: "Connect to your Dropbox and/or NetrunnerDB.com account first.".localized())
            
            alert.addAction(UIAlertAction(title: "OK".localized(), handler: nil))
            
            self.present(alert, animated: true, completion:nil)
        }
    }
    
    func importDecksFrom(_ importSource: ImportSource) {
        let importVc = ImportDecksViewController()
        importVc.source = importSource
        self.navigationController?.pushViewController(importVc, animated: true)
    }
    
    // MARK: - sort
    
    func changeSort(_ sender: UIBarButtonItem) {
        let alert = UIAlertController.actionSheet(title: "Sort by".localized(), message:nil)
        
        alert.addAction(UIAlertAction(title: "Date".localized().checked(self.deckListSort == .byDate)) { action in
            self.changeSortType(.byDate)
        })
        alert.addAction(UIAlertAction(title: "Faction".localized().checked(self.deckListSort == .byFaction)) { action in
            self.changeSortType(.byFaction)
        })
        alert.addAction(UIAlertAction(title: "A-Z".localized().checked(self.deckListSort == .byName)) { action in
            self.changeSortType(.byName)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func changeSortType(_ sort: DeckListSort) {
        Defaults[.deckFilterSort] = sort
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
                let faction1 = Faction.name(for: $0.identity?.faction ?? .none) 
                let faction2 = Faction.name(for: $1.identity?.faction ?? .none)
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
        let settings = Settings.viewController
        self.navigationController?.pushViewController(settings, animated: true)
    }
    
    // MARK: - browser
    
    func titleButtonTapped(_ sender: UIBarButtonItem) {
        self.openBrowser()
    }
    
    func openBrowser() {
        let browser = BrowserViewController()
        self.navigationController?.pushViewController(browser, animated: true)
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
            cell.detailTextLabel?.textColor = .black
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let edit = EditDeckViewController()
        edit.deck = self.decks[indexPath.section][indexPath.row]
        
        self.navigationController?.pushViewController(edit, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.decks.count == 1 {
            return nil
        }
        return section == 0 ? "Runner".localized() : "Corp".localized()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let deck = self.decks[indexPath.section][indexPath.row]
            NRDB.sharedInstance.deleteDeck(deck.netrunnerDbId)
            if let filename = deck.filename {
                DeckManager.removeFile(filename)
            }
            
            self.decks[indexPath.section].remove(at: indexPath.row)
            
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
        
        let color = self.tableView.tintColor ?? .blue
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
