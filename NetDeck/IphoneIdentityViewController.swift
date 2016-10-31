//
//  IphoneIdentityViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.10.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit
/*
class xIphoneIdentityViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var okButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!

    @IBOutlet weak var toolbar: UIToolbar!
    var role = NRRole.none
    var deck: Deck?
    
    private var selectedIdentity: Card?
    private var selectedIndexPath: IndexPath?
    private var identities = [Card]()
    private var factionNames = [String]()
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = UIColor.clear
        
        let tableTap = UITapGestureRecognizer(target: self, action: #selector(self.doubleTap(_:)))
        tableTap.numberOfTapsRequired = 2
        self.tableView.addGestureRecognizer(tableTap)
        
        self.title = "Choose Identity".localized()
        
        self.cancelButton.title = "Cancel".localized()
        if self.deck == nil {
            var barButtons = self.toolbar.items
            if let index = barButtons?.index(where: { $0 == self.cancelButton }) {
                barButtons?.remove(at: index)
                self.toolbar.items = barButtons
            }
        }
        
        self.selectedIdentity = self.deck?.identity
        
        self.initIdentities()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.okButton.isEnabled = self.deck != nil && self.deck?.identity != nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let selected = self.selectedIndexPath {
            self.tableView.selectRow(at: selected, animated: false, scrollPosition: .middle)
        }
    }

    private func initIdentities() {
        let settings = UserDefaults.standard
        
        let useDraft = settings.bool(forKey: SettingsKeys.USE_DRAFT)
        let packs = NRPackUsage(rawValue: settings.integer(forKey: SettingsKeys.DECKBUILDER_PACKS)) ?? .all
        
        var factions = Faction.factionsFor(role: self.role)
        
        self.identities.removeAll()
        self.factionNames = factions
        
        self.selectedIndexPath = nil
        
        let disabledPackCodes: Set<String>
        switch packs {
        case .all: disabledPackCodes = PackManager.draftPackCode()
        case .selected: disabledPackCodes = PackManager.disabledPackCodes()
        case .allAfterRotation: disabledPackCodes = PackManager.rotatedPackCodes()
        }
        
        let identities = CardManager.identitiesFor(role: self.role)
        for faction in factions {
            self.identities.append([Card]())
            
            
        }
    }
    
    
 
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}

*/
