//
//  BrowserFilterViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 15.01.17.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class BrowserFilterViewController: UIViewController, UITextFieldDelegate, FilteringViewController {

    @IBOutlet weak var sideLabel: UILabel!
    @IBOutlet weak var sideSelector: UISegmentedControl!

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var searchLabel: UILabel!
    @IBOutlet weak var scopeSelector: UISegmentedControl!

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

    @IBOutlet weak var trashLabel: UILabel!
    @IBOutlet weak var trashSlider: UISlider!

    @IBOutlet weak var uniqueLabel: UILabel!
    @IBOutlet weak var uniqueSwitch: UISwitch!

    @IBOutlet weak var limitedLabel: UILabel!
    @IBOutlet weak var limitedSwitch: UISwitch!

    @IBOutlet weak var mwlLabel: UILabel!
    @IBOutlet weak var mwlSwitch: UISwitch!

    @IBOutlet weak var summaryLabel: UILabel!

    private var browser: BrowserResultViewController
    private var cardList: CardList
    
    private var role = Role.none
    private var scope = CardSearchScope.all
    private var packUsage = PackUsage.all
    private var searchText = ""
    private var selectedType = ""
    private var selectedTypes: Set<String>?
    private var selectedValues = [FilterAttribute: FilterValue]()
    private var initializing = true
    private var prevAp = 0
    private var prevMu = 0
    private var prevTrash = 0
    private var prevCost = 0
    private var prevStr = 0
    private var prevInf = 0
    
    required init() {
        self.browser = BrowserResultViewController()
        self.packUsage = Defaults[.browserPacks]
        self.cardList = CardList.browserInitForRole(self.role, packUsage: self.packUsage)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Cards".localized()
        
        self.initializing = true
        Analytics.logEvent(.browser, attributes: ["Device": "iPad"])
        
        self.edgesForExtendedLayout = []
        
        // side
        self.sideSelector.setTitle("Both".localized(), forSegmentAt: 0)
        self.sideSelector.setTitle("Runner".localized(), forSegmentAt: 1)
        self.sideSelector.setTitle("Corp".localized(), forSegmentAt: 2)
        self.sideLabel.text = "Side:".localized()
        
        // text/scope
        self.scopeSelector.setTitle("All".localized(), forSegmentAt: 0)
        self.scopeSelector.setTitle("Name".localized(), forSegmentAt: 1)
        self.scopeSelector.setTitle("Text".localized(), forSegmentAt: 2)
        self.searchLabel.text = "Search in:".localized()
        self.scope = .all
        
        self.textField.delegate = self
        self.textField.placeholder = "Search Cards".localized()
        self.textField.clearButtonMode = .always
        self.textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        
        // sliders
        self.costSlider.maximumValue = Float(1 + CardManager.maxCost(for: self.role))
        self.costSlider.minimumValue = 0
        
        self.muSlider.maximumValue = Float(1 + CardManager.maxMU)
        self.muSlider.minimumValue = 0
        
        self.strengthSlider.maximumValue = Float(1 + CardManager.maxStrength)
        self.strengthSlider.minimumValue = 0
        
        self.influenceSlider.maximumValue = Float(1 + CardManager.maxInfluence)
        self.influenceSlider.minimumValue = 0
        
        self.apSlider.maximumValue = Float(1 + CardManager.maxAgendaPoints)
        self.apSlider.minimumValue = 0
        
        self.trashSlider.maximumValue = Float(1 + CardManager.maxTrash)
        self.trashSlider.minimumValue = 0
        
        self.costSlider.setThumbImage(UIImage(named: "credit_slider"), for: .normal)
        self.muSlider.setThumbImage(UIImage(named: "mem_slider"), for: .normal)
        self.strengthSlider.setThumbImage(UIImage(named: "strength_slider"), for: .normal)
        self.influenceSlider.setThumbImage(UIImage(named: "influence_slider"), for: .normal)
        self.apSlider.setThumbImage(UIImage(named: "point_slider"), for: .normal)
        self.trashSlider.setThumbImage(UIImage(named: "trash_slider"), for: .normal)
        
        // switches
        self.uniqueLabel.text = "Unique".localized()
        self.limitedLabel.text = "Limited".localized()
        self.mwlLabel.text = "MWL".localized()
                
        self.summaryLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)
        
        let mwl = Defaults[.defaultMWL]
        self.mwlLabel.isHidden = mwl == MWL.none
        self.mwlSwitch.isHidden = mwl == MWL.none

        self.resetAllButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.typeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.setButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.factionButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.subtypeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.dismissKeyboard(_:)), name: Notifications.browserNew, object: nil)
        nc.addObserver(self, selector: #selector(self.dismissKeyboard(_:)), name: Notifications.browserFind, object: nil)
        
        let nav = UINavigationController(rootViewController: self.browser)
        self.splitViewController?.showDetailViewController(nav, sender: self)
        
        self.clearFiltersClicked(self)
        
        let clearButton = UIBarButtonItem(title: "Clear".localized(), style: .plain, target: self, action: #selector(self.clearFiltersClicked(_:)))
        self.navigationItem.rightBarButtonItem = clearButton
        
        self.initializing = false
        self.updateResults()
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
            UIKeyCommand(input: UIKeyInputEscape, modifierFlags: [], action: #selector(self.escKeyPressed(_:)))
        ]
    }
    
    @objc func startTextSearch(_ cmd: UIKeyCommand) {
        self.textField.becomeFirstResponder()
    }
    
    @objc func escKeyPressed(_ cmd: UIKeyCommand) {
        self.textField.resignFirstResponder()
    }
    
    @objc func dismissKeyboard(_ sender: Any) {
        self.textField.resignFirstResponder()
    }
    
    // MARK: - buttons
    
    @objc func clearFiltersClicked(_ sender: Any) {
        // reset segment controllers
        self.role = .none
        self.sideSelector.selectedSegmentIndex = 0
        self.scopeSelector.selectedSegmentIndex = 0
        
        // clear textfield
        self.textField.text = ""
        self.searchText = ""
        self.scope = .all
        
        // reset sliders
        self.apSlider.value = 0
        self.apChanged(self.apSlider)
        self.prevAp = 0
        
        self.muSlider.value = 0
        self.muChanged(self.muSlider)
        self.prevMu = 0
        
        self.influenceSlider.value = 0
        self.influenceChanged(self.influenceSlider)
        self.prevInf = 0
        
        self.strengthSlider.value = 0
        self.strengthChanged(self.strengthSlider)
        self.prevStr = 0
        
        self.costSlider.value = 0
        self.costChanged(self.costSlider)
        self.prevCost = 0
        
        self.trashSlider.value = 0
        self.trashChanged(self.trashSlider)
        self.prevTrash = 0
        
        // reset switches
        self.uniqueSwitch.isOn = false
        self.limitedSwitch.isOn = false
        self.mwlSwitch.isOn = false
        
        self.cardList = CardList.browserInitForRole(self.role, packUsage: self.packUsage)
        self.cardList.clearFilters()
        
        self.updateResults()
        
        self.selectedType = Constant.kANY
        self.selectedTypes = nil
        self.selectedValues.removeAll()
        
        self.resetAllButtons()
    }
    
    @IBAction func sideSelected(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.role = .none
        case 1:
            self.role = .runner
            self.apSlider.value = 0
            self.prevAp = 0
            self.apChanged(self.apSlider)
            self.trashSlider.value = 0
            self.prevTrash = 0
            self.trashChanged(self.trashSlider)
        case 2:
            self.role = .corp
            self.muSlider.value = 0
            self.prevMu = 0
            self.muChanged(self.muSlider)
        default:
            preconditionFailure("bad segment index")
        }
        
        // enable/disable sliders depending on role
        self.muLabel.isEnabled = self.role != .corp
        self.muSlider.isEnabled = self.role != .corp
        self.apLabel.isEnabled = self.role != .runner
        self.apSlider.isEnabled = self.role != .runner
        self.trashLabel.isEnabled = self.role != .runner
        self.trashSlider.isEnabled = self.role != .runner
        
        self.resetAllButtons()
        
        let maxCost = CardManager.maxCost(for: self.role)
        self.costSlider.maximumValue = Float(1 + maxCost)
        self.costSlider.value = Float(min(1 + maxCost, Int(self.costSlider.value)))
        self.prevCost = Int(self.costSlider.value)
        
        self.cardList = CardList.browserInitForRole(self.role, packUsage: self.packUsage)
        self.cardList.clearFilters()
        
        let selectedSets = self.selectedValues[.set]
        var selected = ""
        if let set = selectedSets?.strings {
            selected = set.count == 0 ? Constant.kANY.localized() : (set.count == 1 ? set.first! : "...")
        } else {
            selected = Constant.kANY.localized()
        }
        
        let title = String(format: "%@: %@", "Set".localized(), selected)
        self.setButton.setTitle(title, for: .normal)
        
        self.costChanged(self.costSlider)
        self.cardList.filterByInfluence(Int(self.influenceSlider.value) - 1)
        self.cardList.filterByStrength(Int(self.strengthSlider.value) - 1)
        self.cardList.filterByCost(Int(self.costSlider.value) - 1)
        self.cardList.filterByAgendaPoints(Int(self.apSlider.value) - 1)
        self.cardList.filterByMU(Int(self.muSlider.value) - 1)
        self.cardList.filterByTrash(Int(self.trashSlider.value) - 1)
        
        self.cardList.filterByLimited(self.limitedSwitch.isOn)
        self.cardList.filterByUniqueness(self.uniqueSwitch.isOn)
        self.cardList.filterByMWL(self.mwlSwitch.isOn)
        
        self.filterWithText()
        
        self.updateResults()
    }
    
    // MARK: - buttons for popovers
    
    @IBAction func typeClicked(_ sender: UIButton) {
        let data: TableData<String>
        if self.role == .none {
            data = CardType.allTypes
        } else {
            var types = CardType.typesFor(role: self.role)
            types.insert(CardType.name(for: .identity), at: 1)
            data = TableData(values: types)
        }
        let selected = self.selectedValues[.type]
        
        CardFilterPopover.showFrom(button: sender, inView: self, entries: data, attribute: .type, selected: selected)
    }
    
    @IBAction func setClicked(_ sender: UIButton) {
        let selected = self.selectedValues[.set]
        let stringPacks: TableData<String> = PackManager.packsForTableView(packUsage: self.packUsage)
        
        CardFilterPopover.showFrom(button: sender, inView: self, entries: stringPacks, attribute: .set, selected: selected)
    }
    
    @IBAction func subtypeClicked(_ sender: UIButton) {
        let data: TableData<String>
        if self.role == .none {
            let runner: [String]
            let corp: [String]
            if let selected = self.selectedTypes {
                runner = CardManager.subtypesFor(role: .runner, andTypes: selected, includeIdentities: true)
                corp = CardManager.subtypesFor(role: .corp, andTypes: selected, includeIdentities: true)
            } else {
                runner = CardManager.subtypesFor(role: .runner, andType: self.selectedType, includeIdentities: true)
                corp = CardManager.subtypesFor(role: .corp, andType: self.selectedType, includeIdentities: true)
            }
            
            var sections = [String]()
            var values = [[String]]()
            sections.append("")
            values.append([Constant.kANY])
            if runner.count > 0 {
                values.append(runner)
                sections.append("Runner".localized())
            }
            if corp.count > 0 {
                values.append(corp)
                sections.append("Corp".localized())
            }
            
            data = TableData(sections: sections, values: values)
            data.collapsedSections = [Bool](repeating: false, count: sections.count)
        } else {
            var arr: [String]
            if let selected = self.selectedTypes {
                arr = CardManager.subtypesFor(role: self.role, andTypes: selected, includeIdentities: true)
            } else {
                arr = CardManager.subtypesFor(role: self.role, andType: self.selectedType, includeIdentities: true)
            }
            arr.insert(Constant.kANY, at: 0)
            data = TableData(values: arr)
        }
        
        let selected = self.selectedValues[.subtype]
        
        CardFilterPopover.showFrom(button: sender, inView: self, entries: data, attribute: .subtype, selected: selected)
    }
    
    @IBAction func factionClicked(_ sender: UIButton) {
        let data: TableData<String>
        if self.role == .none {
            data = Faction.factionsForBrowser(packUsage: self.packUsage)
        } else {
            data = TableData(values: Faction.factionsFor(role: self.role, packUsage: self.packUsage))
        }
        let selected = self.selectedValues[.faction]
        
        CardFilterPopover.showFrom(button: sender, inView: self, entries: data, attribute: .faction, selected: selected)
    }
    
    func filterCallback(attribute: FilterAttribute, value: FilterValue) {
        
        if attribute == .type {
            if let v = value.string {
                self.selectedType = v
                self.selectedTypes = nil
            }
            if let v = value.strings {
                self.selectedType = ""
                self.selectedTypes = v
            }
            
            self.resetButton(.subtype)
        }
        
        self.selectedValues[attribute] = value
            
        switch attribute {
        case .type:
            self.cardList.filterByType(value)
        case .subtype:
            self.cardList.filterBySubtype(value)
        case .faction:
            self.cardList.filterByFaction(value)
        case .set:
            self.cardList.filterBySet(value)
        default:
            preconditionFailure("can't happen")
        }
        
        self.updateResults()
    }
    
    func resetAllButtons() {
        self.resetButton(.type)
        self.resetButton(.faction)
        self.resetButton(.set)
        self.resetButton(.subtype)
    }
    
    private func resetButton(_ attribute: FilterAttribute) {
        let button: UIButton
        let any = FilterValue.string(Constant.kANY)
        switch attribute {
        case .type:
            button = self.typeButton
            self.selectedType = Constant.kANY
            self.selectedTypes = nil
            self.resetButton(.subtype)
            self.cardList.filterByType(any)
        case .faction:
            button = self.factionButton
            self.cardList.filterByFaction(any)
        case .set:
            button = self.setButton
            self.cardList.filterBySet(any)
        case .subtype:
            button = self.subtypeButton
            self.cardList.filterBySubtype(any)
        default:
            fatalError("invalid button")
        }
        
        self.selectedValues[attribute] = FilterValue.string(Constant.kANY)
        button.setTitle(attribute.localized() + ": " + Constant.kANY.localized(), for: .normal)
    }
    
    // MARK: - text search
    
    @objc func changeScopeKeyCmd(_ cmd: UIKeyCommand) {
        switch cmd.input?.lowercased() {
        case "a"?:
            self.scope = .all
            self.scopeSelector.selectedSegmentIndex = 0
        case "n"?:
            self.scope = .name
            self.scopeSelector.selectedSegmentIndex = 1
        case "t"?:
            self.scope = .text
            self.scopeSelector.selectedSegmentIndex = 2
        default: break
        }
        self.filterWithText()
    }
    
    @IBAction func scopeSelected(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.scope = .all
        case 1:
            self.scope = .name
        case 2:
            self.scope = .text
        default:
            break
        }
        self.filterWithText()
    }
    
    func filterWithText() {
        switch self.scope {
        case .all:
            self.cardList.filterByTextOrName(self.searchText)
        case .name:
            self.cardList.filterByName(self.searchText)
        case .text:
            self.cardList.filterByText(self.searchText)
        }
        self.updateResults()
    }
    
    // MARK: - text field
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        self.searchText = textField.text ?? ""
        self.filterWithText()
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.searchText = ""
        self.filterWithText()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return false
    }
    
    // MARK: - sliders
    
    @IBAction func influenceChanged(_ sender: UISlider) {
        var value = Int(sender.value)
        sender.value = Float(value)
        value -= 1
        if value != self.prevInf {
            self.influenceLabel.text = String(format: "Influence: %@".localized(), value == -1 ? "All".localized() : "\(value)")
            self.cardList.filterByInfluence(value)
            self.updateResults()
            self.prevInf = value
        }
    }
    
    @IBAction func costChanged(_ sender: UISlider) {
        var value = Int(sender.value)
        sender.value = Float(value)
        value -= 1
        if value != self.prevCost {
            self.costLabel.text = String(format: "Cost: %@".localized(), value == -1 ? "All".localized() : "\(value)")
            self.cardList.filterByCost(value)
            self.updateResults()
            self.prevCost = value
        }
    }
    
    @IBAction func strengthChanged(_ sender: UISlider) {
        var value = Int(sender.value)
        sender.value = Float(value)
        value -= 1
        if value != self.prevStr {
            self.strengthLabel.text = String(format: "Strength: %@".localized(), value == -1 ? "All".localized() : "\(value)")
            self.cardList.filterByStrength(value)
            self.updateResults()
            self.prevStr = value
        }
    }
    
    @IBAction func apChanged(_ sender: UISlider) {
        var value = Int(sender.value)
        sender.value = Float(value)
        value -= 1
        if value != self.prevAp {
            self.apLabel.text = String(format: "AP: %@".localized(), value == -1 ? "All".localized() : "\(value)")
            self.cardList.filterByAgendaPoints(value)
            self.updateResults()
            self.prevAp = value
        }
    }
    
    @IBAction func muChanged(_ sender: UISlider) {
        var value = Int(sender.value)
        sender.value = Float(value)
        value -= 1
        if value != self.prevMu {
            self.muLabel.text = String(format: "MU: %@".localized(), value == -1 ? "All".localized() : "\(value)")
            self.cardList.filterByMU(value)
            self.updateResults()
            self.prevMu = value
        }
    }
    
    @IBAction func trashChanged(_ sender: UISlider) {
        var value = Int(sender.value)
        sender.value = Float(value)
        value -= 1
        if value != self.prevTrash {
            self.trashLabel.text = String(format: "Trash: %@", value == -1 ? "All".localized() : "\(value)")
            self.cardList.filterByTrash(value)
            self.updateResults()
            self.prevTrash = value
        }
    }
    
    // MARK: - switches
    @IBAction func uniqueChanged(_ sender: UISwitch) {
        self.cardList.filterByUniqueness(sender.isOn)
        self.updateResults()
    }
    
    @IBAction func limitedChanged(_ sender: UISwitch) {
        self.cardList.filterByLimited(sender.isOn)
        self.updateResults()
    }
    
    @IBAction func mwlChanged(_ sender: UISwitch) {
        self.cardList.filterByMWL(sender.isOn)
        self.updateResults()
    }
    
    // MARK: - update results
    
    func updateResults() {
        let count = self.cardList.count()
        let fmt = count == 1 ? "%lu matching card".localized() : "%lu matching cards".localized()
        self.summaryLabel.text = String(format: fmt, count)
        
        if !self.initializing {
            self.browser.updateDisplay(self.cardList)
        }
    }

}
