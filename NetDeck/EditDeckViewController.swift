//
//  EditDeckViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 23.12.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit
import SVProgressHUD
import MessageUI
import SwiftyUserDefaults

class EditDeckViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var toolBar: UIToolbar!
    
    @IBOutlet weak var drawButton: UIBarButtonItem!
    @IBOutlet weak var nrdbButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var deck: Deck!
    
    private var cards = [[CardCounter]]()
    private var sections = [String]()
    
    private var autoSave = false
    private var autoSaveDropbox = false
    private var autoSaveNrdb = false
    private var sortType = DeckSort.byFactionType
    
    private var titleButton: UIButton!
    private var cancelButton: UIBarButtonItem!
    private var saveButton: UIBarButtonItem!
    private var exportButton: UIBarButtonItem!
    private var historyButton: UIBarButtonItem!
    
    private var listCards: ListCardsViewController!
    private var tapRecognizer: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = .clear
        
        self.tableView.register(UINib(nibName: "EditDeckCell", bundle: nil), forCellReuseIdentifier: "cardCell")
        
        self.statusLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: UIFontWeightRegular)
        self.statusLabel.text = ""
        
        self.autoSave = Defaults[.autoSave]
        self.autoSaveDropbox = Defaults[.autoSaveDropbox]
        self.autoSaveNrdb = Defaults[.nrdbAutosave]
        
        self.cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelClicked(_:)))
        self.saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.saveClicked(_:)))
        
        self.sortType = Defaults[.deckViewSort]
        
        self.statusLabel.textColor = self.view.tintColor
        self.statusLabel.isUserInteractionEnabled = true
        self.tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.statusTapped(_:)))
        self.statusLabel.addGestureRecognizer(self.tapRecognizer)
        
        // right button
        self.exportButton = UIBarButtonItem(image: UIImage(named: "702-share"), style: .plain, target: self, action: #selector(self.exportDeck(_:)))
        self.historyButton = UIBarButtonItem(image: UIImage(named: "718-timer-1"), style: .plain, target: self, action: #selector(self.showEditHistory(_:)))
        
        self.titleButton = UIButton(type: .system)
        self.titleButton.addTarget(self, action: #selector(self.titleTapped(_:)), for: .touchUpInside)
        self.titleButton.titleLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: UIFontWeightRegular)
        self.titleButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.titleButton.titleLabel?.minimumScaleFactor = 0.5
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setDeckName()
        self.navigationItem.titleView = self.titleButton
        self.navigationItem.rightBarButtonItems = [ self.exportButton, self.historyButton ]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        assert(self.navigationController?.viewControllers.count == 2, "oops")
        
        if !Defaults[.useNrdb] {
            self.nrdbButton.customView = UIView(frame: CGRect.zero)
            self.nrdbButton.isEnabled = false
        }
        
        self.refreshDeck()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Defaults[.deckViewSort] = self.sortType
    }
    
    func setupNavigationButtons(modified: Bool) {
        let navItem = self.navigationItem
        if modified {
            navItem.leftBarButtonItem = self.cancelButton
            navItem.rightBarButtonItems = [ self.saveButton, self.historyButton ]
        } else {
            navItem.leftBarButtonItem = nil
            navItem.rightBarButtonItems = [ self.exportButton, self.historyButton ]
        }
    }
    
    // MARK: - deck name
    
    func setDeckName() {
        self.titleButton.setTitle(self.deck?.name, for: .normal)
        self.titleButton.sizeToFit()
        
        self.title = self.deck?.name
        
        self.doAutoSave()
        self.setupNavigationButtons(modified: self.deck.modified)
    }
    
    func titleTapped(_ sender: Any) {
        let alert = UIAlertController.alert(title: "Enter Name".localized(), message: nil)
        
        alert.addTextField { (textField) in
            textField.text = self.deck?.name
            textField.autocapitalizationType = .words
            textField.autocorrectionType = .no
            textField.returnKeyType = .done
            textField.clearButtonMode = .always
        }
        
        alert.addAction(UIAlertAction(title: "OK".localized(), style: .default) { action in
            self.deck.name = alert.textFields?.first?.text ?? self.deck.name
            self.setDeckName()
        })
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - export
    
    func exportDeck(_ sender: Any) {
        let alert = UIAlertController.actionSheet(title: "Export".localized(), message: nil)
        
        if Defaults[.useDropbox] {
            alert.addAction(UIAlertAction(title: "To Dropbox".localized()) { action in
                Analytics.logEvent(.exportO8D)
                DeckExport.asOctgn(self.deck, autoSave: false)
            })
        }
        if Defaults[.useNrdb]  {
            alert.addAction(UIAlertAction(title: "To NetrunnerDB.com".localized()) { action in
                Analytics.logEvent(.saveToNRDB)
                self.saveToNrdb()
            })
        }
        if Defaults[.useJintekiNet] {
            alert.addAction(UIAlertAction(title: "To Jinteki.net".localized()) { action in
                Analytics.logEvent(.uploadJintekiNet)
                self.saveToJintekiNet()
            })
        }
        
        if MFMailComposeViewController.canSendMail() {
            alert.addAction(UIAlertAction(title: "As Email".localized()) { action in
                Analytics.logEvent(.emailDeck)
                DeckEmail.emailDeck(self.deck, fromViewController: self)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Duplicate Deck".localized()) { action in
            let newDeck = self.deck.duplicate()
            newDeck.saveToDisk()
            let status = String(format: "Copy saved as %@".localized(), newDeck.name)
            SVProgressHUD.showSuccess(withStatus: status)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        alert.view.layoutIfNeeded()
        
        self.present(alert, animated: false, completion: nil)
    }
    
    func showEditHistory(_ sender: Any) {
        self.deck.mergeRevisions()
        
        let histContoller = DeckHistoryViewController()
        histContoller.deck = self.deck
        
        self.navigationController?.pushViewController(histContoller, animated: true)
    }
    
    @IBAction func drawClicked(_ sender: Any) {
        let drawSim = IphoneDrawSimulator()
        drawSim.deck = self.deck
        
        self.navigationController?.pushViewController(drawSim, animated: true)
    }
    
    // MARK: - sort
    
    @IBAction func sortClicked(_ sender: Any) {
        let actionSheet = UIAlertController.actionSheet(title: "Sort by".localized(), message: nil)
        
        actionSheet.addAction(UIAlertAction(title: "Type".localized().checked(self.sortType == .byType)) { action in
            self.changeDeckSort(.byType)
        })
        actionSheet.addAction(UIAlertAction(title: "Faction".localized().checked(self.sortType == .byFactionType)) { action in
            self.changeDeckSort(.byFactionType)
        })
        actionSheet.addAction(UIAlertAction(title: "Set/Type".localized().checked(self.sortType == .bySetType)) { action in
            self.changeDeckSort(.bySetType)
        })
        actionSheet.addAction(UIAlertAction(title: "Set/Number".localized().checked(self.sortType == .bySetNum)) { action in
            self.changeDeckSort(.bySetNum)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func changeDeckSort(_ sortType: DeckSort) {
        self.sortType = sortType
        self.refreshDeck()
    }
    
    // MARK: - netrunnerdb.com
    
    @IBAction func nrdbButtonClicked(_ sender: UIBarButtonItem) {
        let alert = UIAlertController.actionSheet(title: "NetrunnerDB.com", message: nil)
        
        alert.addAction(UIAlertAction(title: "Save".localized()) { action in
            self.saveToNrdb()
        })
        
        if self.deck.netrunnerDbId != nil {
            alert.addAction(UIAlertAction(title: "Reimport".localized()) { action in
                self.reImportDeckFromNetrunnerDb()
            })
            alert.addAction(UIAlertAction(title: "Publish Deck".localized()) { action in
                self.publishDeck()
            })
            alert.addAction(UIAlertAction(title: "Unlink".localized()) { action in
                self.deck.netrunnerDbId = nil
                self.doAutoSave()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        alert.view.layoutIfNeeded()
        self.present(alert, animated: false, completion: nil)
    }
    
    // MARK: - save
    
    func cancelClicked(_ sender: Any) {
        if self.deck.filename != nil {
            self.deck = DeckManager.loadDeckFromPath(self.deck.filename!, useCache: false)
            self.refreshDeck()
            self.setupNavigationButtons(modified: false)
        } else {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    func saveClicked(_ sender: Any) {
        self.deck.mergeRevisions()
        self.deck.saveToDisk()
        
        if self.autoSaveDropbox {
            if self.deck.identity != nil && self.deck.cards.count > 0 {
                DeckExport.asOctgn(self.deck, autoSave: true)
            }
        }
        if self.autoSaveNrdb && self.deck.netrunnerDbId != nil && Reachability.online {
            self.saveToNrdb()
        }
        
        self.setupNavigationButtons(modified: self.deck.modified)
    }
    
    func doAutoSave() {
        let modified = self.deck.modified
        if modified && self.autoSave {
            self.deck.saveToDisk()
        }
        if modified && self.autoSaveDropbox {
            if self.deck.identity != nil && self.deck.cards.count > 0 {
                DeckExport.asOctgn(self.deck, autoSave: true)
            }
        }
    }
    
    func saveToNrdb() {
        if !Reachability.online {
            self.showOfflineAlert()
            return
        }
        
        SVProgressHUD.show(withStatus: "Saving Deck...".localized())
        
        NRDB.sharedInstance.saveDeck(self.deck) { ok, deckId, msg in
            if ok && deckId != nil {
                self.deck.netrunnerDbId = deckId
                self.deck.saveToDisk()
            }
            SVProgressHUD.dismiss()
        }
    }
    
    func saveToJintekiNet() {
        if !Reachability.online {
            self.showOfflineAlert()
            return
        }
        
        JintekiNet.sharedInstance.uploadDeck(self.deck)
    }
    
    func reImportDeckFromNetrunnerDb() {
        if !Reachability.online {
            self.showOfflineAlert()
            return
        }
        
        assert(self.deck.netrunnerDbId != nil, "no nrdb deck id")
        SVProgressHUD.show(withStatus: "Loading Deck...".localized())
        
        NRDB.sharedInstance.loadDeck(self.deck.netrunnerDbId!) { deck in
            if let deck = deck {
                deck.filename = self.deck.filename
                self.deck = deck
                self.deck.state = self.deck.state // to force .modified = true
                
                self.refreshDeck()
            } else {
                let msg = "Loading the deck from NetrunnerDB.com failed.".localized()
                UIAlertController.alert(withTitle: nil, message: msg, button: "OK".localized())
            }
            
            SVProgressHUD.dismiss()
        }
    }
    
    func publishDeck() {
        if !Reachability.online {
            self.showOfflineAlert()
            return
        }
        
        let errors = self.deck.checkValidity()
        if errors.count == 0 {
            SVProgressHUD.show(withStatus: "Publishing Deck...".localized())
            
            NRDB.sharedInstance.publishDeck(self.deck) { ok, deckId, errorMsg in
                if !ok {
                    var failed = "Publishing the deck at NetrunnerDB.com failed.".localized()
                    if errorMsg != nil {
                        failed += "\n" + errorMsg!
                    }
                    UIAlertController.alert(withTitle: nil, message: failed, button: "OK".localized())
                }
                if ok && deckId != nil {
                    let msg = String(format: "Deck published with ID %@".localized(), deckId!)
                    UIAlertController.alert(withTitle: nil, message: msg, button: "OK".localized())
                }
                
                SVProgressHUD.dismiss()
            }
        } else {
            UIAlertController.alert(withTitle: nil, message: "Only valid decks can be published.".localized(), button: "OK".localized())
        }
    }
    
    func showOfflineAlert() {
        UIAlertController.alert(withTitle: nil, message: "An Internet connection is required.".localized(), button: "OK".localized())
    }
    
    @IBAction func showCardList(_ sender: Any) {
        if self.listCards == nil {
            self.listCards = ListCardsViewController()
        }
        self.listCards.deck = self.deck
        
        // protect against pushing the same controller twice (crashlytics #101)
        if self.navigationController?.topViewController != self.listCards {
            self.navigationController?.pushViewController(self.listCards, animated: true)
        }
    }
    
    func refreshDeck() {
        let data = self.deck.dataForTableView(self.sortType)
        self.sections = data.sections
        self.cards = data.values
        
        self.tableView.reloadData()
        
        var footer = String(format: "%ld %@", self.deck.size, self.deck.size == 1 ? "Card".localized() : "Cards".localized())
        let inf = self.deck.role == .corp ? "Inf".localized() : "Influcence".localized()
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
        self.statusLabel.textColor = reasons.count == 0 ? self.view.tintColor : .red
        
        self.drawButton.isEnabled = self.deck.size > 0
        
        self.doAutoSave()
        self.setupNavigationButtons(modified: self.deck.modified)
    }
    
    func changeCount(_ stepper: UIStepper) {
        let section = stepper.tag / 1000
        let row = stepper.tag - (section * 1000)
        
        let cc = self.cards[section][row]
        
        let count = Int(stepper.value)
        let diff = count - cc.count
        self.deck.addCard(cc.card, copies: diff)
        
        self.doAutoSave()
        self.refreshDeck()
    }
    
    func selectIdentity(_ sender: Any) {
        let idController = IphoneIdentityViewController()
        idController.role = self.deck.role
        idController.deck = self.deck
        
        self.navigationController?.pushViewController(idController, animated: true)
    }
    
    // MARK: - tableview
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cards[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let name = self.sections[section]
        let arr = self.cards[section]
        
        let count = arr.reduce(0) { $0 + $1.count }
        
        if section > 0 && count > 0 {
            return String(format: "%@ (%d)", name, count)
        } else {
            return name
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cardCell", for: indexPath) as! EditDeckCell
        
        cell.stepper.tag = indexPath.section * 1000 + indexPath.row
        cell.stepper.addTarget(self, action: #selector(self.changeCount(_:)), for: .valueChanged)
        
        cell.idButton.setTitle("Identity".localized(), for: .normal)
        cell.idButton.addTarget(self, action: #selector(self.selectIdentity(_:)), for: .touchUpInside)
        
        let cc = self.cards[indexPath.section][indexPath.row]
        
        if cc.isNull {
            // empty identity
            cell.nameLabel.textColor = .black
            cell.nameLabel.text = ""
            cell.typeLabel.text = ""
            cell.stepper.isHidden = true
            cell.idButton.isHidden = false
            cell.mwlLabel.text = ""
            cell.influenceLabel.text = ""
            return cell
        }
        
        let card = cc.card
        cell.stepper.minimumValue = 0
        cell.stepper.maximumValue = Double(card.maxPerDeck)
        cell.stepper.value = Double(cc.count)
        cell.stepper.isHidden = card.type == .identity
        cell.idButton.isHidden = card.type != .identity
        
        let fmt = card.unique ? "%lu× %@ •" : "%lu× %@"
        cell.nameLabel.text = String(format: fmt, cc.count, card.name)
    
        if card.type == .identity {
            cell.nameLabel.text = card.name
            cell.stepper.isHidden = true
            
            cell.influenceLabel.textColor = .black
            if self.deck.isDraft {
                cell.influenceLabel.text = "∞"
            } else {
                let deckInfluence = self.deck.influenceLimit
                let inf = deckInfluence == -1 ? "∞" : "\(deckInfluence)"
                
                cell.influenceLabel.text = inf
                if deckInfluence != card.influenceLimit {
                    cell.influenceLabel.textColor = .red
                }
            }
            
            if self.deck.role == .runner {
                cell.mwlLabel.text = "\(card.baseLink)"
            } else {
                cell.mwlLabel.text = ""
            }
        }
        
        cell.nameLabel.textColor = .black
        if !self.deck.isDraft && card.owned < cc.count {
            cell.nameLabel.textColor = .red
        }
        
        cell.nameLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: UIFontWeightRegular)
        cell.mwlLabel.text = ""
        
        if card.type != .identity {
            let influence = self.deck.influenceFor(cc)
            if influence > 0 {
                cell.influenceLabel.text = "\(influence)"
                cell.influenceLabel.textColor = card.factionColor
            } else {
                cell.influenceLabel.text = ""
            }
            
            let penalty = card.mwlPenalty(self.deck.mwl)
            if penalty > 0 && !self.deck.mwl.universalInfluence {
                cell.mwlLabel.text = "\(-cc.count * penalty)"
            }
        }
        
        var type = Faction.name(for: card.faction)
        let subtype = card.subtype
        if subtype.length > 0 {
            type += " · " + subtype
        }
        cell.typeLabel.text = type
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cc = self.cards[indexPath.section][indexPath.row]
        if cc.isNull {
            return
        }
        
        let imgController = CardImageViewController()
        imgController.setCardCounters(self.deck.allCards)
        imgController.selectedCard = cc.card
        
        self.navigationController?.pushViewController(imgController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let cc = self.cards[indexPath.section][indexPath.row]
            if !cc.isNull {
                self.deck.addCard(cc.card, copies: 0)
            }
            
            self.perform(#selector(self.refreshDeck), with: nil, afterDelay: 0.0)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Remove".localized()
    }
    
    // MARK: - legality
    
    func statusTapped(_ gesture: UITapGestureRecognizer) {
        if gesture.state != .ended {
            return
        }
        
        let alert = UIAlertController.actionSheet(title: "Deck Legality".localized(), message: nil)
        
        alert.addAction(UIAlertAction(title: "Casual".localized().checked(self.deck.mwl == .none)) { action in
            self.deck.mwl = .none
            self.deck.onesies = false
            self.refreshDeck()
        })
        alert.addAction(UIAlertAction(title: "MWL v1.0".localized().checked(self.deck.mwl == .v1_0)) { action in
            self.deck.mwl = .v1_0
            self.deck.onesies = false
            self.refreshDeck()
        })
        alert.addAction(UIAlertAction(title: "MWL v1.1".localized().checked(self.deck.mwl == .v1_1)) { action in
            self.deck.mwl = .v1_1
            self.deck.onesies = false
            self.refreshDeck()
        })
        alert.addAction(UIAlertAction(title: "MWL v1.2".localized().checked(self.deck.mwl == .v1_2)) { action in
            self.deck.mwl = .v1_2
            self.deck.onesies = false
            self.refreshDeck()
        })
        alert.addAction(UIAlertAction(title: "1.1.1.1".localized().checked(self.deck.onesies)) { action in
            self.deck.mwl = .none
            self.deck.onesies = true
            self.refreshDeck()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
}
