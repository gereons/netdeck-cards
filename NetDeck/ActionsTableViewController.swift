//
//  ActionsTableViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 23.01.17.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import UIKit

enum MenuItem: Int {
    case decks, deckDiff, browser, settings, about
    
    var cardsRequired: Bool {
        switch self {
        case .decks, .deckDiff, .browser: return true
        case .settings, .about: return false
        }
    }
    static var count: Int {
        return 5
    }
}

class ActionsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StartViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var version: UIBarButtonItem!
    
    private var searchForCard: Card?
    private var selectedItem = MenuItem.decks

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.isScrollEnabled = false
        
        self.title = "Net Deck"
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        self.version.title = Utils.appVersion()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.loadDeck(_:)), name: Notifications.loadDeck, object: nil)
        nc.addObserver(self, selector: #selector(self.newDeck(_:)), name: Notifications.newDeck, object: nil)
        nc.addObserver(self, selector: #selector(self.newDeck(_:)), name: Notifications.browserNew, object: nil)
        nc.addObserver(self, selector: #selector(self.importDeckFromClipboard(_:)), name: Notifications.importDeck, object: nil)
        nc.addObserver(self, selector: #selector(self.loadCards(_:)), name: Notifications.loadCards, object: nil)
        nc.addObserver(self, selector: #selector(self.listDecks(_:)), name: Notifications.browserFind, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if CardManager.cardsAvailable {
            self.selectDecks()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let displayedAlert = CardUpdateCheck.checkCardUpdateAvailable()
        if !displayedAlert {
            AppUpdateCheck.checkUpdate()
        }
        
        if !CardManager.cardsAvailable {
            self.resetDetailView()
        } else {
            self.selectDecks()
        }
    }
    
    func addNewDeck(_ role: Role) {
        let filter = CardFilterViewController(role: role)
   
        if let nav = self.navigationController {
            if nav.viewControllers.count > 1 {
                nav.popToRootViewController(animated: false)
            }
            nav.pushViewController(filter, animated: true)
        }
    }

    func openBrowser() {
        let indexPath = IndexPath(row: MenuItem.browser.rawValue, section: 0)
        
        self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        self.tableView(self.tableView, didSelectRowAt: indexPath)
    }
    
    // select "Decks" view
    private func selectDecks() {
        let indexPath = IndexPath(row: MenuItem.decks.rawValue, section: 0)
        
        self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        self.tableView(self.tableView, didSelectRowAt: indexPath)
    }

    @objc func loadDeck(_ notification: Notification) {
        guard let roleCode = notification.userInfo?["role"] as? Int,
            let role = Role(rawValue: roleCode),
            let filename = notification.userInfo?["filename"] as? String else {
                return
        }
        
        let filter = CardFilterViewController(role: role, andFile: filename)
        self.navigationController?.pushViewController(filter, animated: true)
    }
    
    @objc func newDeck(_ notification: Notification) {
        let filter: CardFilterViewController
        if notification.name == Notifications.browserNew {
            guard
                let code = notification.userInfo?["code"] as? String,
                let card = CardManager.cardBy(code: code)
            else { return }
            
            let deck = Deck(role: card.role)
            deck.addCard(card, copies: 1)
            filter = CardFilterViewController(role: card.role, andDeck: deck)
        } else {
            guard
                let roleCode = notification.userInfo?["role"] as? Int,
                let role = Role(rawValue: roleCode)
            else { return }
            filter = CardFilterViewController(role: role)
        }
        
        if let nav = self.navigationController {
            if nav.viewControllers.count > 1 {
                nav.popToRootViewController(animated: false)
            }
            nav.pushViewController(filter, animated: true)
        }
    }
    
    @objc func importDeckFromClipboard(_ notification: Notification) {
        guard
            let deck = notification.userInfo?["deck"] as? Deck,
            let identity = deck.identity
        else { return }
        
        deck.saveToDisk()
        let filter = CardFilterViewController(role: identity.role, andDeck: deck)
        if let nav = self.navigationController {
            if nav.viewControllers.count > 1 {
                nav.popToRootViewController(animated: false)
            }
            nav.pushViewController(filter, animated: true)
        }
    }
    
    @objc func loadCards(_ notification: Notification) {
        self.tableView.reloadData()        
        if self.selectedItem != .settings {
            self.selectDecks()
        }
    }
    
    @objc func listDecks(_ notification: Notification) {
        guard
            let code = notification.userInfo?["code"] as? String,
            let card = CardManager.cardBy(code: code)
        else { return }
        
        _ = self.navigationController?.popToRootViewController(animated: false)
        self.searchForCard = card
        self.selectDecks()
    }
    
    // MARK: - table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MenuItem.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "actionCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? {
            let c = UITableViewCell(style: .default, reuseIdentifier: identifier)
            c.accessoryType = .disclosureIndicator
            c.textLabel?.font = UIFont.systemFont(ofSize: 17)
            return c
        }()
        
        let menuItem = MenuItem(rawValue: indexPath.row)!
        
        let label: String
        switch menuItem {
        case .about:
            label = "About".localized()
        case .settings:
            label = "Settings".localized()
        case .deckDiff:
            label = "Compare Decks".localized()
        case .decks:
            label = "Decks".localized()
        case .browser:
            label = "Card Browser".localized()
        }
        cell.textLabel?.text = label
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.selectedItem = MenuItem(rawValue: indexPath.row)!
        
        if !CardManager.cardsAvailable && self.selectedItem.cardsRequired {
            self.resetDetailView()
            return
        }
        
        switch self.selectedItem {
        case .decks:
            let decks: SavedDecksList
            if let card = self.searchForCard {
                decks = SavedDecksList(card: card)
                self.searchForCard = nil
            } else {
                decks = SavedDecksList()
            }
            self.showAsDetailViewController(decks)
        case .deckDiff:
            let compare = CompareDecksList()
            self.showAsDetailViewController(compare)
        case .browser:
            let browser = BrowserFilterViewController()
            self.navigationController?.pushViewController(browser, animated: true)
        case .settings:
            let settings = Settings.viewController
            Analytics.logEvent(.showSettings)
            self.showAsDetailViewController(settings)
        case .about:
            let about = AboutViewController()
            self.showAsDetailViewController(about)
        }
    }
    
    private func resetDetailView() {
        let empty = EmptyDetailViewController()
        self.showAsDetailViewController(empty)
    }
    
    private func showAsDetailViewController(_ vc: UIViewController) {
        let navController = UINavigationController(rootViewController: vc)
        navController.navigationBar.barTintColor = .white
        self.showDetailViewController(navController, sender: self)
    }
    
}
