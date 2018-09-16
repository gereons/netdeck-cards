//
//  CardFilterViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 18.01.17.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class CardFilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, FilteringViewController {
 
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
    
    @IBOutlet weak var muApLabel: UILabel!
    @IBOutlet weak var muApSlider: UISlider!
    
    @IBOutlet weak var moreLessButton: UIButton!
    @IBOutlet weak var viewModeControl: UISegmentedControl!
    
    @IBOutlet weak var searchContainer: UIView!
    @IBOutlet weak var searchSeparator: UIView!
    @IBOutlet weak var sliderContainer: UIView!
    @IBOutlet weak var sliderSeparator: UIView!
    @IBOutlet weak var buttonContainer: UIView!
    @IBOutlet weak var bottomSeparator: UIView!
    @IBOutlet weak var influenceSeparator: UIView!
    
    @IBOutlet weak var movingSeparator: UIView!
    @IBOutlet weak var resultsTopMargin: NSLayoutConstraint!
    @IBOutlet weak var resultsBottomMargin: NSLayoutConstraint!
    
    @IBOutlet weak var resultsView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var deckListViewController: DeckListViewController
    private var keyboardObserver: KeyboardObserver!
    
    private var revertButton: UIBarButtonItem!
    private var role = Role.none
    private var cardList: CardList!
    private var cards = [[Card]]()
    private var sections = [String]()
    
    private var packUsage = PackUsage.all
    private var searchText = ""
    private var scope = CardSearchScope.all
    private var sendNotification = false
    private var selectedType = ""
    private var selectedTypes: Set<String>?
    private var selectedValues = [FilterAttribute: FilterValue]()
    fileprivate var searchFieldActive = false
    private var influenceValue = -1
    
    private var prevAp = 0
    private var prevMu = 0
    private var prevStr = 0
    private var prevCost = 0
    private var prevInf = 0

    private var legality: DeckLegality

    private let largeCellHeight = 140
    private let smallCellHeight = 107
    
    enum Add: Int {
        case table, collection
    }
    
    private let scopes: [CardSearchScope: FilterAttribute] = [
        .all: .nameAndText,
        .name: .name,
        .text: .text
    ]
    private let scopeLabels: [CardSearchScope: String] = [
        .all: "All".localized(),
        .name: "Name".localized(),
        .text: "Text".localized()
    ]
    private var showAllFilters = true
    private var viewMode = CardFilterView.list
    
    required init(role: Role) {
        self.deckListViewController = DeckListViewController()
        self.role = role
        self.deckListViewController.role = role
        self.legality = .standard(mwl: Defaults[.defaultMWL])
        
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience init(role: Role, andFile file: String) {
        self.init(role: role)

        self.deckListViewController.loadDeck(fromFile: file)
        self.legality = self.deckListViewController.deck.legality
    }
    
    convenience init(role: Role, andDeck deck: Deck) {
        self.init(role: role)
        
        assert(role == deck.role, "role mismatch")
        self.deckListViewController.deck = deck
        self.legality = deck.legality
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showAllFilters = true
        self.viewMode = Defaults[.filterViewMode]
        
        self.view.backgroundColor = .white
        self.navigationController?.navigationBar.backgroundColor = .white
        
        self.packUsage = Defaults[.deckbuilderPacks]
        
        self.cardList = CardList(role: self.role, packUsage: packUsage, browser: false, legality: self.legality)
        self.initCards()
        
        self.tableView.register(UINib(nibName: "CardFilterCell", bundle: nil), forCellReuseIdentifier: "cardCell")
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        self.collectionView.register(UINib(nibName: "CardFilterThumbView", bundle: nil), forCellWithReuseIdentifier: "cardThumb")
        self.collectionView.register(CollectionViewSectionHeader.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "sectionHeader")
        self.collectionView.alwaysBounceVertical = true
        
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.headerReferenceSize = CGSize(width: 320, height: 22)
        layout.sectionInset = UIEdgeInsets(top: 2, left: 2, bottom: 0, right: 2)
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.edgesForExtendedLayout = .bottom
        
        let nav = UINavigationController(rootViewController: self.deckListViewController)
        self.splitViewController?.showDetailViewController(nav, sender: self)
                
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.addTopCard(_:)), name: Notifications.addTopCard, object: nil)
        nc.addObserver(self, selector: #selector(self.deckChanged(_:)), name: Notifications.deckChanged, object: nil)
        nc.addObserver(self, selector: #selector(self.deckSaved(_:)), name: Notifications.deckSaved, object: nil)
        nc.addObserver(self, selector: #selector(self.nameAlertWillAppear(_:)), name: Notifications.nameAlert, object: nil)
        self.keyboardObserver = KeyboardObserver(handler: self)
        
        self.navigationItem.title = "Filter".localized()
        let clearButton = UIBarButtonItem(title: "Clear".localized(), style: .plain, target: self, action: #selector(self.clearFiltersClicked(_:)))
        self.navigationItem.rightBarButtonItem = clearButton
        
        self.initFilters()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setResultTopMargin()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        Defaults[.filterViewMode] = self.viewMode
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "F", modifierFlags: .command, action: #selector(self.startTextSearch(_:)), discoverabilityTitle: "Find Card".localized()),
            UIKeyCommand(input: "A", modifierFlags: .command, action: #selector(self.changeScopeKeyCmd(_:)), discoverabilityTitle: "Scope: All".localized()),
            UIKeyCommand(input: "N", modifierFlags: .command, action: #selector(self.changeScopeKeyCmd(_:)), discoverabilityTitle: "Scope: Name".localized()),
            UIKeyCommand(input: "T", modifierFlags: .command, action: #selector(self.changeScopeKeyCmd(_:)), discoverabilityTitle: "Scope: Text".localized()),
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(self.escKeyPressed(_:)))
        ]
    }
    
    @objc func startTextSearch(_ cmd: UIKeyCommand) {
        self.searchField.becomeFirstResponder()
    }
    
    @objc func escKeyPressed(_ cmd: UIKeyCommand) {
        self.searchField.resignFirstResponder()
    }
    
    fileprivate func setResultTopMargin() {
        let buttonsHeight = self.buttonContainer.frame.height
        
        if self.showAllFilters {
            let sliderHeight = self.sliderContainer.frame.height
            self.resultsTopMargin.constant = buttonsHeight + sliderHeight + 1
        } else {
            let influenceHeight = self.influenceSeparator.frame.maxY
            self.resultsTopMargin.constant = buttonsHeight + influenceHeight + 1
        }
    }
    
    func initCards() {
        let data = self.cardList.dataForTableView()
        self.cards = data.values
        self.sections = data.sections
    }
    
    @objc func deckChanged(_ notification: Notification) {
        guard let deck = self.deckListViewController.deck else {
            return
        }
        if self.legality != deck.legality {
            self.cardList = CardList(role: self.role, packUsage: self.packUsage, browser: false, legality: deck.legality)
            self.legality = deck.legality
        }
        if let identity = deck.identity {
            if self.role == .runner {
                self.cardList.preFilterForRunner(identity, deck.mwl)
            } else {
                self.cardList.preFilterForCorp(identity, deck.mwl)
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
    
    @objc func deckSaved(_ notification: Notification) {
        self.setBackOrRevertButton(false)
    }
    
    func setBackOrRevertButton(_ modified: Bool) {
        let autoSave = Defaults[.autoSave]
        if autoSave {
            return
        }
        
        self.navigationItem.leftBarButtonItem = modified ? self.revertButton : nil
    }
    
    @objc func revertDeck(_ sender: UIBarButtonItem) {
        if let filename = self.deckListViewController.deck.filename {
            let deck = DeckManager.loadDeckFromPath(filename, useCache: false)
            self.reloadData()
            self.deckListViewController.deck = deck
            self.setBackOrRevertButton(false)
        } else {
            self.navigationItem.leftBarButtonItem = nil
            _ = self.navigationController?.popToRootViewController(animated: false)
        }
    }
    
    func initFilters() {
        self.typeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.setButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.factionButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.subtypeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        self.costSlider.maximumValue = Float(1 + CardManager.maxCost(for: self.role))
        self.strengthSlider.maximumValue = Float(1 + CardManager.maxStrength)
        self.influenceSlider.maximumValue = Float(1 + CardManager.maxInfluence)
        self.muApSlider.maximumValue = Float(1 + (self.role == .runner ? CardManager.maxMU : CardManager.maxAgendaPoints))
        
        self.costSlider.setThumbImage(UIImage(named: "credit_slider"), for: .normal)
        self.strengthSlider.setThumbImage(UIImage(named: "strength_slider"), for: .normal)
        self.influenceSlider.setThumbImage(UIImage(named: "influence_slider"), for: .normal)
        let img = UIImage(named: self.role == .runner ? "mem_slider" : "point_slider")
        self.muApSlider.setThumbImage(img, for: .normal)
        
        self.searchField.placeholder = "Search Cards".localized()
        self.searchField.clearButtonMode = .always
        
        self.clearFilters()
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
        self.scopeButton.setTitle(self.scopeLabels[self.scope]! + Constant.arrow, for: .normal)
        self.scopeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.scopeButton.titleLabel?.minimumScaleFactor = 0.5
        
        self.searchField.text = ""
        self.searchText = ""
        
        self.costSlider.value = 0
        self.costValueChanged(self.costSlider)
        self.prevCost = 0
        
        self.muApSlider.value = 0
        self.muApValueChanged(self.muApSlider)
        self.prevMu = 0
        self.prevAp = 0
        
        self.influenceSlider.value = 0
        self.influenceValueChanged(self.influenceSlider)
        self.prevInf = 0
        self.influenceValue = -1
        
        self.strengthSlider.value = 0
        self.strengthValueChanged(self.strengthSlider)
        self.prevStr = 0
        
        self.resetAllButtons()
        self.selectedType = Constant.kANY
        self.selectedTypes = nil
        
        self.selectedValues.removeAll()
        
        self.sendNotification = true
    }
    
    @objc func addTopCard(_ notification: Notification) {
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
    
    @objc func nameAlertWillAppear(_ notification: Notification) {
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
            self.muApSlider.value = 0
            self.muApValueChanged(self.muApSlider)
            self.strengthSlider.value = 0
            self.strengthValueChanged(self.strengthSlider)
        }
        
        if self.searchField.isFirstResponder {
            self.searchField.resignFirstResponder()
        }
        
        let moreLess = self.showAllFilters ? "Less △".localized() : "More ▽".localized()
        self.moreLessButton.setTitle(moreLess, for: .normal)
        
        if self.showAllFilters {
            self.influenceSeparator.isHidden = true
        }
        
        self.setResultTopMargin()
        UIView.animate(withDuration: 0.20, animations: {
            self.resultsView.layoutIfNeeded()
        }, completion: { _ in
            self.influenceSeparator.isHidden = self.showAllFilters
        })
    }
    
    @IBAction func viewModeChanged(_ sender: UISegmentedControl) {
        var scrollToPath: IndexPath?
        
        if viewMode == .list {
            if let visible = self.tableView.indexPathsForVisibleRows {
                for indexPath in visible {
                    let rect = self.tableView.rectForRow(at: indexPath)
                    let convertedRect = self.tableView.convert(rect, to: self.tableView.superview)
                    let visible = self.tableView.frame.contains(convertedRect)
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
    
        self.viewMode = CardFilterView(rawValue: sender.selectedSegmentIndex) ?? .list
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
        
        CardFilterPopover.showFrom(button: sender, inView: self, entries: data, attribute: .type, selected: selected)
    }
    
    @IBAction func setClicked(_ sender: UIButton) {
        let stringPacks: TableData<String> = PackManager.packsForTableView(packUsage: self.packUsage)
        let selected = self.selectedValues[.set]
        
        CardFilterPopover.showFrom(button: sender, inView: self, entries: stringPacks, attribute: .set, selected: selected)
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
        
        CardFilterPopover.showFrom(button: sender, inView: self, entries: data, attribute: .subtype, selected: selected)
    }
    
    @IBAction func factionClicked(_ sender: UIButton) {
        let data = TableData(values: Faction.factionsFor(role: self.role, packUsage: self.packUsage))
        let selected = self.selectedValues[.faction]
        
        CardFilterPopover.showFrom(button: sender, inView: self, entries: data, attribute: .faction, selected: selected)
    }
    
    func filterCallback(attribute: FilterAttribute, value: FilterValue) {
        if attribute == .type {
            if let v = value.string {
                self.selectedType = v
                self.selectedTypes = nil
            } else if let v = value.strings {
                self.selectedType = ""
                self.selectedTypes = v
            }
            
            self.resetButton(.subtype)
        }
    
        self.selectedValues[attribute] = value
        
        self.updateFilter(attribute, value: value)
    }
    
    func resetAllButtons() {
        self.resetButton(.type)
        self.resetButton(.set)
        self.resetButton(.faction)
        self.resetButton(.subtype)
    }
    
    func resetButton(_ attribute: FilterAttribute) {
        let button: UIButton
        switch attribute {
        case .type:
            button = self.typeButton
            self.resetButton(.subtype)
        case .set:
            button = self.setButton
        case .subtype:
            button = self.subtypeButton
        case .faction:
            button = self.factionButton
        default:
            fatalError("invalid type")
        }
        
        let any = FilterValue.string(Constant.kANY)
        self.selectedValues[attribute] = any
        
        self.updateFilter(attribute, value: any)
        let title = attribute.localized() + ": " + Constant.kANY.localized()
        button.setTitle(title, for: .normal)
    }
    
    // MARK: - slider callbacks
    
    @IBAction func strengthValueChanged(_ sender: UISlider) {
        var value = Int(round(sender.value))
        sender.value = Float(value)
        value -= 1
        if value != self.prevStr {
            self.strengthLabel.text = String(format: "Strength: %@".localized(), value == -1 ? "All".localized() : "\(value)")
            self.updateFilter(.strength, value: FilterValue.int(value))
            self.prevStr = value
        }
    }
    
    @IBAction func muApValueChanged(_ sender: UISlider) {
        var value = Int(round(sender.value))
        sender.value = Float(value)
        value -= 1
        let prev = self.role == .runner ? self.prevMu : self.prevAp
        if value != prev {
            let fmt = self.role == .runner ? "MU: %@".localized() : "AP: %@".localized()
            self.muApLabel.text = String(format: fmt, value == -1 ? "All".localized() : "\(value)")
            self.updateFilter(self.role == .runner ? .mu : .agendaPoints, value: FilterValue.int(value))
            if self.role == .runner {
                self.prevMu = value
            } else {
                self.prevAp = value
            }
        }
    }
    
    @IBAction func costValueChanged(_ sender: UISlider) {
        var value = Int(round(sender.value))
        sender.value = Float(value)
        value -= 1
        if value != self.prevCost {
            self.costLabel.text = String(format: "Cost: %@".localized(), value == -1 ? "All".localized() : "\(value)")
            self.updateFilter(.cost, value: FilterValue.int(value))
            self.prevCost = value
        }
    }
    
    @IBAction func influenceValueChanged(_ sender: UISlider) {
        var value = Int(round(sender.value))
        sender.value = Float(value)
        value -= 1
        if value != self.prevInf {
            self.influenceLabel.text = String(format: "Influence: %@".localized(), value == -1 ? "All".localized() : "\(value)")
            self.updateFilter(.influence, value: FilterValue.int(value))
            self.prevInf = value
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
    
    @objc func changeScopeKeyCmd(_ cmd: UIKeyCommand) {
        if cmd.input?.lowercased() == "a" {
            self.changeScope(.all)
        } else if cmd.input?.lowercased() == "n" {
            self.changeScope(.name)
        } else if cmd.input?.lowercased() == "t" {
            self.changeScope(.text)
        }
    }
    
    func changeScope(_ scope: CardSearchScope) {
        self.scope = scope
        self.scopeButton.setTitle(self.scopeLabels[self.scope]! + Constant.arrow, for: .normal)
        
        self.updateFilter(self.scopes[self.scope]!, value: FilterValue.string(self.searchText))
    }
    
    // MARK: - text search
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if CardImageViewPopover.dismiss() {
            return false
        }
        
        let text = textField.text! as NSString
        self.searchText = text.replacingCharacters(in: range, with: string)
        
        self.updateFilter(self.scopes[self.scope]!, value: FilterValue.string(self.searchText))
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if CardImageViewPopover.dismiss() {
            return false
        }
        
        self.searchText = ""
        self.updateFilter(self.scopes[self.scope]!, value: FilterValue.string(self.searchText))
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if CardImageViewPopover.dismiss() {
            return false
        }
        
        if self.searchText.count > 0 {
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
            NotificationCenter.default.post(name: Notifications.addTopCard, object: self)
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // MARK: - filter update
    
    func updateFilter(_ attribute: FilterAttribute, value: FilterValue) {
        switch attribute {
        case .mu:
            self.cardList.filterByMU(value.int!)
        case .cost:
            self.cardList.filterByCost(value.int!)
        case .agendaPoints:
            self.cardList.filterByAgendaPoints(value.int!)
        case .strength:
            self.cardList.filterByStrength(value.int!)
        case .influence:
            let inf = value.int!
            if let identity = self.deckListViewController.deck?.identity {
                self.cardList.filterByInfluence(inf, forFaction: identity.faction)
            } else {
                self.cardList.filterByInfluence(inf)
            }
        
        case .name:
            self.cardList.filterByName(value.string!)
        case .text:
            self.cardList.filterByText(value.string!)
        case .nameAndText:
            self.cardList.filterByTextOrName(value.string!)
            
        case .faction:
            self.cardList.filterByFaction(value)
        case .set:
            self.cardList.filterBySet(value)
        case .type:
            self.cardList.filterByType(value)
        case .subtype:
            self.cardList.filterBySubtype(value)
        }
        
        self.initCards()
        if self.sendNotification {
            self.reloadData()
        }
    }
    
    // MARK: - table view
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = UIColor(rgb: 0xEBEBEC)
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
        guard let card = self.cards[indexPath] else {
            return cell
        }

        cell.addButton.tag = Add.table.rawValue
        cell.addButton.addTarget(self, action: #selector(self.addCardToDeck(_:)), for: .touchUpInside)
        
        let deck = self.deckListViewController.deck
        let identity = deck?.identity ?? Card.null()

        let influence = identity.faction == card.faction ? 0 : card.influence
        cell.pips.set(value: influence, color: card.factionColor)
        
        let mwl = deck?.mwl ?? Defaults[.defaultMWL]
        let penalty = card.mwlPenalty(mwl)
        cell.pipsView.backgroundColor = penalty > 0 ? UIColor(rgb: 0xf5f5f5) : .white
        
        cell.nameLabel.text = card.name
        let cc = deck?.findCard(card) ?? CardCounter.null()
        cell.countLabel.text = cc.count > 0 ? "\(cc.count)" : ""

        cell.nameLabel.textColor = card.owned == 0 ? .darkGray : .black

        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = self.cards[indexPath.section][indexPath.row]
        let rect = self.tableView.rectForRow(at: indexPath)
        let mwl = self.deckListViewController.deck?.mwl ?? .none
        CardImageViewPopover.show(for: card, mwl: mwl, from: rect, in: self, subView: self.tableView)
    }
    
    @objc func addCardToDeck(_ sender: UIButton) {
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
        if textField.isFirstResponder && (textField.text?.count ?? 0) > 0 {
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cardThumb", for: indexPath) as! CardFilterThumbView
        guard let card = self.cards[indexPath] else {
            return cell
        }
        let cc = self.deckListViewController.deck?.findCard(card) ?? CardCounter.null()

        
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
        let mwl = self.deckListViewController.deck?.mwl ?? .none
        CardImageViewPopover.show(for: card, mwl: mwl, from: rect, in: self, subView: self.collectionView)
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

extension CardFilterViewController: KeyboardHandling {
    // MARK: - keyboard show/hide
    
    func keyboardWillShow(_ info: KeyboardInfo) {
        if !self.searchField.isFirstResponder {
            return
        }
        
        self.searchFieldActive = true
        self.moreLessButton.isHidden = true
        
        let screenHeight = UIScreen.main.bounds.size.height
        let kbHeight = screenHeight - info.endFrame.origin.y
        
        self.resultsTopMargin.constant = 0
        self.resultsBottomMargin.constant = kbHeight
        
        UIView.animate(withDuration: info.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    func keyboardWillHide(_ info: KeyboardInfo) {
        if self.searchFieldActive {
            self.searchField.resignFirstResponder()
        }
        
        self.searchFieldActive = false
        self.moreLessButton.isHidden = false
        
        self.setResultTopMargin()
        self.resultsBottomMargin.constant = 0
        
        UIView.animate(withDuration: info.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    

}
