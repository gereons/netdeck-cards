//
//  ImportDecksViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 01.11.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit
import SVProgressHUD

class ImportDecksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!

    var source = NRImportSource.none
    
    private var runnerDecks = [Deck]()
    private var corpDecks = [Deck]()
    private var filteredDecks = [[Deck]]()
    
    private var importButton: UIBarButtonItem!
    private var spacer: UIBarButtonItem!
    private var sortButton: UIBarButtonItem!
    private var barButtons = [UIBarButtonItem]()
    private var alert: UIAlertController?
    
    private var dateFormatter = DateFormatter()
    private var deckListSort = NRDeckListSort.byDate
    
    private var filterText = ""
    private var searchScope = NRDeckSearchScope.all
    
    override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
        
        if Device.isIpad {
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
        } else {
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sort = UserDefaults.standard.integer(forKey: SettingsKeys.DECK_FILTER_SORT)
        self.deckListSort = NRDeckListSort(rawValue: sort) ?? .byDate
        
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        
        self.searchBar.placeholder = "Search for decks, identities or cards".localized()
        if self.filterText.length > 0 {
            self.searchBar.text = self.filterText
        }
        self.searchBar.scopeButtonTitles = [ "All".localized(), "Name".localized(), "Identity".localized(), "Card".localized() ];
        self.searchBar.selectedScopeButtonIndex = self.searchScope.rawValue
        self.searchBar.showsScopeBar = false
        self.searchBar.showsCancelButton = false
        // needed on iOS8
        self.searchBar.sizeToFit()
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.rowHeight = 44
        let nib = UINib(nibName: "DeckCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "deckCell")
        self.tableView.setContentOffset(CGPoint(x: 0, y: self.searchBar.frame.size.height), animated:false)
        
        // do the initial listing in the background, as it may block the ui thread
        
        if (self.source == .dropbox)
        {
            SVProgressHUD.show(withStatus: "Loading decks from Dropbox".localized())
            self.getDropboxDecks()
        }
        else
        {
            SVProgressHUD.show(withStatus: "Loading decks from NetrunnerDB.com".localized())
            self.getNetrunnerDbDecks()
        }
        
        let title = Device.isIphone ? "All".localized() : "Import All".localized()
        self.importButton = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(self.importAll(_:)))
        
        if Device.isIphone {
            self.sortButton = UIBarButtonItem(image: UIImage(named: "890-sort-ascending-toolbar"), style: .plain, target: self, action: #selector(self.changeSort(_:)))
        } else {
            self.sortButton = UIBarButtonItem(title: "Sort".localized(), style: .plain, target: self, action: #selector(self.changeSort(_:)))
        }

        self.spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        self.spacer.width = 15
        self.barButtons = Device.isIphone ? [ self.importButton, self.sortButton ] : [ self.importButton, self.spacer, self.sortButton ]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.topItem?.title = Device.isIphone ? "Import".localized() : "Import Deck".localized()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.willShowKeyboard(_:)), name: Notification.Name.UIKeyboardWillShow, object:nil)
        nc.addObserver(self, selector: #selector(self.willHideKeyboard(_:)), name: Notification.Name.UIKeyboardWillHide, object:nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - sorting
    
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
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel) { action in
            self.alert = nil
        })
        
        if Device.isIpad, let popover = alert.popoverPresentationController {
            popover.barButtonItem = sender
            popover.sourceView = self.view
            popover.permittedArrowDirections = .up
            alert.view.layoutIfNeeded()
        }
        self.alert = alert
        self.present(alert, animated:false, completion:nil)
    }
    
    func changeSortType(_ sort: NRDeckListSort) {
        UserDefaults.standard.set(sort.rawValue, forKey:SettingsKeys.DECK_FILTER_SORT)
        self.deckListSort = sort
    
        self.filterDecks()
        self.tableView.reloadData()
    }
    
    func dismissSortPopup() {
        self.alert?.dismiss(animated:false, completion:nil)
        self.alert = nil
    }
    
    // MARK: - import all
    
    
    func importAll(_ sender: UIBarButtonItem) {
        guard self.alert == nil else {
            self.dismissSortPopup()
            return
        }
        
        let msg: String
        if self.source == .dropbox {
            msg = "Import all decks from Dropbox?"
        } else {
            msg = "Import all decks from NetrunnerDB.com? Existing linked decks will be overwritten."
        }
        
        let alert = UIAlertController.alert(title: "Import All".localized(), message: msg.localized())
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK".localized()) { action in
            SVProgressHUD.showSuccess(withStatus: "Imported decks".localized())
            self.perform(#selector(self.doImportAll), with: nil, afterDelay: 0.0)
        })
        
        self.present(alert, animated: false, completion: nil)
    }
    
    func doImportAll() {
        for decks in self.filteredDecks {
            for deck in decks {
                if self.source == .netrunnerDb {
                    deck.filename = NRDB.sharedInstance.filenameForId(deck.netrunnerDbId)
                }
                deck.updateOnDisk()
            }
        }
    }
    
    // MARK: - netrunnnerdb import
    
    func getNetrunnerDbDecks() {
        self.runnerDecks.removeAll()
        self.corpDecks.removeAll()
        
        SVProgressHUD.show(withStatus: "Loading Decks...".localized())
        
        NRDB.sharedInstance.decklist { decks in
            SVProgressHUD.dismiss()
            
            if let decks = decks {
                for deck in decks {
                    switch deck.role {
                    case .runner: self.runnerDecks.append(deck)
                    case .corp: self.corpDecks.append(deck)
                    default: break
                    }
                }
                
            }
            
            self.filterDecks()
            self.tableView.reloadData()
            self.navigationController?.navigationBar.topItem?.rightBarButtonItems = self.barButtons
        }
    }
    
    func importDeckFromNRDB(_ deckId: String, filename: String?) {
        guard self.source == .netrunnerDb else {
            return
        }
        
        SVProgressHUD.show(withStatus: "Import Deck".localized())
        
        NRDB.sharedInstance.loadDeck(deckId) { deck in
            if let deck = deck {
                deck.filename = filename
                SVProgressHUD.showSuccess(withStatus: "Deck imported".localized())
                deck.updateOnDisk()
                NRDB.sharedInstance.addDeck(deck)
            } else {
                SVProgressHUD.showError(withStatus: "Deck import failed".localized())
            }
        }
    }
    
    // MARK: - dropbox import
    
    func getDropboxDecks() {
        self.runnerDecks.removeAll()
        self.corpDecks.removeAll()
        
        DropboxWrapper.listDropboxFiles { names in
            var deckNames = [String]()
            for name in names {
                if name.lowercased().hasSuffix(".o8d") {
                    deckNames.append(name)
                }
            }
            
            self.downloadDropboxDecks(deckNames)
        }
    }
    
    func downloadDropboxDecks(_ deckNames: [String]) {
        let cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        let directory = cacheDir.appendPathComponent("dropbox")
        
        let fileManager = FileManager.default
        try? fileManager.removeItem(atPath: directory)
        try? fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        
        DropboxWrapper.downloadDropboxFiles(deckNames, toDirectory: directory) {
            SVProgressHUD.dismiss()
            
            self.readDecksFromDropbox(directory)
            self.navigationController?.navigationBar.topItem?.rightBarButtonItems = self.barButtons
        }
    }
    
    func readDecksFromDropbox(_ directory: String) {
        let fileManager = FileManager.default
        let files = try? fileManager.contentsOfDirectory(atPath: directory)
        
        for file in files! {
            let path = directory.appendPathComponent(file)
            if let data = fileManager.contents(atPath: path),
                let attrs = try? fileManager.attributesOfItem(atPath: path),
                let lastModified = attrs[FileAttributeKey.modificationDate] as? Date {
            
                let importer = OctgnImport()
                if let deck = importer.parseOctgnDeckFromData(data) {
                    if let range = file.range(of: ".o8d", options: .caseInsensitive) {
                        deck.name = file.substring(to: range.lowerBound)
                    } else {
                        deck.name = file
                    }
                    deck.lastModified = lastModified
                    
                    switch deck.role {
                    case .runner: self.runnerDecks.append(deck)
                    case .corp: self.corpDecks.append(deck)
                    default: break
                    }
                }
            }
        }
        
        let total = self.runnerDecks.count + self.corpDecks.count
        if total == 0 {
            let msg = "Copy Decks in OCTGN Format (.o8d) into the Apps/Net Deck folder of your Dropbox to import them into this App.".localized()
            
            UIAlertController.alert(withTitle: "No Decks found".localized(), message: msg, button: "OK".localized())
        } else {
            self.filterDecks()
            self.tableView.reloadData()
        }
    }
    
    // MARK: - filter & sort
    
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

    func filterDecks() {
        var allDecks = [Deck]()
        
        if self.deckListSort == .byDate {
            allDecks.append(contentsOf: self.runnerDecks)
            allDecks.append(contentsOf: self.corpDecks)
            allDecks = self.sortDecks(allDecks)
        } else {
            self.runnerDecks = self.sortDecks(self.runnerDecks)
            self.corpDecks = self.sortDecks(self.corpDecks)
        }
        
        if self.filterText.length > 0 {
            let namePredicate = NSPredicate(format: "name CONTAINS[cd] %@", filterText)
            let identityPredicate = NSPredicate(format: "(identity.name CONTAINS[cd] %@) or (identity.englishName CONTAINS[cd] %@)",
            filterText, filterText)
            let cardPredicate = NSPredicate(format: "(ANY cards.card.name CONTAINS[cd] %@) OR (ANY cards.card.englishName CONTAINS[cd] %@)", filterText, filterText)
            
            let predicate: NSPredicate
            switch self.searchScope {
            case .all:
                predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [ namePredicate, identityPredicate, cardPredicate ])
            case .name:
                predicate = namePredicate
            case .identity:
                predicate = identityPredicate
            case .card:
                predicate = cardPredicate
            }
            
            if allDecks.count > 0 {
                self.filteredDecks = [ allDecks.filter { predicate.evaluate(with: $0) } ]
            } else {
                self.filteredDecks = [
                    self.runnerDecks.filter { predicate.evaluate(with: $0) },
                    self.corpDecks.filter { predicate.evaluate(with: $0) }
                ]
            }
        } else {
            if allDecks.count > 0 {
                self.filteredDecks = [ allDecks ]
            } else {
                self.filteredDecks = [ self.runnerDecks, self.corpDecks ]
            }
        }
    }
    
    // MARK: - search bar
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filterText = searchText
        self.filterDecks()
        self.tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.searchScope = NRDeckSearchScope(rawValue: selectedScope) ?? .all
        self.filterDecks()
        self.tableView.reloadData()
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
    
    // MARK: - tableview
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.filteredDecks.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredDecks[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.deckListSort == .byDate ? nil :
            section == 0 ? "Runner".localized() : "Corp".localized()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "deckCell", for: indexPath) as! DeckCell
        
        cell.accessoryType = .none
        cell.infoButton?.isHidden = true
        
        let deck = self.filteredDecks[indexPath.section][indexPath.row]
        
        cell.nameLabel.text = deck.name
        if let identity = deck.identity {
            cell.identityLabel.text = identity.name
            cell.identityLabel.textColor = identity.factionColor
        } else {
            cell.identityLabel.text = "No Identity".localized()
            cell.identityLabel.textColor = UIColor.darkGray
        }
        
        let summary: String
        if deck.role == .runner {
            summary = String(format: "%d Cards · %d Influence".localized(), deck.size, deck.influence)
        } else {
            summary = String(format: "%d Cards · %d Influence · %d AP".localized(), deck.size, deck.influence, deck.agendaPoints)
        }
        
        cell.summaryLabel?.text = summary
        let valid = deck.checkValidity().count == 0
        cell.summaryLabel?.textColor = valid ? UIColor.black : UIColor.red
        
        cell.dateLabel.text = self.dateFormatter.string(from: deck.lastModified!)
        cell.nrdbIcon?.isHidden = self.source == .dropbox
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let deck = self.filteredDecks[indexPath.section][indexPath.row]
        
        if self.source == .netrunnerDb {
            if let filename = NRDB.sharedInstance.filenameForId(deck.netrunnerDbId) {
                let msg = "A local copy of this deck already exists.".localized()
                
                let alert = UIAlertController.alert(title: nil, message: msg)
                
                alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Overwrite".localized()) { action in
                    self.importDeckFromNRDB(deck.netrunnerDbId!, filename: filename)
                })
                alert.addAction(UIAlertAction(title: "Import as new".localized()) { action in
                    self.importDeckFromNRDB(deck.netrunnerDbId!, filename: nil)
                })
                
                self.present(alert, animated: false, completion: nil)
            } else {
                self.importDeckFromNRDB(deck.netrunnerDbId!, filename: nil)
            }
        } else {
            deck.updateOnDisk()
            SVProgressHUD.showSuccess(withStatus: "Deck imported".localized())
        }
    }
    
    // MARK: - keyboard show/hide
    
    func willShowKeyboard(_ notification: Notification) {
        guard let kbRect = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let screenHeight = UIScreen.main.bounds.size.height
        let kbHeight = screenHeight - kbRect.cgRectValue.origin.y
        
        let insets = UIEdgeInsets(top: 64, left: 0, bottom: kbHeight, right: 0)
        self.tableView.contentInset = insets
        self.tableView.scrollIndicatorInsets = insets
    }
    
    func willHideKeyboard(_ notification: Notification) {
        let insets = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        self.tableView.contentInset = insets
        self.tableView.scrollIndicatorInsets = insets
    }

}
