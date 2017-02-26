//
//  ActionsTableViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 23.01.17.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

enum MenuItem: Int {
    case decks, deckDiff, browser, settings, about
    case count
}

class ActionsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var version: UIBarButtonItem!
    
    private var settings: SettingsViewController!
    private var searchForCard: Card?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.isScrollEnabled = false
        self.navigationController?.navigationBar.barTintColor = .white
        
        self.title = "Net Deck"
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        self.version.title = AppDelegate.appVersion()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.loadDeck(_:)), name: Notifications.loadDeck, object: nil)
        nc.addObserver(self, selector: #selector(self.newDeck(_:)), name: Notifications.newDeck, object: nil)
        nc.addObserver(self, selector: #selector(self.newDeck(_:)), name: Notifications.browserNew, object: nil)
        nc.addObserver(self, selector: #selector(self.importDeckFromClipboard(_:)), name: Notifications.importDeck, object: nil)
        nc.addObserver(self, selector: #selector(self.loadCards(_:)), name: Notifications.loadCards, object: nil)
        nc.addObserver(self, selector: #selector(self.loadCards(_:)), name: Notifications.dropboxChanged, object: nil)
        nc.addObserver(self, selector: #selector(self.listDecks(_:)), name: Notifications.browserFind, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let displayedAlert = CardUpdateCheck.checkCardUpdateAvailable(self)
        if !displayedAlert {
            AppUpdateCheck.checkUpdate()
        }
        
        if !CardManager.cardsAvailable || !PackManager.packsAvailable {
            self.resetDetailView()
            return
        }
        
        self.selectDecks()
    }
    
    // select "Decks" view
    private func selectDecks() {
        let indexPath = IndexPath(row: MenuItem.decks.rawValue, section: 0)
        
        self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        self.tableView(self.tableView, didSelectRowAt: indexPath)
    }

    private func resetDetailView() {
        let empty = EmptyDetailViewController()
        self.showAsDetailViewController(empty)
    }
    
    func loadDeck(_ notification: Notification) {
        guard let roleCode = notification.userInfo?["role"] as? Int,
            let role = Role(rawValue: roleCode),
            let filename = notification.userInfo?["filename"] as? String else {
                return
        }
        
        let filter = CardFilterViewController(role: role, andFile: filename)
        self.navigationController?.pushViewController(filter, animated: true)
    }
    
    func newDeck(_ notification: Notification) {
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
    
    func importDeckFromClipboard(_ notification: Notification) {
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
    
    func loadCards(_ notification: Notification) {
        self.tableView.reloadData()        
        self.selectDecks()
    }
    
    func listDecks(_ notification: Notification) {
        guard
            let code = notification.userInfo?["code"] as? String,
            let card = CardManager.cardBy(code: code)
        else { return }
        
        let _ = self.navigationController?.popToRootViewController(animated: false)
        self.searchForCard = card
        self.selectDecks()
    }
    
    // MARK: - table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MenuItem.count.rawValue
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "actions") ?? {
            let c = UITableViewCell(style: .default, reuseIdentifier: "actions")
            c.accessoryType = .disclosureIndicator
            c.textLabel?.font = UIFont.systemFont(ofSize: 17)
            return c
        }()
        
        let cardsAvailable = CardManager.cardsAvailable && PackManager.packsAvailable
        
        let menuItem = MenuItem(rawValue: indexPath.row) ?? .count
        
        switch menuItem {
        case .about:
            cell.textLabel?.text = "About".localized()
        case .settings:
            cell.textLabel?.text = "Settings".localized()
        case .deckDiff:
            cell.textLabel?.text = "Compare Decks".localized()
            cell.textLabel?.isEnabled = cardsAvailable
        case .decks:
            cell.textLabel?.text = "Decks".localized()
            cell.textLabel?.isEnabled = cardsAvailable
        case .browser:
            cell.textLabel?.text = "Card Browser".localized()
            cell.textLabel?.isEnabled = cardsAvailable
        case .count:
            assert(false, "this can't happen")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let enabled = cell?.textLabel?.isEnabled ?? false
        if !enabled {
            self.resetDetailView()
            return
        }
        
        self.settings = nil
        
        let menuItem = MenuItem(rawValue: indexPath.row) ?? .count
        
        switch menuItem {
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
            self.settings = SettingsViewController()
            self.showAsDetailViewController(settings.iask)
        case .about:
            let about = AboutViewController()
            self.showAsDetailViewController(about)
        case .count:
            assert(false, "this can't happen")
        }
    }
    
    private func showAsDetailViewController(_ vc: UIViewController) {
        let navController = UINavigationController(rootViewController: vc)
        navController.navigationBar.barTintColor = .white
        self.showDetailViewController(navController, sender: self)
    }
    
}
