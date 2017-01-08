//
//  IdentitySelectionViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 08.01.17.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

class IdentitySelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var modeSelector: UISegmentedControl!
    @IBOutlet weak var factionSelector: UISegmentedControl!
    
    @IBOutlet weak var factionSelectorWidth: NSLayoutConstraint!
    
    private var role = NRRole.none
    private var allFactionNames = [String]()
    private var allIdentities = [[Card]]()
    private var factionNames = [String]()
    private var identities = [[Card]]()
    private var initialIdentity: Card?
    private var selectedIdentity: Card?
    private var selectedIndexPath: IndexPath?
    private var viewTable = true

    class func showFor(role: NRRole, inViewController vc: UIViewController, withIdentity identity: Card?) {
        let selection = IdentitySelectionViewController(role: role, identity: identity)
        
        vc.present(selection, animated: false, completion: nil)
    }
    
    init(role: NRRole, identity: Card?) {
        super.init(nibName: "IdentitySelectionViewController", bundle: nil)
        
        self.modalPresentationStyle = .formSheet
        
        self.role = role
        self.initialIdentity = identity
        self.selectedIdentity = identity
        
        let settings = UserDefaults.standard
        self.viewTable = settings.bool(forKey: SettingsKeys.IDENTITY_TABLE)
        let packs = settings.integer(forKey: SettingsKeys.DECKBUILDER_PACKS)
        let packUsage = NRPackUsage(rawValue: packs) ?? .all
        let identities = CardManager.identitiesForSelection(self.role, packUsage: packUsage)
        
        self.allFactionNames = identities.sections
        self.allIdentities = identities.values as! [[Card]]
        
        self.factionNames = self.allFactionNames
        self.identities = self.allIdentities
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = "Choose Identity".localized()
        self.okButton.setTitle("Done".localized(), for: .normal)
        self.cancelButton.setTitle("Cancel".localized(), for: .normal)
        
        // setup tableview
        let nib = UINib(nibName: "IdentityViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "identityCell")
        
        let tableTap = UITapGestureRecognizer(target: self, action: #selector(self.doubleTap(_:)))
        tableTap.numberOfTapsRequired = 2
        self.tableView.addGestureRecognizer(tableTap)
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        // setup collectionview
        
        self.collectionView.register(UINib(nibName: "IdentityCardView", bundle: nil), forCellWithReuseIdentifier: "cardThumb")
        self.collectionView.register(CollectionViewSectionHeader.nib(), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "sectionHeader")
        
        let collectionTap = UITapGestureRecognizer(target: self, action: #selector(self.doubleTap(_:)))
        collectionTap.numberOfTapsRequired = 2
        self.collectionView.addGestureRecognizer(collectionTap)
        
        self.collectionView.alwaysBounceVertical = true
        
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.headerReferenceSize = CGSize(width: 500, height: 22)
        layout.sectionInset = UIEdgeInsets(top: 2, left: 2, bottom: 0, right: 2)
        layout.minimumLineSpacing = 3
        layout.minimumInteritemSpacing = 3
        layout.sectionHeadersPinToVisibleBounds = true
        
        self.tableView.isHidden = !self.viewTable
        self.collectionView.isHidden = self.viewTable
        self.modeSelector.selectedSegmentIndex = self.viewTable ? 1 : 0
        
        let settings = UserDefaults.standard
        let includeDraft = settings.bool(forKey: SettingsKeys.USE_DRAFT)
        let dataDestinyAllowed = settings.bool(forKey: SettingsKeys.USE_DATA_DESTINY)
        
        var titles: [String]
        if self.role == .runner {
            titles = dataDestinyAllowed ? Faction.runnerFactionNamesAll : Faction.runnerFactionNamesCore
        } else {
            titles = Faction.corpFactionNames
        }
        
        titles.remove(at: 0)
        titles.remove(at: 0)
        
        titles.insert("All".localized(), at: 0)
        if includeDraft {
            titles.append("Draft".localized())
        }
        
        self.factionSelector.removeAllSegments()
        for i in (0 ..< titles.count).reversed() {
            self.factionSelector.insertSegment(withTitle: titles[i], at: 0, animated: false)
        }
        self.factionSelector.sizeToFit()
        
        self.setupSelectedIdentity()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let selected = self.selectedIndexPath {
            self.tableView.selectRow(at: selected, animated: false, scrollPosition: .middle)
            self.collectionView.selectItem(at: selected, animated: false, scrollPosition: .centeredVertically)
        }
    }
    
    private func setupSelectedIdentity() {
        self.selectedIndexPath = nil
        
        for i in 0 ..< self.identities.count {
            let arr = self.identities[i]
            for j in 0 ..< arr.count {
                let card = arr[j]
                if self.selectedIdentity?.code == card.code {
                    self.selectedIndexPath = IndexPath(row: j, section: i)
                    break
                }
            }
        }
    }

    @IBAction func okClicked(_ sender: Any) {
        if let selected = self.selectedIdentity {
            NotificationCenter.default.post(name: Notifications.selectIdentity, object: self, userInfo: [ "code": selected.code ])
        }
        self.cancelClicked(sender)
    }
    
    @IBAction func cancelClicked(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    func doubleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }
        
        if !self.viewTable {
            let point = gesture.location(in: self.collectionView)
            if let indexPath = self.collectionView.indexPathForItem(at: point) {
                let card = self.identities[indexPath.section][indexPath.row]
                self.selectedIdentity = card
                self.selectedIndexPath = indexPath
            }
        }
        
        self.okClicked(gesture)
    }
    
    @IBAction func viewModeChange(_ sender: UISegmentedControl) {
        self.viewTable = sender.selectedSegmentIndex == 1
        self.tableView.isHidden = !self.viewTable
        self.collectionView.isHidden = self.viewTable
        
        UserDefaults.standard.set(self.viewTable, forKey: SettingsKeys.IDENTITY_TABLE)
        
        if let selected = self.selectedIndexPath {
            self.tableView.reloadData()
            self.tableView.selectRow(at: selected, animated: false, scrollPosition: .middle)
            
            self.collectionView.reloadData()
            self.collectionView.selectItem(at: selected, animated: false, scrollPosition: .centeredVertically)
        }
    }

    @IBAction func factionChange(_ sender: UISegmentedControl) {
        let selected = sender.selectedSegmentIndex
        
        if selected == 0 {
            self.factionNames = self.allFactionNames
            self.identities = self.allIdentities
        } else {
            var factions = self.role == .runner ? Faction.runnerFactionsAll : Faction.corpFactions
            
            if selected - 1 < factions.count {
                let faction = factions[selected - 1]
                self.factionNames = [ Faction.name(for: faction) ]
                self.identities = [ self.allIdentities[selected - 1] ]
                
            } else {
                self.factionNames = [ "Draft".localized() ]
                self.identities = [ self.allIdentities[selected - 1] ]
            }
        }
        
        self.setupSelectedIdentity()
        self.tableView.reloadData()
        self.collectionView.reloadData()
    }

    func showImage(_ sender: UIButton) {
        let buttonPosition = sender.convert(CGPoint.zero, to: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: buttonPosition) {
            let card = self.identities[indexPath.section][indexPath.row]
            var rect = self.tableView.rectForRow(at: indexPath)
            rect.origin.x = sender.frame.origin.x
            
            CardImageViewPopover.show(for: card, from: rect, in: self, subView: self.tableView)
        }
    }
    
    // MARK: - table view
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.identities.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.identities[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "identityCell", for: indexPath) as! IdentityViewCell
        
        cell.infoButton.addTarget(self, action: #selector(self.showImage(_:)), for: .touchUpInside)
        
        cell.accessoryType = .none
        cell.titleLabel.font = UIFont.systemFont(ofSize: 17)
        
        let card = self.identities[indexPath.section][indexPath.row]
        if card.code == self.selectedIdentity?.code {
            cell.accessoryType = .checkmark
            cell.isSelected = true
            cell.titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
            self.selectedIndexPath = indexPath
        }
        
        cell.titleLabel.text = card.name
        cell.titleLabel.textColor = card.factionColor
        
        cell.deckSizeLabel.text = "\(card.minimumDecksize)"
        cell.influenceLimitLabel.text = card.influenceLimit == -1 ? "∞" : "\(card.influenceLimit)"
        
        if self.role == .runner {
            cell.linkLabel.text = "\(card.baseLink)"
            cell.linkIcon.isHidden = false
        } else {
            cell.linkIcon.isHidden = true
            cell.linkLabel.text = nil
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var reloads = [ indexPath ]
        if let selected = self.selectedIndexPath {
            reloads.append(selected)
        }
        
        let card = self.identities[indexPath.section][indexPath.row]
        self.selectedIdentity = card
        self.selectedIndexPath = indexPath
        
        self.tableView.reloadRows(at: reloads, with: .none)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.factionNames[section]
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = UIColor(rgb: 0xEBEBEC)
        let card = self.identities[section][0]
        header.textLabel?.textColor = card.factionColor
    }
    
    // MARK: - collection view
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.identities.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.identities[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cardThumb", for: indexPath) as! IdentityCardView
        
        let card = self.identities[indexPath.section][indexPath.row]
        cell.card = card
        
        cell.selectButton.addTarget(self, action: #selector(self.selectCell(_:)), for: .touchUpInside)
        cell.selectButton.tag = indexPath.section * 1000 + indexPath.row
        
        if self.selectedIndexPath == indexPath {
            cell.layer.borderWidth = 4
            cell.layer.borderColor = card.factionColor.cgColor
            cell.layer.cornerRadius = 8
        } else {
            cell.layer.borderWidth = 0
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let card = self.identities[indexPath.section][indexPath.row]
        if let cell = collectionView.cellForItem(at: indexPath) {
            let rect = collectionView.convert(cell.frame, to: self.collectionView)
            CardImageViewPopover.show(for: card, from: rect, in: self, subView: self.collectionView)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 160, height: 148)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 2, left: 2, bottom: 0, right: 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeader", for: indexPath) as! CollectionViewSectionHeader
        header.title.text = self.factionNames[indexPath.section]
        
        let card = self.identities[indexPath.section][indexPath.row]
        header.title.textColor = card.factionColor
        
        return header
    }
    
    func selectCell(_ sender: UIButton) {
        let section = sender.tag / 1000
        let item = sender.tag - (section * 1000)
        let card = self.identities[section][item]
        
        self.selectedIdentity = card
        self.selectedIndexPath = IndexPath(item: item, section: section)
        
        self.collectionView.reloadData()
    }

}
