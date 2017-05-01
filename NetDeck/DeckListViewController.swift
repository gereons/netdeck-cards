//
//  DeckListViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 22.01.17.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit
import SVProgressHUD
import SwiftyUserDefaults

class DeckListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIPrintInteractionControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var mwlButton: UIButton!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var statusLabel: TickingLabel!
    @IBOutlet weak var deckNameLabel: UILabel!
    @IBOutlet weak var lastSetLabel: UILabel!
    
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var drawButton: UIButton!
    @IBOutlet weak var analysisButton: UIButton!
    @IBOutlet weak var notesButton: UIButton!
    @IBOutlet weak var historyButton: UIButton!
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerWidth: NSLayoutConstraint!
    
    @IBOutlet weak var toolbarBottomMargin: NSLayoutConstraint!
    private var keyboardObserver: KeyboardObserver!

    var role = Role.none
    var deck: Deck! {
        didSet {
            if oldValue != nil {
                self.refresh()
            }
        }
    }
    
    private var sections = [String]()
    private var cards = [[CardCounter]]()
    private var actionSheet: UIAlertController!
    private var printController: UIPrintInteractionController!
    private var toggleViewButton: UIBarButtonItem!
    private var saveButton: UIBarButtonItem!
    private var exportButton: UIBarButtonItem!
    private var stateButton: UIBarButtonItem!
    private var nrdbButton: UIBarButtonItem!
    private var progressView: UIProgressView!
    
    private var filename: String?
    private var autoSave = false
    private var autoSaveDropbox = false
    private var useNetrunnerDb = false
    private var autoSaveNRDB = false
    
    private var sortType = DeckSort.byFactionType
    private var scale = 1.0
    private var largeCells = false
    private var initializing = false
    private var historyTimer: Timer?
    private var historyTicker = 0.0
    
    private let historySaveInterval = 60.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initializing = true

        self.useNetrunnerDb = Defaults[.useNrdb]
        self.autoSaveNRDB = Defaults[.nrdbAutosave]
        self.sortType = Defaults[.deckViewSort]
        let scale: Double = Defaults[.deckViewScale]
        self.scale = scale == 0.0 ? 1.0 : scale
        
        if self.filename != nil && self.deck == nil {
            self.deck = DeckManager.loadDeckFromPath(self.filename!)
            assert(self.role == deck.role, "role mismatch")
        }
        
        if self.deck == nil {
            self.deck = Deck(role: self.role)
        }
        
        self.deckNameLabel.text = self.deck.name
        self.initCards()
        
        self.parent?.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.tableView.backgroundColor = .clear
        self.tableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        self.tableView.scrollIndicatorInsets = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.register(UINib(nibName: "LargeCardCell", bundle: nil), forCellReuseIdentifier: "largeCardCell")
        self.tableView.register(UINib(nibName: "SmallCardCell", bundle: nil), forCellReuseIdentifier: "smallCardCell")
        
        self.largeCells = true
        
        self.collectionView.backgroundColor = .clear
        self.collectionView.alwaysBounceVertical = true
        
        self.navigationController?.navigationBar.barTintColor = .white
        
        let selections = [
            UIImage(named: "deckview_card") as Any,
            UIImage(named: "deckview_table") as Any,
            UIImage(named: "deckview_list") as Any
        ]
        let viewSelector = UISegmentedControl(items: selections)
        let view = Defaults[.deckViewStyle]
        viewSelector.selectedSegmentIndex = view.rawValue
        viewSelector.addTarget(self, action: #selector(self.toggleView(_:)), for: .valueChanged)
        self.toggleViewButton = UIBarButtonItem(customView: viewSelector)
        self.doToggleView(view)
        
        self.navigationItem.leftBarButtonItem = self.toggleViewButton
        
        self.autoSave = Defaults[.autoSave]
        self.autoSaveDropbox = self.autoSave && Defaults[.useDropbox] && Defaults[.autoSaveDropbox]
        
        // right button
        self.exportButton = UIBarButtonItem(image: UIImage(named: "702-share"), style: .plain, target: self, action: #selector(self.exportDeck(_:)))
        self.saveButton = UIBarButtonItem(title: "Save".localized(), style: .plain, target: self, action: #selector(self.saveDeckClicked(_:)))
        self.saveButton.isEnabled = false
        
        let img = UIImage(named: "netrunnerdb_com")?.withRenderingMode(.alwaysOriginal)
        self.nrdbButton = UIBarButtonItem(image: img, style: .plain, target: self, action: #selector(self.nrdbButtonClicked(_:)))
        
        self.stateButton = UIBarButtonItem(title: DeckState.buttonLabelFor(self.deck.state), style: .plain, target: self, action: #selector(self.changeState(_:)))
        
        self.stateButton.possibleTitles = Set(DeckState.possibleTitles())
        
        let dupButton = UIBarButtonItem(title: "Duplicate".localized(), style: .plain, target: self, action: #selector(self.duplicateDeck(_:)))
        let nameButton = UIBarButtonItem(title: "Name".localized(), style: .plain, target: self, action: #selector(self.enterName(_:)))
        let sortButton = UIBarButtonItem(title: "Sort".localized(), style: .plain, target: self, action: #selector(self.sortPopup(_:)))
        
        var rightButtons = [UIBarButtonItem]()
        rightButtons.append(self.exportButton)
        rightButtons.append(sortButton)
        rightButtons.append(dupButton)
        if self.useNetrunnerDb {
            rightButtons.append(self.nrdbButton)
        }
        if !self.autoSave {
            rightButtons.append(self.saveButton)
        }
        rightButtons.append(nameButton)
        rightButtons.append(self.stateButton)
        
        self.navigationItem.rightBarButtonItems = rightButtons
        
        // setup bottom toolbar
        self.drawButton.setTitle("Draw".localized(), for: .normal)
        self.analysisButton.setTitle("Analysis".localized(), for: .normal)
        self.notesButton.setTitle("Notes".localized(), for: .normal)
        self.historyButton.setTitle("History".localized(), for: .normal)
        self.historyButton.isEnabled = deck.filename != nil && deck.revisions.count > 0
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.identitySelected(_:)), name: Notifications.selectIdentity, object: nil)
        nc.addObserver(self, selector: #selector(self.deckChanged(_:)), name: Notifications.deckChanged, object: nil)
        nc.addObserver(self, selector: #selector(self.notesChanged(_:)), name: Notifications.notesChanged, object: nil)
        nc.addObserver(self, selector: #selector(self.stopHistoryTimer(_:)), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        nc.addObserver(self, selector: #selector(self.startHistoryTimer(_:)), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        
        self.keyboardObserver = KeyboardObserver(handler: self)
        
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(self.enterName(_:)))
        self.deckNameLabel.addGestureRecognizer(nameTap)
        self.deckNameLabel.isUserInteractionEnabled = true
        
        self.collectionView.register(UINib(nibName: "CardImageCell", bundle: nil), forCellWithReuseIdentifier: "cardImageCell")
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGesture(_:)))
        self.collectionView.addGestureRecognizer(pinch)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGesture(_:)))
        self.collectionView.addGestureRecognizer(longPress)
        
        self.statusLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFontWeightRegular)
        self.summaryLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFontWeightRegular)
        
        let footerTap = UITapGestureRecognizer(target: self, action: #selector(self.statusTapped(_:)))
        self.footerView.addGestureRecognizer(footerTap)
        self.footerView.isUserInteractionEnabled = true
        
        self.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let x = Double(self.view.center.x) - self.historySaveInterval
        let width = 2 * self.historySaveInterval
        self.progressView = UIProgressView(frame: CGRect(x: x, y: 40, width: width, height: 3))
        self.progressView.progress = 1.0
        self.progressView.progressTintColor = .darkGray
        self.toolBar.addSubview(self.progressView)
        
        self.progressView.isHidden = !Defaults[.autoHistory]
        self.footerView.layer.opacity = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.deck.cards.count > 0 || self.deck.identity != nil {
            NotificationCenter.default.post(name: Notifications.deckChanged, object: self, userInfo: [ "initialLoad": true])
        }
        
        self.initializing = false
        
        if self.deck.identity == nil && self.filename == nil && self.deck.cards.count == 0 {
            self.selectIdentity(self)
        }
        
        if self.deck.filename != nil {
            self.startHistoryTimer(self)
        }
        
        self.stateButton.title = DeckState.buttonLabelFor(self.deck.state)
        self.footerWidth.constant = self.historyButton.frame.origin.x - 16
        UIView.animate(withDuration: 0.1) {
            self.footerView.layer.opacity = 1
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        Defaults[.deckViewScale] = self.scale
        Defaults[.deckViewSort] = self.sortType
        
        self.stopHistoryTimer(self)
    }
    
    // MARK: - history timer
    func startHistoryTimer(_ notification: Any) {
        self.stopHistoryTimer(notification)
        
        guard Defaults[.autoHistory] else {
            return
        }
        
        self.historyTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.historySave(_:)), userInfo: nil, repeats: true)
        self.progressView.progress = 1.0
        self.historyTicker = self.historySaveInterval
    }
    
    func stopHistoryTimer(_ notification: Any) {
        self.historyTimer?.invalidate()
        self.historyTimer = nil
        self.historyTicker = 0
    }
    
    func historySave(_ timer: Timer) {
        self.historyTicker -= 1
        self.progressView.progress = Float(self.historyTicker / self.historySaveInterval)

        if self.historyTicker <= 0 {
            self.deck.mergeRevisions()
            self.historyButton.isEnabled = true
            self.historyTicker = self.historySaveInterval + 1
        }
    }
    
    
    func loadDeck(fromFile file: String) {
        self.filename = file
        self.deck = DeckManager.loadDeckFromPath(file)
        assert(self.role == self.deck.role, "role mismatch")
    }
    
    func saveDeckClicked(_ sender: Any) {
        self.saveDeckManually(true)
        NotificationCenter.default.post(name: Notifications.deckSaved, object: self)
    }
    
    private func saveDeckManually(_ manually: Bool) {
        if self.actionSheet != nil {
            return self.dismissActionSheet()
        }
        
        if manually {
            self.stopHistoryTimer(self)
            self.historyButton.isEnabled = true
            self.progressView?.isHidden = false
            self.startHistoryTimer(self)
            
            self.deck.mergeRevisions()
            SVProgressHUD.showSuccess(withStatus: "Saving...".localized())
        }
        
        var keepLastModified = !manually
        if self.autoSave {
            keepLastModified = false
        }
        if keepLastModified {
            self.deck.updateOnDisk()
        } else {
            self.deck.saveToDisk()
        }
        
        if manually && self.autoSaveNRDB {
            self.saveDeckToNetrunnerDb()
        }
        
        self.saveButton.isEnabled = false
        
        if self.autoSaveDropbox {
            if self.deck.identity != nil && self.deck.cards.count > 0 {
                DeckExport.asOctgn(self.deck, autoSave: true)
            }
        }
    }
    
    @IBAction func analysisClicked(_ sender: UIButton) {
        DeckAnalysisViewController.showForDeck(self.deck, inViewController: self)
    }
    
    @IBAction func drawSimulatorClicked(_ sender: UIButton) {
        DrawSimulatorViewController.showForDeck(self.deck, inViewController: self)
    }
    
    func nrdbButtonClicked(_ sender: Any) {
        if self.actionSheet != nil {
            return self.dismissActionSheet()
        }
        
        if let deckId = self.deck.netrunnerDbId {
            let msg = String(format: "This deck is linked to deck %@ on NetrunnerDB.com".localized(), deckId)
            
            let alert = UIAlertController.alert(title: nil, message: msg)
            
            alert.addAction(UIAlertAction.alertCancel(nil))
            alert.addAction(UIAlertAction(title: "Open in Safari".localized()) { action in
                if Reachability.online {
                    Analytics.logEvent(.openInSafari)
                    self.openInSafari(self.deck)
                } else {
                    self.showOfflineAlert()
                }
            })
            alert.addAction(UIAlertAction(title: "Publish deck".localized()) { action in
                if Reachability.online {
                    Analytics.logEvent(.publishDeck)
                    self.publishDeck(self.deck)
                } else {
                    self.showOfflineAlert()
                }
            })
            alert.addAction(UIAlertAction(title: "Unlink".localized()) { action in
                self.deck.netrunnerDbId = nil
                Analytics.logEvent(.unlinkDeck)
                if self.autoSave {
                    self.saveDeckManually(false)
                }
                self.refresh()
            })
            alert.addAction(UIAlertAction(title: "Reimport".localized()) { action in
                Analytics.logEvent(.reimportDeck)
                self.reImportDeckFromNetrunnerDb()
            })
            alert.addAction(UIAlertAction(title: "Save".localized()) { action in
                Analytics.logEvent(.saveToNRDB)
                self.saveDeckToNetrunnerDb()
            })
            
            self.present(alert, animated: false, completion: nil)
        } else {
            let msg = "This deck is not (yet) linked to a deck on NetrunnerDB.com".localized()
            let alert = UIAlertController.alert(title: nil, message: msg)
            
            alert.addAction(UIAlertAction(title: "OK".localized(), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Save".localized()) { action in
                Analytics.logEvent(.saveToNRDB)
                self.saveDeckToNetrunnerDb()
            })
            self.present(alert, animated: false, completion: nil)
        }
    }
    
    private func saveDeckToNetrunnerDb() {
        if !Reachability.online {
            return self.showOfflineAlert()
        }
        
        SVProgressHUD.show(withStatus: "Saving Deck...".localized())
        
        NRDB.sharedInstance.saveDeck(self.deck) { ok, deckId, msg in
            SVProgressHUD.dismiss()
            
            if !ok {
                UIAlertController.alert(withTitle: nil, message: "Saving the deck at NetrunnerDB.com failed.".localized(), button: "OK".localized())
            }
            if ok && deckId != nil {
                self.deck.netrunnerDbId = deckId
                self.deck.updateOnDisk()
            }
        }
    }
    
    private func reImportDeckFromNetrunnerDb() {
        if !Reachability.online {
            return self.showOfflineAlert()
        }
        
        guard let deckId = self.deck.netrunnerDbId else {
            return
        }
        
        NRDB.sharedInstance.loadDeck(deckId) { deck in
            
            SVProgressHUD.dismiss()
            if let deck = deck {
                deck.filename = self.deck.filename
                self.deck = deck
                self.deck.state = self.deck.state // force .modified = true
                
                self.refresh()
            } else {
                UIAlertController.alert(withTitle: nil, message: "Loading the deck from NetrunnerDB.com failed.".localized(), button: "OK".localized())
            }
        }
    }
    
    private func openInSafari(_ deck: Deck) {
        guard let nrdbId = self.deck.netrunnerDbId, let url = URL(string: "https://netrunnerdb.com/en/deck/view/" + nrdbId) else {
            return
        }
        
        UIApplication.shared.openURL(url)
    }
    
    private func publishDeck(_ deck: Deck) {
        let errors = deck.checkValidity()
        guard errors.count == 0 else {
            UIAlertController.alert(withTitle: nil, message: "Only valid decks can be published.".localized(), button: "OK".localized())
            return
        }
        
        SVProgressHUD.show(withStatus: "Publishing Deck...")
        
        NRDB.sharedInstance.publishDeck(self.deck) { ok, deckId, errorMsg in
            SVProgressHUD.dismiss()
            
            if !ok {
                var fail = "Publishing the deck at NetrunnerDB.com failed.".localized()
                if let err = errorMsg {
                    fail += "\n'\(err)'"
                }
                UIAlertController.alert(withTitle: nil, message: fail , button: "OK".localized())
            }
            if ok && deckId != nil {
                let msg = String(format: "Deck published with ID %@".localized(), deckId!)
                UIAlertController.alert(withTitle: nil, message: msg , button: "OK".localized())
            }
        }
    }
    
    private func showOfflineAlert() {
        UIAlertController.alert(withTitle: nil, message: "An Internet connection is required.".localized(), button: "OK".localized())
    }
    
    @IBAction func notesButtonClicked(_ sender: Any) {
        if self.actionSheet != nil {
            return self.dismissActionSheet()
        }
        DeckNotesPopup.showFor(deck: self.deck, in: self)
    }
    
    @IBAction func historyButtonClicked(_ sender: UIButton) {
        if self.actionSheet != nil {
            return self.dismissActionSheet()
        }
        self.deck.mergeRevisions()
        DeckHistoryPopup.showFor(deck: self.deck, in: self)
    }
    
    // MARK: - duplicate deck
    
    func duplicateDeck(_ sender: UIBarButtonItem) {
        if self.actionSheet != nil {
            return self.dismissActionSheet()
        }
        
        let alert = UIAlertController.alert(title: nil, message: "Duplicate this deck?".localized())
        
        alert.addAction(UIAlertAction(title: "No".localized(), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes, switch to copy".localized()) { action in
            let newDeck = self.deck.duplicate()
            self.deck = newDeck
            if self.autoSave {
                self.deck.saveToDisk()
            } else {
                self.deck.state = self.deck.state // force .modified=true
            }
            self.refresh()
        })
        alert.addAction(UIAlertAction(title: "Yes, but stay here".localized()) { action in
            let newDeck = self.deck.duplicate()
            newDeck.saveToDisk()
            if self.autoSaveDropbox {
                if newDeck.identity != nil && newDeck.cards.count > 0 {
                    DeckExport.asOctgn(newDeck, autoSave: true)
                }
            }
        })
        
        self.present(alert, animated: false, completion: nil)
    }
    
    // MARK: - deck state
    
    func changeState(_ sender: UIBarButtonItem) {
        if self.actionSheet != nil {
            return self.dismissActionSheet()
        }
        
        self.actionSheet = UIAlertController.actionSheet(title: nil, message: nil)
        self.actionSheet.addAction(UIAlertAction(title: "Active".localized().checked(self.deck.state == .active)) { action in
          self.changeDeckState(.active)
        })
        self.actionSheet.addAction(UIAlertAction(title: "Testing".localized().checked(self.deck.state == .testing)) { action in
            self.changeDeckState(.testing)
        })
        self.actionSheet.addAction(UIAlertAction(title: "Retired".localized().checked(self.deck.state == .retired)) { action in
            self.changeDeckState(.retired)
        })
        self.actionSheet.addAction(UIAlertAction.actionSheetCancel() { action in
            self.actionSheet = nil
        })
        
        let popover = self.actionSheet.popoverPresentationController
        popover?.barButtonItem = sender
        popover?.sourceView = self.view
        popover?.permittedArrowDirections = .any
        self.actionSheet.view.layoutIfNeeded()
        
        self.present(self.actionSheet, animated: false, completion: nil)
    }
    
    private func changeDeckState(_ newState: DeckState) {
        let oldState = self.deck.state
        
        Analytics.logEvent(.changeState, attributes: [ "From": DeckState.rawLabelFor(oldState), "To": DeckState.rawLabelFor(newState)])
        self.deck.state = newState
        self.stateButton.title = DeckState.buttonLabelFor(newState)
        if newState != oldState {
            if self.autoSave {
                self.saveDeckManually(false)
            }
            self.refresh()
        }
        self.actionSheet = nil
    }
    
    // MARK: - deck name
    
    func enterName(_ sender: Any) {
        if self.actionSheet != nil {
            return self.dismissActionSheet()
        }
        
        let nameAlert = UIAlertController.alert(title: "Enter Name".localized(), message: nil)
        
        nameAlert.addTextField() { textField in
            textField.placeholder = "Deck Name".localized()
            textField.text = self.deck.name
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .always
            textField.autocorrectionType = .no
            textField.returnKeyType = .done
        }
        
        nameAlert.addAction(UIAlertAction.alertCancel(nil))
        nameAlert.addAction(UIAlertAction(title: "OK".localized()) { action in
            self.deck.name = nameAlert.textFields![0].text ?? self.deck.name
            self.deckNameLabel.text = self.deck.name
            if self.autoSave {
                self.saveDeckManually(false)
            } else {
                NotificationCenter.default.post(name: Notifications.deckChanged, object: self)
            }
            self.refresh()
        })
        
        NotificationCenter.default.post(name: Notifications.nameAlert, object: self)
        self.present(nameAlert, animated: false, completion: nil)
    }
    
    // MARK: - identity selection
    
    func selectIdentity(_ sender: Any) {
        if self.actionSheet != nil {
            return self.dismissActionSheet()
        }
        
        IdentitySelectionViewController.showFor(role: self.role, inViewController: self, withIdentity: self.deck.identity)
    }
    
    func identitySelected(_ notification: Notification) {
        guard let code = notification.userInfo?["code"] as? String else {
            return
        }
        guard let card = CardManager.cardBy(code: code) else {
            return
        }
        
        if self.deck.identity?.code != code {
            self.deck.addCard(card, copies: 1)
            self.refresh()
            
            NotificationCenter.default.post(name: Notifications.deckChanged, object: self)
        }
        
    }
    
    // MARK: - sort
    
    func sortPopup(_ sender: UIBarButtonItem) {
        if self.actionSheet != nil {
            return self.dismissActionSheet()
        }
        
        if self.printController != nil {
            return self.dismissPrintController()
        }
        
        self.actionSheet = UIAlertController.actionSheet(title: nil, message: nil)
        
        self.actionSheet.addAction(UIAlertAction(title: "by Type".localized().checked(self.sortType == .byType)) { action in
            self.changeDeckSort(.byType)
        })
        self.actionSheet.addAction(UIAlertAction(title: "by Faction".localized().checked(self.sortType == .byFactionType)) { action in
            self.changeDeckSort(.byFactionType)
        })
        self.actionSheet.addAction(UIAlertAction(title: "by Set/Type".localized().checked(self.sortType == .bySetType)) { action in
            self.changeDeckSort(.bySetType)
        })
        self.actionSheet.addAction(UIAlertAction(title: "by Set/Number".localized().checked(self.sortType == .bySetNum)) { action in
            self.changeDeckSort(.bySetNum)
        })
        self.actionSheet.addAction(UIAlertAction.actionSheetCancel() { action in
            self.actionSheet = nil
        })
        
        let popover = self.actionSheet.popoverPresentationController
        popover?.barButtonItem = sender
        popover?.sourceView = self.view
        popover?.permittedArrowDirections = .any
        self.actionSheet.view.layoutIfNeeded()
        
        self.present(self.actionSheet, animated: false, completion: nil)
    }
    
    private func changeDeckSort(_ sortType: DeckSort) {
        self.sortType = sortType
        self.actionSheet = nil
        self.refresh()
    }
    
    // MARK: - export
    
    func exportDeck(_ sender: UIBarButtonItem) {
        if self.actionSheet != nil {
            return self.dismissActionSheet()
        }
        
        if self.printController != nil {
            return self.dismissPrintController()
        }
        
        self.actionSheet = UIAlertController.actionSheet(title: nil, message: nil)
        
        if Defaults[.useDropbox] {
            self.actionSheet.addAction(UIAlertAction(title: "Dropbox: OCTGN".localized()) { action in
                Analytics.logEvent(.exportO8D)
                self.octgnExport()
            })
            self.actionSheet.addAction(UIAlertAction(title: "Dropbox: BBCode".localized()) { action in
                Analytics.logEvent(.exportBBCode)
                DeckExport.asBBCode(self.deck)
                self.actionSheet = nil
            })
            self.actionSheet.addAction(UIAlertAction(title: "Dropbox: Markdown".localized()) { action in
                Analytics.logEvent(.exportMD)
                DeckExport.asMarkdown(self.deck)
                self.actionSheet = nil
            })
            self.actionSheet.addAction(UIAlertAction(title: "Dropbox: Plain Text".localized()) { action in
                Analytics.logEvent(.exportText)
                DeckExport.asPlaintext(self.deck)
                self.actionSheet = nil
            })
        }
        
        self.actionSheet.addAction(UIAlertAction(title: "Clipboard: BBCode".localized()) { action in
            Analytics.logEvent(.clipBBCode)
            UIPasteboard.general.string = DeckExport.asBBCodeString(self.deck)
            DeckImport.updateCount()
            self.actionSheet = nil
        })
        self.actionSheet.addAction(UIAlertAction(title: "Clipboard: Markdown".localized()) { action in
            Analytics.logEvent(.clipMD)
            UIPasteboard.general.string = DeckExport.asMarkdownString(self.deck)
            DeckImport.updateCount()
            self.actionSheet = nil
        })
        self.actionSheet.addAction(UIAlertAction(title: "Clipboard: Plain Text".localized()) { action in
            Analytics.logEvent(.clipText)
            UIPasteboard.general.string = DeckExport.asPlaintextString(self.deck)
            DeckImport.updateCount()
            self.actionSheet = nil
        })
        
        if DeckEmail.canSendMail() {
            self.actionSheet.addAction(UIAlertAction(title: "As Email".localized()) { action in
                Analytics.logEvent(.emailDeck)
                DeckEmail.emailDeck(self.deck, fromViewController: self)
                self.actionSheet = nil
            })
        }
        
        if UIPrintInteractionController.isPrintingAvailable {
            self.actionSheet.addAction(UIAlertAction(title: "Print".localized()) { action in
                Analytics.logEvent(.printDeck)
                self.printDeck(self.exportButton)
                self.actionSheet = nil
            })
        }
        
        if Defaults[.useJintekiNet] {
            self.actionSheet.addAction(UIAlertAction(title: "Upload to Jinteki.net".localized()) { action in
                Analytics.logEvent(.uploadJintekiNet)
                JintekiNet.sharedInstance.uploadDeck(self.deck)
                self.actionSheet = nil
            })
        }
        
        self.actionSheet.addAction(UIAlertAction.alertCancel() { action in
            self.actionSheet = nil
        })
        
        let popover = self.actionSheet.popoverPresentationController
        popover?.barButtonItem = sender
        popover?.sourceView = self.view
        popover?.permittedArrowDirections = .any
        self.actionSheet.view.layoutIfNeeded()
        self.present(self.actionSheet, animated: false, completion: nil)
    }
    
    private func dismissActionSheet() {
        self.actionSheet.dismiss(animated: false, completion: nil)
        self.actionSheet = nil
    }
    
    private func octgnExport() {
        if self.deck.identity == nil {
            UIAlertController.alert(withTitle: nil, message: "Deck needs to have an Identity.".localized(), button: "OK".localized())
            return
        }
        if self.deck.cards.count == 0 {
            UIAlertController.alert(withTitle: nil, message: "Deck needs to have Cards.".localized(), button: "OK".localized())
            return
        }
        DeckExport.asOctgn(self.deck, autoSave: false)
        self.actionSheet = nil
    }
    
    // MARK: - toggle view
    
    func toggleView(_ sender: UISegmentedControl) {
        if self.actionSheet != nil {
            return self.dismissActionSheet()
        }
        
        let viewMode = CardView(rawValue: sender.selectedSegmentIndex) ?? .largeTable
        Defaults[.deckViewStyle] = viewMode
        self.doToggleView(viewMode)
    }
    
    private func doToggleView(_ viewMode: CardView) {
        self.tableView.isHidden = viewMode == .image
        self.collectionView.isHidden = viewMode != .image
        
        self.largeCells = viewMode == .largeTable
        
        self.reloadViews()
    }
    
    // MARK: - reload
    
    private func reloadViews() {
        if self.initializing {
            return
        }
        
        if !self.tableView.isHidden {
            self.tableView.reloadData()
        }
        if !self.collectionView.isHidden {
            self.collectionView.reloadData()
        }
    }
    
    // MARK: - notifications
    
    func notesChanged(_ notification: Notification) {
        if self.autoSave {
            self.saveDeckManually(false)
        }
        self.refresh()
    }
    
    func deckChanged(_ notification: Notification) {
        let initialLoad = notification.userInfo?["initialLoad"] as? Bool ?? false
            
        if !initialLoad {
            self.refresh()
        }
        
        if self.autoSave && self.deck.modified {
            self.saveDeckManually(false)
        }
    }
    
    private func refresh() {
        self.initCards()
        self.reloadViews()
        
        self.saveButton.isEnabled = self.deck.modified
        self.drawButton.isEnabled = self.deck.cards.count > 0
        self.analysisButton.isEnabled = self.deck.cards.count > 0
        
        var summary = ""
        let card = self.deck.size == 1 ? "Card".localized() : "Cards".localized()
        summary = "\(deck.size) \(card)"
        if self.deck.identity != nil && !self.deck.isDraft {
            summary += String(format: " · %ld/%ld %@", self.deck.influence, self.deck.influenceLimit, "Influence".localized())
        } else {
            summary += String(format: " · %ld %@", self.deck.influence, "Influence".localized())
        }
        
        if self.role == .corp {
            summary += String(format: " · %ld %@", self.deck.agendaPoints, "AP".localized())
        }
        
        let reasons = self.deck.checkValidity()
        let status = reasons.first ?? "Deck is valid".localized()
        
        self.summaryLabel.text = summary
        self.summaryLabel.textColor = reasons.count == 0 ? .darkGray : .red
        self.statusLabel.text = status
        self.statusLabel.strings = reasons
        self.statusLabel.textColor = reasons.count == 0 ? .darkGray : .red
        
        let set = PackManager.mostRecentPackUsedIn(deck: self.deck)
        self.lastSetLabel.text = String(format: "Cards up to %@".localized(), set)
        
        self.deckNameLabel.text = self.deck.name
        
        self.stateButton.title = DeckState.buttonLabelFor(self.deck.state)
    }
    
    private func initCards() {
        let data = self.deck.dataForTableView(self.sortType)
        self.cards = data.values 
        self.sections = data.sections
    }
    
    func add(card: Card) {
        self.deck.addCard(card, copies: 1)
        self.refresh()
        
        var cardPath: IndexPath?
        var i = 0
        for section in 0 ..< self.cards.count {
            let arr = self.cards[section]
            for row in 0 ..< arr.count {
                let cc = arr[row]
                if !cc.isNull && card.code == cc.card.code {
                    if self.tableView.isHidden {
                        cardPath = IndexPath(item: i, section: 0)
                        break
                    } else {
                        cardPath = IndexPath(row: row, section: section)
                    }
                }
                i += 1
            }
        }
        
        guard let indexPath = cardPath else {
            assert(false, "added card not found")
            return
        }
        
        if !self.tableView.isHidden {
            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
            self.perform(#selector(self.flashTableCell(_:)), with: indexPath, afterDelay: 0.01)
        } else {
            self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            self.perform(#selector(self.flashImageCell(_:)), with: indexPath, afterDelay: 0.01)
        }
        
        if self.autoSave {
            self.saveDeckManually(false)
        }
    }
    
    func flashTableCell(_ indexPath: IndexPath) {
        guard let cell = self.tableView.cellForRow(at: indexPath) else {
            return
        }
        
        UIView.animate(withDuration: 0.1,
                       delay: 0,
                       options: .allowUserInteraction,
                       animations: { cell.backgroundColor = .lightGray },
                       completion: { finished in cell.backgroundColor = .white })
    }
    
    func flashImageCell(_ indexPath: IndexPath) {
        guard let cell = self.collectionView.cellForItem(at: indexPath) else {
            return
        }
        
        UIView.animate(withDuration: 0.1,
                       delay: 0,
                       options: .allowUserInteraction,
                       animations: { cell.transform = CGAffineTransform(scaleX: 1.05, y: 1.05) },
                       completion: { finished in cell.transform = CGAffineTransform.identity })
    }
    
    // MARK: - table view
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.largeCells ? 83 : 40
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.tableView.isHidden ? 0 : self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cards[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let arr = self.cards[section]
        let count = arr.reduce(0) { $0 + $1.count }
        
        if section > 0 && count > 0 {
            return "\(self.sections[section]) (\(count))"
        } else {
            return self.sections[section]
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = self.largeCells ? "largeCardCell" : "smallCardCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! CardCell
        
        cell.delegate = self
        cell.separatorInset = UIEdgeInsets.zero
        let cc = self.cards[indexPath.section][indexPath.row]
        cell.deck = self.deck
        cell.cardCounter = cc.isNull ? nil : cc
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let cc = self.cards[indexPath.section][indexPath.row]
        return !cc.isNull
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let cc = self.cards[indexPath.section][indexPath.row]
            if !cc.isNull {
                self.deck.addCard(cc.card, copies: 0)
            }
            
            NotificationCenter.default.post(name: Notifications.deckChanged, object: self)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cc = self.cards[indexPath.section][indexPath.row]
        if !cc.isNull {
            let rect = self.tableView.rectForRow(at: indexPath)
            CardImageViewPopover.show(for: cc.card, from: rect, in: self, subView: self.tableView)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Remove".localized()
    }
    
    // MARK: - collection view
    
    private let cardWidth = 225.0
    private let cardHeight = 333.0
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Int(self.scale * self.cardWidth), height: Int(self.scale * self.cardHeight))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 2, left: 2, bottom: 0, right: 2)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.collectionView.isHidden ? 0 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1 + self.deck.cards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.row
        var cc: CardCounter?
        if index == 0 {
            if self.deck.identity != nil {
                cc = self.deck.identityCc
            }
        } else {
            cc = self.deck.cards[index - 1]
        }
        
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        let rect = collectionView.convert(cell.frame, to: collectionView.superview)
        
        let topVisible = rect.origin.y >= 66
        let bottomVisible = rect.origin.y + rect.size.height <= 728
        
        let popupHeight: CGFloat = 170 // full height (including the arrow) of the popup
        let labelHeight: CGFloat = 20 // height of the label underneath the image
        
        var direction = UIPopoverArrowDirection.any
        var popupOrigin = CGRect(x: cell.center.x, y: cell.frame.origin.y, width: 1, height: 1)
        
        if topVisible && bottomVisible {
            direction = .up
        } else if topVisible {
            if rect.origin.y < 728 - popupHeight {
                // top Visible and enough space - show from top of image
                direction = .up
            } else {
                // top visible, not enough space - show above image
                direction = .down
            }
        } else if bottomVisible {
            popupOrigin.origin.y += cell.frame.size.height - labelHeight
            if rect.origin.y + rect.size.height >= 66 + popupHeight {
                // bottom visible and enough space - show from bottom
                direction = .down
            } else {
                // bottom visible, not enough space - show below image
                direction = .up
            }
        } else {
            assert(false, "invisible cell???")
        }
        
        if cc != nil && cc?.card.type != .identity {
            CardImagePopup.showFor(cc: cc!, inDeck: self.deck, from: popupOrigin, inViewController: self, subView: self.collectionView, direction: direction)
        } else {
            self.selectIdentity(self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cardImageCell", for: indexPath) as! CardImageCell
        
        let index = indexPath.row
        var cc: CardCounter?
        
        if index == 0 {
            if self.deck.identity != nil {
                cc = self.deck.identityCc
            }
            cell.copiesLabel.text = ""
        } else {
            let cc2 = self.deck.cards[index - 1]
            cc = cc2
            
            if cc2.card.type == .agenda {
                cell.copiesLabel.text = String(format: "×%lu · %lu AP", cc2.count, cc2.count * cc2.card.agendaPoints)
            } else {
                let influence = self.deck.influenceFor(cc2)
                if influence > 0 {
                    cell.copiesLabel.text = String(format: "×%lu · %lu %@", cc2.count, influence, "Influence".localized())
                } else {
                    cell.copiesLabel.text = "×\(cc2.count)"
                }
            }
            
            cell.copiesLabel.textColor = .black
            if !self.deck.isDraft && cc2.card.owned < cc2.count {
                cell.copiesLabel.textColor = .red
            }
        }
        
        if cc != nil {
            cell.loadImage(for: cc!)
        } else {
            cell.setImageStack(ImageCache.placeholder(for: self.role))
        }
        
        return cell
    }
    
    private var scaleStart = 0.0
    private var startIndex: IndexPath?
    
    func pinchGesture(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began {
            self.scaleStart = self.scale
            let startPoint = gesture.location(in: self.collectionView)
            self.startIndex = self.collectionView.indexPathForItem(at: startPoint)
        } else if gesture.state == .changed {
            self.scale = scaleStart * Double(gesture.scale)
            self.scale = max(self.scale, 0.5)
            self.scale = min(self.scale, 1.0)
            
            self.collectionView.reloadData()
            
            if let index = startIndex, index.row < self.deck.cards.count {
                self.collectionView.scrollToItem(at: index, at: .centeredVertically, animated: false)
            }
        } else if gesture.state == .ended {
            self.startIndex = nil
        }
    }
    
    func longPressGesture(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else {
            return
        }
        
        let point = gesture.location(in: self.collectionView)
        if let indexPath = self.collectionView.indexPathForItem(at: point) {
            let index = indexPath.row
            var cc: CardCounter?
            if index == 0 {
                if self.deck.identity != nil {
                    cc = self.deck.identityCc
                }
            } else {
                cc = self.deck.cards[index - 1]
            }
            
            guard let cell = collectionView.cellForItem(at: indexPath), let card = cc?.card else {
                return
            }
            
            CardImageViewPopover.show(for: card, mwl: self.deck.mwl, from: cell.frame, in: self, subView: self.collectionView)
        }
    }

    // MARK: - printing
    
    private func dismissPrintController() {
        self.printController.dismiss(animated: false)
        self.printController = nil
    }
    
    private func printDeck(_ sender: UIBarButtonItem) {
        self.printController = UIPrintInteractionController.shared
        self.printController.delegate = self
    
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .general
        printInfo.jobName = self.deck.name
        printInfo.outputType = .grayscale
        self.printController.printInfo = printInfo
        
        let margin: CGFloat = 60 // 30 == 1 cm
        let formatter = UISimpleTextPrintFormatter(text: DeckExport.asPlaintextString(self.deck))
        formatter.startPage = 0
        formatter.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        formatter.font = UIFont.systemFont(ofSize: 10)
        self.printController.printFormatter = formatter
        self.printController.showsPageRange = true
        
        self.printController.present(from: sender, animated: false) { controller, completed, error in
            if !completed && error != nil {
                UIAlertController.alert(withTitle: "Printing Problem".localized(), message: error!.localizedDescription, button: "OK".localized())
            }
        }
    }
    
    func printInteractionControllerDidDismissPrinterOptions(_ printInteractionController: UIPrintInteractionController) {
        self.printController = nil
    }
    
    // MARK: - MWL selection
    
    func statusTapped(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            self.showMwlSelection()
        }
    }
    
    private func showMwlSelection() {
        let alert = UIAlertController.actionSheet(title: "Deck Legality".localized(), message: nil)
        
        alert.addAction(UIAlertAction(title: "Casual".localized().checked(self.deck.mwl == .none && !self.deck.onesies)) { action in
            self.setMwl(.none, cacheRefresh: .none, onesies: false)
        })
        alert.addAction(UIAlertAction(title: "MWL v1.0".localized().checked(self.deck.mwl == .v1_0)) { action in
            self.setMwl(.v1_0, cacheRefresh: .none, onesies: false)
        })

        alert.addAction(UIAlertAction(title: "MWL v1.1".localized().checked(self.deck.mwl == .v1_1)) { action in
            self.setMwl(.v1_1, cacheRefresh: .none, onesies: false)
        })
        
        alert.addAction(UIAlertAction(title: "MWL v1.2".localized().checked(self.deck.mwl == .v1_2)) { action in
            self.setMwl(.v1_2, cacheRefresh: .none, onesies: false)
        })

        alert.addAction(UIAlertAction(title: "1.1.1.1".localized().checked(self.deck.onesies)) { action in
            self.setMwl(.none, cacheRefresh: .none, onesies: true)
        })

        alert.addAction(UIAlertAction(title: "Cache Refresh".localized().checked(self.deck.cacheRefresh == .r2017)) { action in
            self.setMwl(CacheRefresh.r2017.mwl, cacheRefresh: .r2017, onesies: false)
        })
        
        alert.addAction(UIAlertAction.actionSheetCancel(nil))
        
        let popover = alert.popoverPresentationController
        popover?.sourceRect = self.footerView.frame
        popover?.sourceView = self.view
        popover?.permittedArrowDirections = .down
        
        alert.view.layoutIfNeeded()
        self.present(alert, animated: false, completion: nil)
    }
    
    private func setMwl(_ newMwl: MWL, cacheRefresh: CacheRefresh, onesies: Bool) {
        if self.deck.mwl != newMwl || self.deck.onesies != onesies || self.deck.cacheRefresh != cacheRefresh {
            self.deck.mwl = newMwl
            self.deck.onesies = onesies
            self.deck.cacheRefresh = cacheRefresh
            
            NotificationCenter.default.post(name: Notifications.deckChanged, object: self)
        }
    }
    
}

extension DeckListViewController: KeyboardHandling {
    // MARK: - keyboard show/hide
    
    func keyboardWillShow(_ info: KeyboardInfo) {
        
        let screenHeight = UIScreen.main.bounds.size.height
        let kbHeight = screenHeight - info.endFrame.origin.y
        self.toolbarBottomMargin.constant = kbHeight
        
        UIView.animate(withDuration: info.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    func keyboardWillHide(_ info: KeyboardInfo) {
        self.toolbarBottomMargin.constant = 0
        UIView.animate(withDuration: info.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }

}
