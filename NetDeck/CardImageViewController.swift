//
//  CardImageViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.10.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

class CardImageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView!

    var selectedCard = Card.null()

    var showAsDifferences = false
    
    private var cards = [Card]()
    private var counts = [Int]()
    private var initialScrollDone = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.collectionView.backgroundColor = .clear
        
        let nib = UINib(nibName: "CardImageViewCell", bundle: nil)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "cardCell")
        
        self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    override var prefersStatusBarHidden: Bool {
        return Device.isIphone4
    }

    func setCards(_ cards: [Card]) {
        self.cards = cards
        self.counts.removeAll()
    }
    
    func setCardCounters(_ cardCounters: [CardCounter]) {
        self.cards.removeAll()
        self.counts.removeAll()
        
        cardCounters.forEach {
            self.cards.append($0.card)
            self.counts.append($0.count)
        }
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
        
        if let row = self.cards.index(where: { $0.code == self.selectedCard.code }) {
            let indexPath = IndexPath(row: row, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
        
    }
    
    // MARK: - collection view
    
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
        
        if self.counts.count == 0 {
            cell.setCard(card)
        } else {
            cell.setCard(card, andCount: self.counts[indexPath.row])
        }
        
        return cell
    }
}

