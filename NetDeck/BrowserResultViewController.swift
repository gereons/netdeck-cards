//
//  BrowserResultViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 07.01.17.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class BrowserResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PopupDisplayer {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var sortType = BrowserSort.byType
    private var cardList: CardList!
    private var sections = [String]()
    private var values = [[Card]]()
    private var toggeViewButton: UIBarButtonItem!
    private var sortButton: UIBarButtonItem!
    private var popup: UIAlertController!
    private var largeCells = false
    private var scale = 1.0
    
    private var keyboardObserver: KeyboardObserver!
    
    private let sortStr: [ BrowserSort: String] = [
        .byType: "Type".localized(),
        .byFaction: "Faction".localized(),
        .byTypeFaction: "Type/Faction".localized(),
        .bySet: "Set".localized(),
        .bySetFaction: "Set/Faction".localized(),
        .bySetType: "Set/Type".localized(),
        .bySetNumber: "Set/Number".localized(),
        .byCost: "Cost".localized(),
        .byStrength: "Strength".localized()
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scale: Double = Defaults[.browserViewScale]
        self.scale = scale == 0 ? 1.0 : scale

        self.sortType = Defaults[.browserViewSort]
        
        // left buttons
        let selections = [
            UIImage(named: "deckview_card") as Any,
            UIImage(named: "deckview_table") as Any,
            UIImage(named: "deckview_list") as Any
        ]
        let viewSelector = UISegmentedControl(items: selections)
        let viewStyle = Defaults[.browserViewStyle]
        viewSelector.selectedSegmentIndex = viewStyle.rawValue
        viewSelector.addTarget(self, action: #selector(self.toggleView(_:)), for: .valueChanged)
        
        self.toggeViewButton = UIBarButtonItem(customView: viewSelector)
        self.doToggleView(viewStyle)
        
        self.navigationController?.navigationBar.barTintColor = .white
        self.navigationItem.leftBarButtonItem = self.toggeViewButton
        
        // right buttons
        let arrow = Constant.arrow
        self.sortButton = UIBarButtonItem(title: self.sortStr[self.sortType]! + arrow, style: .plain, target: self, action: #selector(self.sortPopup(_:)))
        let titles = self.sortStr.values.map { $0 + arrow }
        self.sortButton.possibleTitles = Set(titles)
        
        self.navigationItem.rightBarButtonItem = self.sortButton
        
        self.parent?.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.tableView.backgroundColor = .clear
        self.collectionView.backgroundColor = .clear
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        self.tableView.register(UINib(nibName: "SmallBrowserCell", bundle: nil), forCellReuseIdentifier: "smallBrowserCell")
        self.tableView.register(UINib(nibName: "LargeBrowserCell", bundle: nil), forCellReuseIdentifier: "largeBrowserCell")
        
        self.collectionView.register(UINib(nibName: "BrowserImageCell", bundle: nil), forCellWithReuseIdentifier: "browserImageCell")
        self.collectionView.register(CollectionViewSectionHeader.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "sectionHeader")
        
        let insets = UIEdgeInsets.forScreen()
        self.collectionView.contentInset = insets
        self.collectionView.scrollIndicatorInsets = insets
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.prefetchDataSource = self
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGesture(_:)))
        self.collectionView.addGestureRecognizer(pinch)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGesture(_:)))
        self.collectionView.addGestureRecognizer(longPress)
        
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.headerReferenceSize = CGSize(width: 703, height: 22)
        layout.sectionInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        layout.minimumLineSpacing = 3
        layout.minimumInteritemSpacing = 3
        layout.sectionFootersPinToVisibleBounds = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.keyboardObserver = KeyboardObserver(handler: self)

        self.cardList.sortBy(self.sortType)
        self.updateDisplay(self.cardList)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Defaults[.browserViewScale] = self.scale
        Defaults[.browserViewSort] = self.sortType
    }
    
    func updateDisplay(_ cardList: CardList) {
        self.cardList = cardList
        
        let data = cardList.dataForTableView()
        self.sections = data.sections
        self.values = data.values
        
        self.reloadViews()
    }
    
    @objc func sortPopup(_ sender: UIBarButtonItem) {
        if self.popup != nil {
            self.popup.dismiss(animated: false, completion: nil)
            self.popup = nil
            return
        }
        
        self.popup = UIAlertController.actionSheet(title: "Sort by".localized(), message: nil)
        
        self.popup.addAction(UIAlertAction(title: "Type".localized()) { action in
            self.changeSortType(.byType)
        })
        self.popup.addAction(UIAlertAction(title: "Faction".localized()) { action in
            self.changeSortType(.byFaction)
        })
        self.popup.addAction(UIAlertAction(title: "Type/Faction".localized()) { action in
            self.changeSortType(.byTypeFaction)
        })
        self.popup.addAction(UIAlertAction(title: "Set".localized()) { action in
            self.changeSortType(.bySet)
        })
        self.popup.addAction(UIAlertAction(title: "Set/Faction".localized()) { action in
            self.changeSortType(.bySetFaction)
        })
        self.popup.addAction(UIAlertAction(title: "Set/Type".localized()) { action in
            self.changeSortType(.bySetType)
        })
        self.popup.addAction(UIAlertAction(title: "Set/Number".localized()) { action in
            self.changeSortType(.bySetNumber)
        })
        self.popup.addAction(UIAlertAction(title: "Cost".localized()) { action in
            self.changeSortType(.byCost)
        })
        self.popup.addAction(UIAlertAction(title: "Strength".localized()) { action in
            self.changeSortType(.byStrength)
        })
        
        self.popup.addAction(UIAlertAction.actionSheetCancel { action in
            self.popup = nil
        })
        
        let popover = self.popup.popoverPresentationController
        popover?.barButtonItem = sender
        popover?.sourceView = self.view
        popover?.permittedArrowDirections = .any
        self.popup.view.layoutIfNeeded()
        
        self.present(self.popup, animated: false, completion: nil)
    }
    
    func changeSortType(_ sort: BrowserSort) {
        self.sortType = sort
        
        self.sortButton.title = self.sortStr[sort]! + Constant.arrow
        self.cardList.sortBy(self.sortType)
        self.updateDisplay(self.cardList)
        self.popup = nil
    }
    
    @objc func toggleView(_ sender: UISegmentedControl) {
        let viewStyle = CardView(rawValue: sender.selectedSegmentIndex) ?? .largeTable
        Defaults[.browserViewStyle] = viewStyle
        self.doToggleView(viewStyle)
    }
    
    func doToggleView(_ style: CardView) {
        self.tableView.isHidden = style == .image
        self.collectionView.isHidden = style != .image
        
        self.largeCells = style == .largeTable
        
        self.reloadViews()
    }
    
    func reloadViews() {
        guard self.tableView != nil, self.collectionView != nil else {
            return
        }
        
        if !self.tableView.isHidden {
            self.tableView.reloadData()
        }
        if !self.collectionView.isHidden {
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.reloadData()
        }
    }
    
    // MARK: - table view
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.largeCells ? 82 : 40
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.values[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.tableView.isHidden ? 0 : self.sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(self.sections[section]) (\(self.values[section].count))"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = self.largeCells ? "largeBrowserCell" : "smallBrowserCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! BrowserCell
        
        guard let card = self.values[indexPath] else {
            return cell
        }

        cell.card = card
        cell.parent = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = self.values[indexPath.section][indexPath.row]
        let rect = self.tableView.rectForRow(at: indexPath)
        CardImageViewPopover.show(for: card, from: rect, in: self, subView: self.tableView)
    }
    
    // MARK: - collection view 
    
    let cardWidth = 225.0
    let cardHeight = 313.0
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = cardWidth * self.scale
        let height = cardHeight * self.scale
        return CGSize(width: Int(width), height: Int(height))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 2, left: 2, bottom: 5, right: 2)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.collectionView.isHidden ? 0 : self.sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.values[section].count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier = "browserImageCell"
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! BrowserImageCell
        
        guard let card = self.values[indexPath] else {
            return cell
        }

        cell.loadImage(for: card)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        let card = self.values[indexPath.section][indexPath.row]
        
        self.showPopup(for: card, in: collectionView, from: cell.frame)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeader", for: indexPath) as! CollectionViewSectionHeader
        header.title.text = "\(self.sections[indexPath.section]) (\(self.values[indexPath.section].count))"
        
        return header
    }
    
    func showPopup(for card: Card, in view: UIView, from rect: CGRect) {
        let sheet = UIAlertController.actionSheet(title: nil, message: nil)
        
        sheet.addAction(UIAlertAction(title: "Find decks using this card".localized()) { action in
            NotificationCenter.default.post(name: Notifications.browserFind, object: self, userInfo: [ "code": card.code ])
        })
        sheet.addAction(UIAlertAction(title: "New deck with this card".localized()) { action in
            NotificationCenter.default.post(name: Notifications.browserNew, object: self, userInfo: [ "code": card.code ])
        })
        sheet.addAction(UIAlertAction(title: "NetrunnerDB page for this card".localized()) { action in
            Analytics.logEvent(.openNRDB, attributes: ["Card": card.name])
            if let nrdbUrl = URL(string: card.nrdbLink) {
                UIApplication.shared.open(nrdbUrl)
            }
        })
        
        let popover = sheet.popoverPresentationController
        popover?.sourceRect = rect
        popover?.sourceView = view
        popover?.permittedArrowDirections = .any
        sheet.view.layoutIfNeeded()
        
        self.present(sheet, animated: false, completion: nil)
    }

    // MARK: - long press
    
    @objc func longPressGesture(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else {
            return
        }
        
        let point = gesture.location(in: self.collectionView)
        if let indexPath = self.collectionView.indexPathForItem(at: point),
            let cell = self.collectionView.cellForItem(at: indexPath) {
            let card = self.values[indexPath.section][indexPath.row]
            CardImageViewPopover.show(for: card, from: cell.frame, in: self, subView: self.collectionView)
        }
    }
    
    // MARK: - pinch 
    
    private var scaleStart = 0.0
    private var startIndex: IndexPath?
    @objc func pinchGesture(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began {
            self.scaleStart = self.scale
            let startPoint = gesture.location(in: self.collectionView)
            self.startIndex = self.collectionView.indexPathForItem(at: startPoint)
        } else if gesture.state == .changed {
            self.scale = self.scaleStart * Double(gesture.scale)
            self.scale = max(self.scale, 0.5)
            self.scale = min(self.scale, 1.0)
            
            self.collectionView.collectionViewLayout.invalidateLayout()
            if let startIndex = self.startIndex {
                var ok = startIndex.section < self.values.count
                if ok {
                    let arr = self.values[startIndex.section]
                    ok = startIndex.row < arr.count
                }
                if ok {
                    self.collectionView.scrollToItem(at: startIndex, at: .centeredVertically, animated: false)
                }
            }
        } else if gesture.state == .ended {
            self.startIndex = nil
        }
    }
}

extension BrowserResultViewController: UICollectionViewDataSourcePrefetching {

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        indexPaths.forEach {
            let card = self.values[$0.section][$0.row]
            ImageCache.sharedInstance.getImage(for: card) { _,_,_ in }
        }

    }
    
}

// MARK: - keyboard
extension BrowserResultViewController: KeyboardHandling {
    func keyboardWillShow(_ info: KeyboardInfo) {
        let screenHeight = UIScreen.main.bounds.size.height
        let kbHeight = screenHeight - info.endFrame.origin.y
        
        let insets = UIEdgeInsets.forScreen(bottom: kbHeight)
        
        self.tableView.contentInset = insets
        self.tableView.scrollIndicatorInsets = insets
        self.collectionView.contentInset = insets
        self.collectionView.scrollIndicatorInsets = insets
    }
    
    func keyboardWillHide(_ info: KeyboardInfo) {
        let insets = UIEdgeInsets.forScreen()
        self.tableView.contentInset = insets
        self.tableView.scrollIndicatorInsets = insets
        self.collectionView.contentInset = insets
        self.collectionView.scrollIndicatorInsets = insets
    }
}
