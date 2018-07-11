//
//  CardImageViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.10.16.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import UIKit

class CardImageViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    var selectedCard = Card.null()

    var showAsDifferences = false
    
    private var cards = [Card]()
    private var counts = [Int]()
    private var initialScrollDone = false
    private var mwl: MWL!
    private var deck: Deck?
    var peeking = false {
        didSet {
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.scrollToSelected()
        }
    }

    init(peeking: Bool = false) {
        super.init(nibName: "CardImageViewController", bundle: nil)

        self.peeking = peeking
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.collectionView.backgroundColor = .clear
        
        let nib = UINib(nibName: "CardImageViewCell", bundle: nil)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "cardCell")
        
        self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        self.collectionView.scrollFix()
        self.collectionView.prefetchDataSource = self
    }

    override var prefersStatusBarHidden: Bool {
        return Device.isIphone4
    }

    func setCards(_ cards: [Card], mwl: MWL, deck: Deck?) {
        self.cards = cards
        self.mwl = mwl
        self.counts.removeAll()
        self.deck = deck
        if deck != nil {
            let addButton = UIBarButtonItem(title: "Add to Deck".localized(), style: .plain, target: self, action: #selector(self.addToDeck(_:)))
            self.navigationItem.rightBarButtonItem = addButton
        }
    }
    
    func setCardCounters(_ cardCounters: [CardCounter], mwl: MWL) {
        self.cards.removeAll()
        self.counts.removeAll()
        
        cardCounters.forEach {
            self.cards.append($0.card)
            self.counts.append($0.count)
        }
        
        self.mwl = mwl
        self.deck = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard !self.initialScrollDone else {
            return
        }
        self.initialScrollDone = true
        
        if self.cards.count == 1 {
            var inset = self.collectionView.contentInset
            let frameWidth = self.collectionView.frame.size.width
            let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            let offset = (frameWidth - layout.itemSize.width - layout.minimumLineSpacing * 2.0) / 2.0
            inset.left = offset
            inset.right = offset
            self.collectionView.contentInset = inset
        }

        self.scrollToSelected()
    }

    private func scrollToSelected() {
        if let row = self.cards.index(where: { $0.code == self.selectedCard.code }) {
            let indexPath = IndexPath(row: row, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
    }

    @objc func addToDeck(_ button: UIBarButtonItem) {
        let paths = self.collectionView.indexPathsForVisibleItems.sorted { $0.row < $1.row }
        var path: IndexPath
        switch paths.count {
        case 1:
            path = paths[0]
        case 2:
            // left or right edge?
            path = paths[0].row == 0 ? paths[0] : paths[1]
        case 3:
            path = paths[1]
        default: return
        }

        let card = self.cards[path.row]
        self.deck?.addCard(card, copies: 1)

        self.collectionView.reloadItems(at: paths)
    }
}

// MARK: - collection view
extension CardImageViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.cards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cardCell", for: indexPath) as! CardImageViewCell
        
        cell.showAsDifferences = self.showAsDifferences
        
        let card = self.cards[indexPath.row]
        let cc = self.deck?.findCard(card)
        
        if self.counts.count == 0 && cc?.count == 0 {
            cell.setCard(card, mwl: self.mwl)
        } else {
            var count = 0
            if self.counts.count > 0 {
                count = self.counts[indexPath.row]
            }
            if count == 0 {
                count = cc?.count ?? 0
            }
            cell.setCard(card, count: count, mwl: self.mwl)
        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.peeking ? 100 : 10
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let margin: CGFloat = self.peeking ? 100 : 0
        return UIEdgeInsetsMake(0, margin, 0, margin)
    }
}

extension CardImageViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        indexPaths.forEach {
            let card = self.cards[$0.row]
            ImageCache.sharedInstance.getImage(for: card) { _,_,_ in }
        }
    }
}

