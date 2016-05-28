//
//  BrowserViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 09.04.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit


class BrowserViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var setButton: UIButton!
    @IBOutlet weak var factionButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    private var role = NRRole.None
    private var cardList: CardList!
    private var cards = [[Card]]()
    private var sections = [String]()
    
    // filter criteria
    private var searchText = ""
    private var types = Set<String>()
    private var sets = Set<String>()
    private var factions = Set<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Browser".localized()
        Analytics.logEvent("Browser", attributes: [ "Device": "iPhone" ])
        
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.tableView.tableFooterView = UIView(frame:CGRect.zero)
        self.tableView.backgroundColor = UIColor.clearColor()
        
        self.searchBar.scopeButtonTitles = [ "Both".localized(), "Runner".localized(), "Corp".localized() ]
        self.searchBar.showsCancelButton = false
        self.searchBar.showsScopeBar = true
        
        self.typeButton.setTitle("Type".localized(), forState: .Normal)
        self.setButton.setTitle("Set".localized(), forState: .Normal)
        self.factionButton.setTitle("Faction".localized(), forState: .Normal)
        self.clearButton.setTitle("Clear".localized(), forState: .Normal)
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector:#selector(BrowserViewController.showKeyboard(_:)), name:UIKeyboardWillShowNotification, object:nil)
        nc.addObserver(self, selector:#selector(BrowserViewController.hideKeyboard(_:)), name:UIKeyboardWillHideNotification, object:nil)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(BrowserViewController.longPress(_:)))
        self.tableView.addGestureRecognizer(longPress)

        self.refresh()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let filtersActive = CardManager.cardsAvailable() && CardSets.setsAvailable()
        
        self.typeButton.enabled = filtersActive
        self.setButton.enabled = filtersActive
        self.factionButton.enabled = filtersActive
        self.clearButton.enabled = filtersActive
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func refresh() {
        self.cardList = CardList.browserInitForRole(self.role)
        if self.searchText.length > 0 {
            self.cardList.filterByName(self.searchText)
        }
        
        if self.types.count > 0 {
            self.cardList.filterByTypes(self.types)
        }
        
        if self.sets.count > 0 {
            self.cardList.filterBySets(self.sets)
        }
        
        if self.factions.count > 0 {
            self.cardList.filterByFactions(self.factions)
        }
        
        let data = self.cardList.dataForTableView()
        self.cards = data.values as! [[Card]]
        self.sections = data.sections as! [String]
        
        self.tableView.reloadData()
    }
    
    // MARK: table view
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let arr = self.cards[section]
        return arr.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let arr = self.cards[section]
    
        return String(format:"%@ (%ld)", self.sections[section], arr.count)
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "browserCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier:cellIdentifier)
            cell!.selectionStyle = .None
            cell!.accessoryType = .DisclosureIndicator
            
            let pips = SmallPipsView.createWithFrame(CGRectMake(0,0,38,38))
            cell!.accessoryView = pips
        }
    
        let card = self.cards[indexPath.section][indexPath.row]
        cell!.textLabel?.text = card.name
    
        switch card.type {
        
        case .Identity:
            let inf = card.influenceLimit == -1 ? "∞" : "\(card.influenceLimit)"
            cell!.detailTextLabel?.text = String(format: "%@ · %ld/%@", card.factionStr, card.minimumDecksize, inf)
        
        case .Agenda:
            cell!.detailTextLabel?.text = String(format: "%@ · %ld/%ld", card.factionStr, card.advancementCost, card.agendaPoints)
            
        default:
            cell!.detailTextLabel?.text = String(format: "%@ · %l@ Cr", card.factionStr, card.costString)
        }
    
        let pips = cell!.accessoryView as! SmallPipsView
        pips.setValue(card.influence)
        pips.setColor(card.factionColor)
    
        return cell!
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let card = self.cards[indexPath.section][indexPath.row]
    
        let img = CardImageViewController(nibName: "CardImageViewController", bundle: nil)
    
        // flatten our 2d cards array into a single list
        var cards = [Card]()
        for c in self.cards {
            cards.appendContentsOf(c)
        }
        img.setCards(cards)
        img.selectedCard = card
    
        self.navigationController?.pushViewController(img, animated:true)
    }
    
    // MARK: - search bar
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.role = NRRole(rawValue: selectedScope - 1)!
        self.refresh()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        self.refresh()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = false
        self.searchBar.resignFirstResponder()
    }
    
    // MARK: type, factio & set buttons
    @IBAction func typeButtonTapped(btn: UIButton) {
        
        let picker = BrowserValuePicker(title: "Type".localized())
        if role == .None {
            picker.data = CardType.allTypes
        } else {
            let types = CardType.typesForRole(role)
            picker.data = TableData(values: types)
        }
        
        picker.preselected = self.types
        picker.setResult = { result in
            self.types = result
            self.refresh()
        }
    
        self.navigationController?.pushViewController(picker, animated: true)
    }
    
    
    @IBAction func setButtonTapped(btn: UIButton) {
        let picker = BrowserValuePicker(title: "Set".localized())
        picker.data = CardSets.allEnabledSetsForTableview()
        picker.preselected = self.sets
        picker.setResult = { result in
            self.sets = result
            self.refresh()
        }
        
        self.navigationController?.pushViewController(picker, animated: true)
    }
    
    @IBAction func factionButtonTapped(btn: UIButton) {
        let picker = BrowserValuePicker(title: "Faction".localized())
        picker.data = Faction.factionsForBrowser()
        picker.preselected = self.factions
        picker.setResult = { result in
            self.factions = result
            self.refresh()
        }
        
        self.navigationController?.pushViewController(picker, animated: true)
    }
    
    // MARK: clear button
    
    @IBAction func clearButtonTapped(btn: UIButton) {
        self.sets.removeAll()
        self.types.removeAll()
        self.factions.removeAll()
        self.searchText = ""
        
        self.refresh()
    }

    // MARK: keyboard show/hide
    @objc func showKeyboard(notification: NSNotification) {
        let kbRect = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        let kbHeight = kbRect.CGRectValue().size.height
        
        var inset = self.tableView.contentInset
        inset.bottom = kbHeight
        self.tableView.contentInset = inset
        self.tableView.scrollIndicatorInsets = inset
    }
    
    @objc func hideKeyboard(nta: NSNotification) {
        var inset = self.tableView.contentInset
        inset.bottom = 0
        self.tableView.contentInset = inset
        self.tableView.scrollIndicatorInsets = inset
    }
    
    // MARK: long press
    @objc func longPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .Began {
            let point = gesture.locationInView(self.tableView)
            if let indexPath = self.tableView.indexPathForRowAtPoint(point) {
                let card = self.cards[indexPath.section][indexPath.row]
                
                let msg = String(format:"Open web page for\n%@?".localized(), card.name)
                
                let alert = UIAlertController.alertWithTitle(nil, message: msg)
                alert.addAction(UIAlertAction(title:"ANCUR".localized()) { action in
                    if let ancur = card.ancurLink, url = NSURL(string: ancur) {
                        UIApplication.sharedApplication().openURL(url)
                    }
                })
                alert.addAction(UIAlertAction(title:"NetrunnerDB".localized()) { action in
                    if let url = NSURL(string: card.nrdbLink) {
                        UIApplication.sharedApplication().openURL(url)
                    }
                })
                
                alert.addAction(UIAlertAction.cancelAlertAction(nil))
                
                self.presentViewController(alert, animated:false, completion:nil)
            }
        }
    }
}

