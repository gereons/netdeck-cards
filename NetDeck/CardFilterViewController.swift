//
//  CardFilterViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 18.01.17.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

class CardFilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, FilterCallback {
 
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var scopeButton: UIButton!
    
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var subtypeButton: UIButton!
    @IBOutlet weak var factionButton: UIButton!
    @IBOutlet weak var setButton: UIButton!
    
    @IBOutlet weak var influenceLabel: UILabel!
    @IBOutlet weak var influenceSlider: UISlider!
    
    @IBOutlet weak var strengthLabel: UILabel!
    @IBOutlet weak var strengthSlider: UISlider!
    
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var costSlider: UISlider!
    
    @IBOutlet weak var muLabel: UILabel!
    @IBOutlet weak var muSlider: UISlider!
    
    @IBOutlet weak var apLabel: UILabel!
    @IBOutlet weak var apSlider: UISlider!
    
    @IBOutlet weak var moreLessButton: UIButton!
    @IBOutlet weak var viewModeControl: UISegmentedControl!
    
    @IBOutlet weak var searchContainer: UIView!
    @IBOutlet weak var searchSeparator: UIView!
    @IBOutlet weak var sliderContainer: UIView!
    @IBOutlet weak var sliderSeparator: UIView!
    @IBOutlet weak var buttonContainer: UIView!
    @IBOutlet weak var bottomSeparator: UIView!
    @IBOutlet weak var influenceSeparator: UIView!
    
    @IBOutlet weak var tableViewTopMargin: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottomMargin: NSLayoutConstraint!
    @IBOutlet weak var collectionViewTopMargin: NSLayoutConstraint!
    @IBOutlet weak var collectionViewBottomMargin: NSLayoutConstraint!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var deckListViewController: DeckListViewController
    private var navController: UINavigationController
    
    private var revertButton: UIBarButtonItem!
    private var role = NRRole.none
    private var cardList: CardList!
    private var cards = [[Card]]()
    private var sections = [String]()
    
    private var packUsage = NRPackUsage.all
    private var searchText = ""
    private var scope = NRSearchScope.all
    private var sendNotification = false
    private var selectedType = ""
    private var selectedTypes: Set<String>?
    private var selectedValues = [Button: Any]()
    private var searchFieldActive = false
    private var influenceValue = -1
    
    private var prevAp = 0
    private var prevMu = 0
    private var prevStr = 0
    private var prevCost = 0
    private var prevInf = 0
    
    private let largeCellHeight = 140
    private let smallCellHeight = 107
    
    enum Button: Int {
        case type, faction, set, subtype
    }
    
    enum View: Int {
        case list, img2, img3
    }
    
    enum Add: Int {
        case table, collection
    }
    
    private let scopes: [NRSearchScope: String] = [
        .all: "all text",
        .name: "card name",
        .text: "card text"
    ]
    private let scopeLabels: [NRSearchScope: String] = [
        .all: "All".localized(),
        .name: "Name".localized(),
        .text: "Text".localized()
    ]
    private var showAllFilters = true
    private var viewMode = View.list
    
    init(role: NRRole) {
        self.deckListViewController = DeckListViewController()
        self.navController = UINavigationController(rootViewController: self.deckListViewController)
        
        super.init(nibName: "CardFilterViewController", bundle: nil)
        
        self.role = role
        self.deckListViewController.role = role
    }
    
    convenience init(role: NRRole, andFile file: String) {
        self.init(role: role)
        
        self.deckListViewController.loadDeck(fromFile: file)
    }
    
    convenience init(role: NRRole, andDeck deck: Deck) {
        self.init(role: role)
        
        assert(role == deck.role, "role mismatch")
        self.deckListViewController.deck = deck
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settings = UserDefaults.standard
        self.showAllFilters = settings.bool(forKey: SettingsKeys.SHOW_ALL_FILTERS)
        self.viewMode = View(rawValue: settings.integer(forKey: SettingsKeys.FILTER_VIEW_MODE)) ?? .list
        
        self.view.backgroundColor = .white
        self.navigationController?.navigationBar.backgroundColor = .white
        
        self.packUsage = NRPackUsage(rawValue: settings.integer(forKey: SettingsKeys.DECKBUILDER_PACKS)) ?? .all
        
        self.cardList = CardList(forRole: self.role, packUsage: packUsage)
        self.initCards()
        
        self.tableView.register(UINib(nibName: "CardFilterCell", bundle: nil), forCellReuseIdentifier: "cardCell")
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        self.collectionView.register(UINib(nibName: "CardFilterThumbView", bundle: nil), forCellWithReuseIdentifier: "cardThumb")
        self.collectionView.register(CollectionViewSectionHeader.nib(), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "sectionHeader")
        self.collectionView.alwaysBounceVertical = true
        
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.headerReferenceSize = CGSize(width: 320, height: 22)
        layout.sectionInset = UIEdgeInsetsMake(2, 2, 0, 2)
        layout.minimumInteritemSpacing = 3
        layout.minimumLineSpacing = 3
        layout.sectionHeadersPinToVisibleBounds = true
        
        let moreLess = self.showAllFilters ? "Less △".localized() : "More ▽".localized()
        self.moreLessButton.setTitle(moreLess, for: .normal)
        self.influenceSeparator.isHidden = self.showAllFilters
        
        self.viewModeControl.selectedSegmentIndex = self.viewMode.rawValue
        self.collectionView.isHidden = self.viewMode == .list
        self.tableView.isHidden = self.viewMode != .list
        
        self.revertButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.revertDeck(_:)))
        
        self.resetAllButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.edgesForExtendedLayout = .bottom
        
        let detailViewManager = self.splitViewController?.delegate as! DetailViewManager
        detailViewManager.detailViewController = self.navController
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.willShowKeyboard(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        nc.addObserver(self, selector: #selector(self.willHideKeyboard(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
        nc.addObserver(self, selector: #selector(self.addTopCard(_:)), name: Notifications.addTopCard, object: nil)
        nc.addObserver(self, selector: #selector(self.deckChanged(_:)), name: Notifications.deckChanged, object: nil)
        nc.addObserver(self, selector: #selector(self.deckSaved(_:)), name: Notifications.deckSaved, object: nil)
        nc.addObserver(self, selector: #selector(self.nameAlertWillAppear(_:)), name: Notifications.nameAlert, object: nil)
        
        self.setResultFrames()
        self.initFilters()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let topItem = self.navigationController?.navigationBar.topItem
        topItem?.title = "Filter".localized()
        topItem?.rightBarButtonItem = UIBarButtonItem(title: "Clear".localized(), style: .plain, target: self, action: #selector(self.clearFiltersClicked(_:)))
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        let settings = UserDefaults.standard
        settings.set(self.showAllFilters, forKey: SettingsKeys.SHOW_ALL_FILTERS)
        settings.set(self.viewMode.rawValue, forKey: SettingsKeys.FILTER_VIEW_MODE)
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "F", modifierFlags: .command, action: #selector(self.startTextSearch(_:)), discoverabilityTitle: "Find Card".localized()),
            UIKeyCommand(input: "A", modifierFlags: .command, action: #selector(self.changeScopeKeyCmd(_:)), discoverabilityTitle: "Scope All".localized()),
            UIKeyCommand(input: "N", modifierFlags: .command, action: #selector(self.changeScopeKeyCmd(_:)), discoverabilityTitle: "Scope: Name".localized()),
            UIKeyCommand(input: "T", modifierFlags: .command, action: #selector(self.changeScopeKeyCmd(_:)), discoverabilityTitle: "Scope: Text".localized()),
            UIKeyCommand(input: UIKeyInputEscape, modifierFlags: [], action: #selector(self.escKeyPressed(_:)))
        ]
    }
    
    func startTextSearch(_ cmd: UIKeyCommand) {
        self.searchField.becomeFirstResponder()
    }
    
    func escKeyPressed(_ cmd: UIKeyCommand) {
        self.searchField.resignFirstResponder()
    }
    
    func setResultFrames() {
        self.tableViewTopMargin.constant = self.showAllFilters ? 0 : -129
        self.collectionViewTopMargin.constant = self.showAllFilters ? 0 : -129
    }
    
    func initCards() {
        let data = self.cardList.dataForTableView()
        self.cards = data.values
        self.sections = data.sections
    }
    
    func deckChanged(_ notification: Notification) {
        guard let deck = self.deckListViewController.deck else {
            return
        }
        if let identity = deck.identity {
            if self.role == .runner {
                self.cardList.preFilterForRunner(identity)
            } else {
                self.cardList.preFilterForCorp(identity)
            }
        }
        self.initCards()
        
        if self.influenceValue != -1 {
            if let identity = deck.identity {
                self.cardList.filterByInfluence(self.influenceValue, forFaction: identity.faction)
            } else {
                self.cardList.filterByInfluence(self.influenceValue)
            }
            self.initCards()
        }
        
        self.setBackOrRevertButton(deck.modified)
        
        self.reloadData()
    }
    
    func deckSaved(_ notification: Notification) {
        self.setBackOrRevertButton(false)
    }
    
    func setBackOrRevertButton(_ modified: Bool) {
        let autoSave = UserDefaults.standard.bool(forKey: SettingsKeys.AUTO_SAVE)
        if autoSave {
            return
        }
        
        let topItem = self.navigationController?.navigationBar.topItem
        topItem?.leftBarButtonItem = modified ? self.revertButton : nil
    }
    
    func revertDeck(_ sender: UIBarButtonItem) {
        if let filename = self.deckListViewController.deck.filename {
            let deck = DeckManager.loadDeckFromPath(filename, useCache: false)
            self.reloadData()
            self.deckListViewController.deck = deck
            self.setBackOrRevertButton(false)
        } else {
            self.navigationController?.navigationBar.topItem?.leftBarButtonItem = nil
            let _ = self.navigationController?.popToRootViewController(animated: false)
        }
    }
    
    func initFilters() {
        self.setRole(self.role)
        
        self.typeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.setButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.factionButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.subtypeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        self.typeButton.tag = Button.type.rawValue
        self.setButton.tag = Button.set.rawValue
        self.factionButton.tag = Button.faction.rawValue
        self.subtypeButton.tag = Button.subtype.rawValue
        
        self.costSlider.maximumValue = Float(1 + CardManager.maxCost(for: self.role))
        self.muSlider.maximumValue = Float(1 + CardManager.maxMU)
        self.strengthSlider.maximumValue = Float(1 + CardManager.maxStrength)
        self.influenceSlider.maximumValue = Float(1 + CardManager.maxInfluence)
        self.apSlider.maximumValue = Float(1 + CardManager.maxAgendaPoints)
        
        self.costSlider.setThumbImage(UIImage(named: "credit_slider"), for: .normal)
        self.muSlider.setThumbImage(UIImage(named: "mem_slider"), for: .normal)
        self.strengthSlider.setThumbImage(UIImage(named: "strength_slider"), for: .normal)
        self.influenceSlider.setThumbImage(UIImage(named: "influence_slider"), for: .normal)
        self.apSlider.setThumbImage(UIImage(named: "point_slider"), for: .normal)
        
        self.searchField.placeholder = "Search Cards".localized()
        self.searchField.clearButtonMode = .always
        
        self.clearFilters()
    }
    
    func setRole(_ role: NRRole) {
        self.role = role
        
        self.muLabel.isHidden = role == .corp
        self.muSlider.isHidden = role == .corp
        self.apLabel.isHidden = role == .runner
        self.apSlider.isHidden = role == .runner
    }
    
    func reloadData() {
        if self.viewMode == .list {
            self.tableView.reloadData()
        } else {
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.reloadData()
        }
    }
    
    // MARK: - clear filters
    
    @IBAction func clearFiltersClicked(_ sender: Any) {
        self.cardList.clearFilters()
        self.clearFilters()
        
        self.initCards()
        self.reloadData()
    }
    
    func clearFilters() {
        self.sendNotification = false
        
        self.scope = .name
        self.scopeButton.setTitle(self.scopeLabels[self.scope]! + DeckState.arrow, for: .normal)
        self.scopeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.scopeButton.titleLabel?.minimumScaleFactor = 0.5
        
        self.searchField.text = ""
        self.searchText = ""
        
        self.costSlider.value = 0
        self.costValueChanged(self.costSlider)
        self.prevCost = 0
        
        self.muSlider.value = 0
        self.muValueChanged(self.muSlider)
        self.prevMu = 0
        
        self.influenceSlider.value = 0
        self.influenceValueChanged(self.influenceSlider)
        self.prevInf = 0
        self.influenceValue = -1
        
        self.strengthSlider.value = 0
        self.strengthValueChanged(self.strengthSlider)
        self.prevStr = 0
        
        self.apSlider.value = 0
        self.apValueChanged(self.apSlider)
        self.prevAp = 0
        
        self.resetAllButtons()
        self.selectedType = Constant.kANY
        self.selectedTypes = nil
        
        self.selectedValues.removeAll()
        
        self.sendNotification = true
    }
    
    func addTopCard(_ notification: Notification) {
        if self.cards.count > 0 {
            let cards = self.cards[0]
            if cards.count > 0 {
                let card = cards[0]
                self.deckListViewController.add(card: card)
                let deck = self.deckListViewController.deck
                self.setBackOrRevertButton(deck?.modified ?? false)
                self.reloadData()
            }
        }
    }
    
    // MARK: - keyboard show/hide
    
    func willShowKeyboard(_ notification: Notification) {
        if !self.searchField.isFirstResponder {
            return
        }
        
        self.searchFieldActive = true
        self.moreLessButton.isHidden = true
        
        guard let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue,
            let animDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        let screenHeight = UIScreen.main.bounds.size.height
        let kbHeight = screenHeight - keyboardFrame.cgRectValue.origin.y
        
        self.tableViewBottomMargin.constant = kbHeight
        self.collectionViewBottomMargin.constant = kbHeight
        self.tableViewTopMargin.constant = -242
        self.collectionViewTopMargin.constant = -242
        
        UIView.animate(withDuration: animDuration) {
            self.tableView.layoutIfNeeded()
            self.collectionView.layoutIfNeeded()
        }
    }
    
    func willHideKeyboard(_ notification: Notification) {
        if self.searchFieldActive {
            self.searchField.resignFirstResponder()
        }
        
        self.searchFieldActive = false
        self.moreLessButton.isHidden = false
        
        guard let animDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        self.tableViewBottomMargin.constant = 0
        self.collectionViewBottomMargin.constant = 0
        
        self.setResultFrames()
        
        UIView.animate(withDuration: animDuration) {
            self.tableView.layoutIfNeeded()
            self.collectionView.layoutIfNeeded()
        }
    }
    
    func nameAlertWillAppear(_ notification: Notification) {
        if self.searchField.isFirstResponder {
            self.searchField.resignFirstResponder()
        }
    }
    
    // MARK: - button callbacks
    
    @IBAction func moreLessClicked(_ sender: Any) {
        self.showAllFilters = !self.showAllFilters
        
        if !self.showAllFilters {
            // reset all filters that are now inaccessible
            self.costSlider.value = 0
            self.costValueChanged(self.costSlider)
            self.muSlider.value = 0
            self.muValueChanged(self.muSlider)
            self.strengthSlider.value = 0
            self.strengthValueChanged(self.strengthSlider)
            self.apSlider.value = 0
            self.apValueChanged(self.apSlider)
        }
        
        if self.searchField.isFirstResponder {
            self.searchField.resignFirstResponder()
        }
        
        let moreLess = self.showAllFilters ? "Less △".localized() : "More ▽".localized()
        self.moreLessButton.setTitle(moreLess, for: .normal)
        
        if self.showAllFilters {
            self.influenceSeparator.isHidden = true
        }
        
        self.setResultFrames()
        UIView.animate(withDuration: 0.10,
            animations: {
                self.tableView.layoutIfNeeded()
                self.collectionView.layoutIfNeeded()
            },
            completion: { finished in
                self.influenceSeparator.isHidden = self.showAllFilters
            })
    }
    
    @IBAction func viewModeChanged(_ sender: UISegmentedControl) {
        var scrollToPath: IndexPath?
        
        if viewMode == .list {
            if let visible = self.tableView.indexPathsForVisibleRows {
                for indexPath in visible {
                    let rect = self.tableView.rectForRow(at: indexPath)
                    let visible = self.tableView.frame.contains(rect)
                    if visible {
                        scrollToPath = indexPath
                        break
                    }
                }
            }
        } else {
            let visible = self.collectionView.indexPathsForVisibleItems.sorted()
            for indexPath in visible {
                let cell = self.collectionView.cellForItem(at: indexPath)!
                let rect = self.collectionView.convert(cell.frame, to: self.collectionView.superview)
                let visible = self.collectionView.frame.contains(rect)
                if visible {
                    scrollToPath = indexPath
                    break
                }
            }
        }
        
        self.viewMode = View(rawValue: sender.selectedSegmentIndex) ?? .list
        self.collectionView.isHidden = self.viewMode == .list
        self.tableView.isHidden = self.viewMode != .list
        
        self.reloadData()
        
        if let scrollTo = scrollToPath {
            if !self.tableView.isHidden {
                self.tableView.scrollToRow(at: scrollTo, at: .top, animated: false)
            }
            if !self.collectionView.isHidden {
                // sadly, this does not work:
                // self.collectionView.scrollToItem(at: scrollTo, at: .top, animated: false)
                // so we compute scroll offset manually
                
                let y: Int
                if viewMode == .img2 {
                    y = scrollTo.row / 2 * (self.largeCellHeight + 3)
                } else {
                    y = scrollTo.row / 3 * (self.smallCellHeight + 3)
                }
                self.collectionView.setContentOffset(CGPoint(x: 0, y: y), animated: false)
            }
        }
    }
    
    @IBAction func typeClicked(_ sender: UIButton) {
        let data = TableData(values: CardType.typesFor(role: self.role))
        let selected = self.selectedValues[.type]
        
        CardFilterPopover.showFrom(button: sender, inView: self, entries: data, type: "Type", selected: selected)
    }
    
    @IBAction func setClicked(_ sender: UIButton) {
        let stringPacks: TableData<String> = PackManager.packsForTableView(packUsage: self.packUsage)
        let selected = self.selectedValues[.set]
        
        CardFilterPopover.showFrom(button: sender, inView: self, entries: stringPacks, type: "Set", selected: selected)
    }
    
    @IBAction func subtypeClicked(_ sender: UIButton) {
        var arr: [String]
        if let selected = self.selectedTypes {
            arr = CardManager.subtypesFor(role: self.role, andTypes: selected, includeIdentities: true)
        } else {
            arr = CardManager.subtypesFor(role: self.role, andType: self.selectedType, includeIdentities: true)
        }
        
        arr.insert(Constant.kANY, at: 0)
        let data = TableData(values: arr)
        let selected = self.selectedValues[.subtype]
        
        CardFilterPopover.showFrom(button: sender, inView: self, entries: data, type: "Subtype", selected: selected)
    }
    
    @IBAction func factionClicked(_ sender: UIButton) {
        let data = TableData(values: Faction.factionsFor(role: self.role, packUsage: self.packUsage))
        let selected = self.selectedValues[.faction]
        
        CardFilterPopover.showFrom(button: sender, inView: self, entries: data, type: "Faction", selected: selected)
    }
    
    func filterCallback(_ button: UIButton, type: String, value object: Any) {
        let value = object as? String
        let values = object as? Set<String>
        assert(value != nil || values != nil, "values")
        
        if button.tag == Button.type.rawValue {
            if let v = value {
                self.selectedType = v
                self.selectedTypes = nil
            } else if let v = values {
                self.selectedType = ""
                self.selectedTypes = v
            }
            
            self.resetButton(.subtype)
        }
        
        let tag = Button(rawValue: button.tag) ?? .type
        self.selectedValues[tag] = value == nil ? values : value
        
        self.updateFilter(type, value: object)
    }
    
    func resetAllButtons() {
        self.resetButton(.type)
        self.resetButton(.set)
        self.resetButton(.faction)
        self.resetButton(.subtype)
    }
    
    func resetButton(_ tag: Button) {
        let button: UIButton
        let prefix: String
        switch tag {
        case .type:
            button = self.typeButton
            prefix = "Type"
            self.resetButton(.subtype)
        case .set:
            button = self.setButton
            prefix = "Set"
        case .subtype:
            button = self.subtypeButton
            prefix = "Subtype"
        case .faction:
            button = self.factionButton
            prefix = "Faction"
        }
        
        self.selectedValues[tag] = Constant.kANY
        
        self.updateFilter(prefix.lowercased(), value: Constant.kANY)
        let title = prefix.localized() + ": " + Constant.kANY.localized()
        button.setTitle(title, for: .normal)
    }
    
    // MARK: - slider callbacks
    
    @IBAction func strengthValueChanged(_ sender: UISlider) {
        var value = Int(round(sender.value))
        sender.value = Float(value)
        value -= 1
        if value != self.prevStr {
            self.strengthLabel.text = String(format: "Strength: %@".localized(), value == -1 ? "All".localized() : "\(value)")
            self.updateFilter("strength", value: value)
            self.prevStr = value
        }
    }
    
    @IBAction func muValueChanged(_ sender: UISlider) {
        var value = Int(round(sender.value))
        sender.value = Float(value)
        value -= 1
        if value != self.prevMu {
            self.muLabel.text = String(format: "MU: %@".localized(), value == -1 ? "All".localized() : "\(value)")
            self.updateFilter("mu", value: value)
            self.prevMu = value
        }
    }
    
    @IBAction func costValueChanged(_ sender: UISlider) {
        var value = Int(round(sender.value))
        sender.value = Float(value)
        value -= 1
        if value != self.prevCost {
            self.costLabel.text = String(format: "Cost: %@".localized(), value == -1 ? "All".localized() : "\(value)")
            self.updateFilter("cost", value: value)
            self.prevCost = value
        }
    }
    
    @IBAction func influenceValueChanged(_ sender: UISlider) {
        var value = Int(round(sender.value))
        sender.value = Float(value)
        value -= 1
        if value != self.prevInf {
            self.influenceLabel.text = String(format: "Influence: %@".localized(), value == -1 ? "All".localized() : "\(value)")
            self.updateFilter("influence", value: value)
            self.prevInf = value
        }
    }
    
    @IBAction func apValueChanged(_ sender: UISlider) {
        var value = Int(round(sender.value))
        sender.value = Float(value)
        value -= 1
        if value != self.prevAp {
            self.apLabel.text = String(format: "AP: %@".localized(), value == -1 ? "All".localized() : "\(value)")
            self.updateFilter("agendaPoints", value: value)
            self.prevAp = value
        }
    }
    
    // MARK: - scope
    
    @IBAction func scopeClicked(_ sender: UIButton) {
        let sheet = UIAlertController.actionSheet(title: nil, message: nil)
        
        sheet.addAction(UIAlertAction(title: "All".localized().checked(self.scope == .all)) { action in
            self.changeScope(.all)
        })
        sheet.addAction(UIAlertAction(title: "Name".localized().checked(self.scope == .name)) { action in
            self.changeScope(.name)
        })
        sheet.addAction(UIAlertAction(title: "Text".localized().checked(self.scope == .text)) { action in
            self.changeScope(.text)
        })
        sheet.addAction(UIAlertAction.actionSheetCancel(nil))
        
        let popover = sheet.popoverPresentationController
        popover?.sourceRect = sender.frame
        popover?.sourceView = self.view
        popover?.permittedArrowDirections = .up
        sheet.view.layoutIfNeeded()
        
        self.present(sheet, animated: false, completion: nil)
    }
    
    func changeScopeKeyCmd(_ cmd: UIKeyCommand) {
        if cmd.input.lowercased() == "a" {
            self.changeScope(.all)
        } else if cmd.input.lowercased() == "n" {
            self.changeScope(.name)
        } else if cmd.input.lowercased() == "t" {
            self.changeScope(.text)
        }
    }
    
    func changeScope(_ scope: NRSearchScope) {
        self.scope = scope
        self.scopeButton.setTitle(self.scopeLabels[self.scope]! + DeckState.arrow, for: .normal)
        
        self.updateFilter(self.scopes[self.scope]!, value: self.searchText)
    }
    
    // MARK: - text search
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if CardImageViewPopover.dismiss() {
            return false
        }
        
        let text = textField.text! as NSString
        self.searchText = text.replacingCharacters(in: range, with: string)
        
        self.updateFilter(self.scopes[self.scope]!, value: self.searchText)
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if CardImageViewPopover.dismiss() {
            return false
        }
        
        self.searchText = ""
        self.updateFilter(self.scopes[self.scope]!, value: self.searchText)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if CardImageViewPopover.dismiss() {
            return false
        }
        
        if self.searchText.length > 0 {
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
            NotificationCenter.default.post(name: Notifications.addTopCard, object: self)
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // MARK: - filter update
    
    func updateFilter(_ type: String, value object: Any) {
        let value = object as? String
        let values = object as? Set<String>
        let num = object as? Int
        
        assert(value != nil || values != nil || num != nil, "invalid values")
        
        switch type {
        case "mu":
            assert(num != nil)
            self.cardList.filterByMU(num!)
        case "cost":
            assert(num != nil)
            self.cardList.filterByCost(num!)
        case "agendaPoints":
            assert(num != nil)
            self.cardList.filterByAgendaPoints(num!)
        case "strength":
            assert(num != nil)
            self.cardList.filterByStrength(num!)
        case "influence":
            assert(num != nil)
            if let identity = self.deckListViewController.deck?.identity {
                self.cardList.filterByInfluence(num!, forFaction: identity.faction)
            } else {
                self.cardList.filterByInfluence(num!)
            }
        
        case "card name":
            assert(value != nil)
            self.cardList.filterByName(value!)
        case "card text":
            assert(value != nil)
            self.cardList.filterByText(value!)
        case "all text":
            assert(value != nil)
            self.cardList.filterByTextOrName(value!)
            
        case "faction":
            if let v = value {
                self.cardList.filterByFaction(v)
            } else {
                self.cardList.filterByFactions(values!)
            }
        case "set":
            if let v = value {
                self.cardList.filterBySet(v)
            } else {
                self.cardList.filterBySets(values!)
            }
        case "type":
            if let v = value {
                self.cardList.filterByType(v)
            } else {
                self.cardList.filterByTypes(values!)
            }
        case "subtype":
            if let v = value {
                self.cardList.filterBySubtype(v)
            } else {
                self.cardList.filterBySubtypes(values!)
            }
        default:
            assert(false, "unknown filter \(type)")
        }
        
        self.initCards()
        if self.sendNotification {
            self.reloadData()
        }
    }
    
    // MARK: - table view
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = .colorWithRGB(0xEBEBEC)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 22
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 38
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let cards = self.cards[section]
        return "\(self.sections[section]) (\(cards.count))"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.tableView.isHidden ? 0 : self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cards[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cardCell", for: indexPath) as! CardFilterCell
        
        cell.addButton.tag = Add.table.rawValue
        cell.addButton.addTarget(self, action: #selector(self.addCardToDeck(_:)), for: .touchUpInside)
        
        let deck = self.deckListViewController.deck
        let identity = deck?.identity ?? Card.null()
        let card = self.cards[indexPath.section][indexPath.row]
        
        let influence = identity.faction == card.faction ? 0 : card.influence
        cell.pips.set(value: influence, color: card.factionColor)
        
        cell.nameLabel.text = card.name
        let cc = deck?.findCard(card) ?? CardCounter.null()
        cell.countLabel.text = cc.count > 0 ? "\(cc.count)" : ""
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = self.cards[indexPath.section][indexPath.row]
        let rect = self.tableView.rectForRow(at: indexPath)
        CardImageViewPopover.show(for: card, from: rect, in: self, subView: self.tableView)
    }
    
    func addCardToDeck(_ sender: UIButton) {
        let tappedIndexPath: IndexPath?
        if sender.tag == Add.table.rawValue {
            let point = sender.convert(CGPoint.zero, to: self.tableView)
            tappedIndexPath = self.tableView.indexPathForRow(at: point)
        } else {
            let point = sender.convert(CGPoint.zero, to: self.collectionView)
            tappedIndexPath = self.collectionView.indexPathForItem(at: point)
        }
        
        guard let indexPath = tappedIndexPath else {
            return
        }
        
        let textField = self.searchField!
        if textField.isFirstResponder && (textField.text?.length ?? 0) > 0{
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
        }
        
        let card = self.cards[indexPath.section][indexPath.row]
        self.deckListViewController.add(card: card)
        self.setBackOrRevertButton(self.deckListViewController.deck.modified)
        
        if viewMode == .list {
            self.tableView.reloadData()
        } else {
            self.collectionView.reloadData()
        }
    }
    
    // MARK: - collection view
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let card = self.cards[indexPath.section][indexPath.row]
        let cc = self.deckListViewController.deck.findCard(card) ?? CardCounter.null()
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cardThumb", for: indexPath) as! CardFilterThumbView
        
        cell.addButton.tag = Add.collection.rawValue
        cell.addButton.addTarget(self, action: #selector(self.addCardToDeck(_:)), for: .touchUpInside)
        
        cell.countLabel.text = cc.count > 0 ? "×\(cc.count)" : ""
        cell.card = card
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let card = self.cards[indexPath.section][indexPath.row]
        let cell = collectionView.cellForItem(at: indexPath)!
        let rect = collectionView.convert(cell.frame, to: self.collectionView)
        
        CardImageViewPopover.show(for: card, from: rect, in: self, subView: self.collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return viewMode == .img3 ? CGSize(width: 103, height: self.smallCellHeight) : CGSize(width: 156, height: self.largeCellHeight)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.collectionView.isHidden ? 0 : self.sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.cards[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 2, left: 2, bottom: 0, right: 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeader", for: indexPath) as! CollectionViewSectionHeader
        let cards = self.cards[indexPath.section]
        header.title.text = "\(self.sections[indexPath.section]) (\(cards.count))"
        
        return header
    }
    
}
