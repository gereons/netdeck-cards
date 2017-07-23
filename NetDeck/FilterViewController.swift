//
//  FilterViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 11.12.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit
import MultiSelectSegmentedControl
import SwiftyUserDefaults

private enum Tags: Int {
    case faction
    case miniFaction
    case type
}

class FilterViewController: UIViewController, MultiSelectSegmentedControlDelegate, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var factionControl: MultiSelectSegmentedControl!
    @IBOutlet weak var miniFactionControl: MultiSelectSegmentedControl!
    
    @IBOutlet weak var typeVerticalDistance: NSLayoutConstraint!
    @IBOutlet weak var typeControl: MultiSelectSegmentedControl!
    
    @IBOutlet weak var influenceLabel: UILabel!
    @IBOutlet weak var influenceSlider: UISlider!
    
    @IBOutlet weak var strengthLabel: UILabel!
    @IBOutlet weak var strengthSlider: UISlider!
    
    @IBOutlet weak var muApLabel: UILabel!
    @IBOutlet weak var muApSlider: UISlider!
    
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var costSlider: UISlider!
    
    @IBOutlet weak var previewTable: UITableView!
    @IBOutlet weak var previewHeader: UILabel!
    
    var role = Role.none
    var identity: Card?
    var cardList: CardList!
    
    private var factionNames = [String]()
    private var typeNames = [String]()
    
    private var selectedTypes = Set<String>()
    private var subtypes: FilterValue?
    
    private var cards = [Card]()
    private var showPreviewTable = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Filter".localized()
                
        self.typeVerticalDistance.constant = 16
        self.miniFactionControl.isHidden = true
        self.miniFactionControl.tag = Tags.miniFaction.rawValue
        self.miniFactionControl.delegate = self
        self.miniFactionControl.selectAllSegments(false)
        
        let useDaD = Defaults[.useDataDestiny]
        let packUsage = Defaults[.deckbuilderPacks]
        let miniFactions = packUsage == .all || useDaD
        
        let factionLimit: Int
        if self.role == .runner {
            self.factionNames = (Faction.runnerFactionsCore + [ Faction.neutral ]).map { Faction.name(for: $0) }
            self.typeNames = Array(CardType.runnerTypeNames.dropFirst()) // remove "Any"
            factionLimit = factionNames.count
            if miniFactions {
                self.factionNames = (Faction.runnerFactionsCore + [ Faction.neutral ] + Faction.runnerMiniFactions).map { Faction.name(for: $0) }
                self.miniFactionControl.isHidden = false
                self.typeVerticalDistance.constant = 48
            }
        } else {
            self.factionNames = (Faction.corpFactions + [ Faction.neutral ]).map { Faction.name(for: $0) }
            factionLimit = factionNames.count
            self.typeNames = Array(CardType.corpTypeNames.dropFirst()) // remove "Any"
        }
        
        // faction control
        self.factionControl.delegate = self
        self.factionControl.tag = Tags.faction.rawValue
        
        self.factionControl .removeAllSegments()
        for i in 0 ..< factionLimit {
            self.factionControl.insertSegment(withTitle: self.factionNames[i], at: i, animated: false)
        }
        self.factionControl.selectAllSegments(false)
        
        // type control
        self.typeControl.delegate = self
        self.typeControl.tag = Tags.type.rawValue
        
        self.typeControl.removeAllSegments()
        for i in 0 ..< self.typeNames.count {
            self.typeControl.insertSegment(withTitle: self.typeNames[i], at: i, animated: false)
        }
        self.typeControl.selectAllSegments(false)
        
        // sliders
        self.costSlider.maximumValue = Float(1 + (self.role == .runner ? CardManager.maxRunnerCost : CardManager.maxCorpCost))
        self.muApSlider.maximumValue = Float(1 + (self.role == .runner ? CardManager.maxMU : CardManager.maxAgendaPoints))
        self.strengthSlider.maximumValue = Float(1 + CardManager.maxStrength)
        self.influenceSlider.maximumValue = Float(1 + CardManager.maxInfluence)
        
        self.costSlider.setThumbImage(UIImage(named: "credit_slider"), for: .normal)
        let iconName = self.role == .runner ? "mem_slider" : "point_slider"
        self.muApSlider.setThumbImage(UIImage(named: iconName), for: .normal)
        self.strengthSlider.setThumbImage(UIImage(named: "strength_slider"), for: .normal)
        self.influenceSlider.setThumbImage(UIImage(named: "influence_slider"), for: .normal)
        
        self.clearFilters()
        
        self.previewHeader.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFontWeightRegular)
        self.previewTable.rowHeight = 30
        self.previewTable.tableFooterView = UIView(frame: CGRect.zero)
        self.showPreviewTable = true
        
        if self.parent?.view.frame.size.height == 480 {
            self.previewTable.isScrollEnabled = false
            self.showPreviewTable = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        assert(self.navigationController?.viewControllers.count == 4, "nav oops")
        
        let clearButton = UIBarButtonItem(title: "Clear".localized(), style: .plain, target: self, action: #selector(self.clearFiltersTapped(_:)))
        self.navigationItem.rightBarButtonItem = clearButton
    }
    
    func clearFiltersTapped(_ sender: Any) {
        self.clearFilters()
    }
    
    func clearFilters() {
        self.cardList.clearFilters()
        
        self.factionControl.selectAllSegments(false)
        self.miniFactionControl.selectAllSegments(false)
        self.typeControl.selectAllSegments(false)
        
        self.influenceSlider.value = 0.0
        self.strengthSlider.value = 0
        self.muApSlider.value = 0
        self.costSlider.value = 0
        
        self.influenceChanged(nil)
        self.strengthChanged(nil)
        self.muApChanged(nil)
        self.costChanged(nil)
        
        self.selectedTypes = Set(self.typeNames)
        self.subtypes = nil
        
        if self.showPreviewTable {
            let top = IndexPath(row: 0, section: 0)
            self.previewTable.scrollToRow(at: top, at: .middle, animated: false)
        }
    }
    
    @IBAction func strengthChanged(_ slider: UISlider?) {
        var value = Int(round(slider?.value ?? 0))
        slider?.value = Float(value)
        value -= 1
        self.strengthLabel.text = String(format: "Strength: %@".localized(), value == -1 ? "All" : String(value))
        self.cardList.filterByStrength(value)
        self.updatePreview()
    }
    
    @IBAction func costChanged(_ slider: UISlider?) {
        var value = Int(round(slider?.value ?? 0))
        slider?.value = Float(value)
        value -= 1
        self.costLabel.text = String(format: "Cost: %@".localized(), value == -1 ? "All" : String(value))
        self.cardList.filterByCost(value)
        self.updatePreview()
    }
    
    @IBAction func influenceChanged(_ slider: UISlider?) {
        var value = Int(round(slider?.value ?? 0))
        slider?.value = Float(value)
        value -= 1
        self.influenceLabel.text = String(format: "Influence: %@".localized(), value == -1 ? "All" : String(value))
        
        if let identity = self.identity {
            self.cardList.filterByInfluence(value, forFaction: identity.faction)
        } else {
            self.cardList.filterByInfluence(value)
        }
        self.updatePreview()
    }
    
    @IBAction func muApChanged(_ slider: UISlider?) {
        var value = Int(round(slider?.value ?? 0))
        slider?.value = Float(value)
        value -= 1
        let fmt = self.role == .runner ? "MU: %@".localized() : "AP: %@".localized()
        self.muApLabel.text = String(format: fmt, value == -1 ? "All" : String(value))
        
        if self.role == .runner {
            self.cardList.filterByMU(value)
        } else {
            self.cardList.filterByAgendaPoints(value)
        }
        self.updatePreview()
    }
    
    @IBAction func selectSubtype(_ btn: UIButton) {
        let picker = BrowserValuePicker(title: "Subtype".localized())
        
        var subtypes = CardManager.subtypesFor(role: self.role, andTypes: self.selectedTypes, includeIdentities: false)
        subtypes.insert(Constant.kANY, at: 0)
        
        picker.data = TableData(values: subtypes)
        
        picker.preselected = self.subtypes
        picker.setResult = { result in
            self.subtypes = result
            self.cardList.filterBySubtype(result)
            self.updatePreview()
        }
        
        self.navigationController?.pushViewController(picker, animated: true)
    }
    
    // MARK: - multi select delegate
    func multiSelect(_ control: MultiSelectSegmentedControl!, didChangeValue value: Bool, at index: UInt) {
        var set = Set<String>()
        
        if control.tag == Tags.type.rawValue {
            for idx in control.selectedSegmentIndexes {
                let type = self.typeNames[idx]
                set.insert(type)
            }
            self.selectedTypes = set
            self.subtypes = nil
            self.cardList.filterBySubtype(FilterValue.strings(Set<String>()))
            self.cardList.filterByType(FilterValue.strings(set))
        } else {
            for idx in self.factionControl.selectedSegmentIndexes {
                let faction = self.factionNames[idx]
                set.insert(faction)
            }
            if self.role == .runner {
                for idx in self.miniFactionControl.selectedSegmentIndexes {
                    let faction = self.factionNames[idx + 4]
                    set.insert(faction)
                }
            }
            
            self.cardList.filterByFaction(FilterValue.strings(set))
        }
        
        self.updatePreview()
    }
    
    func updatePreview() {
        self.cards = self.cardList.allCards()
        
        let count = self.cards.count
        let fmt = count == 1 ? "%lu matching card".localized() : "%lu matching cards".localized()
        self.previewHeader.text = "  " + String(format: fmt, count)
        
        self.previewTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.showPreviewTable ? self.cards.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "previewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? {
            let c = UITableViewCell(style: .default, reuseIdentifier: identifier)
            c.selectionStyle = .none
            c.textLabel?.font = UIFont.systemFont(ofSize: 13)
            c.textLabel?.textColor = .darkGray
            return c
        }()
        
        let card = self.cards[indexPath.row]
        cell.textLabel?.text = card.name
        
        return cell
    }
    
}
