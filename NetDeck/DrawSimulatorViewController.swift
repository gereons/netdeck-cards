//
//  DrawSimulatorViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 13.12.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit

class DrawSimulatorViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var viewModeControl: UISegmentedControl!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var drawnLabel: UILabel!
    @IBOutlet weak var oddsLabel: UILabel!
    
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var selector: UISegmentedControl!
    
    var deck: Deck!
    var cards = [Card]()
    var drawn = [Card]()
    var played = [Bool]()
    
    static var viewMode = 0
    
    class func showForDeck(_ deck: Deck, inViewController vc: UIViewController) {
        let dvw = DrawSimulatorViewController()
        dvw.deck = deck
        dvw.modalPresentationStyle = .formSheet
        vc.present(dvw, animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Analytics.logEvent("Draw Sim", attributes: ["Device": "iPad"])
        
        self.initCards(true)
        
        self.titleLabel.text = "Draw Simulator".localized()
        self.clearButton.setTitle("Clear".localized(), for: UIControlState())
        self.doneButton.setTitle("Done".localized(), for: UIControlState())
        
        self.selector.setTitle("All".localized(), forSegmentAt:6)
        self.selector.apportionsSegmentWidthsByContent = true
        
        self.viewModeControl.selectedSegmentIndex = DrawSimulatorViewController.viewMode
        
        self.tableView.tableFooterView = UIView(frame:CGRect.zero)
        self.tableView.isHidden = DrawSimulatorViewController.viewMode == 0
        
        self.collectionView.register(UINib(nibName:"CardThumbView", bundle:nil),forCellWithReuseIdentifier:"cardThumb")
        self.collectionView.isHidden = DrawSimulatorViewController.viewMode == 1
        
        // each view needs its own long press recognizer
        self.tableView.addGestureRecognizer(UILongPressGestureRecognizer(target:self, action:#selector(DrawSimulatorViewController.longPress(_:))))
        self.collectionView.addGestureRecognizer(UILongPressGestureRecognizer(target:self, action:#selector(DrawSimulatorViewController.longPress(_:))))
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        self.oddsLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: UIFontWeightRegular)
        self.drawnLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFontWeightRegular)
    }
    
    func initCards(_ drawInitialHand: Bool) {
        self.drawn = [Card]()
        self.cards = [Card]()
        self.played = [Bool]()
        
        for cc in self.deck.cards {
            for _ in 0 ..< cc.count {
                cards.append(cc.card)
            }
        }
        
        assert(self.cards.count == self.deck.size, "oops")
        
        self.cards.shuffle()
        
        self.oddsLabel.text = ""
        self.drawnLabel.text = ""
        
        if drawInitialHand {
            var handSize = 5
            if self.deck.identity?.code == Card.andromeda {
                handSize = 9
            }
            self.drawCards(handSize)
        }
    }
    
    func drawCards(_ numCards: Int) {
        for _ in 0..<numCards {
            if self.cards.count > 0 {
                let card = self.cards[0]
                cards.removeFirst()
                self.drawn.append(card)
                self.played.append(false)
            }
        }
        
        assert(self.drawn.count == self.played.count, "oops")
        
        let drawn = self.drawn.count
        self.drawnLabel.text = String(format:"%ld %@ drawn".localized(),
            drawn, drawn==1 ? "Card".localized() : "Cards".localized())
        
        self.tableView.reloadData()
        self.collectionView.reloadData()
        
        // scroll down if not all cards were drawn
        if numCards != self.deck.size && self.drawn.count > 0 {
            let indexPath = IndexPath(row: self.drawn.count-1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
        }
        
        // calculate drawing odds
        let fmt = "Odds to draw a card: 1×%.2f%%  2×%.2f%%  3×%.2f%%".localized()
        let odds = String(format: fmt, self.oddsFor(1), self.oddsFor(2), self.oddsFor(3))
        self.oddsLabel.text = odds
    }
    
    func oddsFor(_ cards: Int) -> Double {
        let odds = 100.0 * Hypergeometric.getProbabilityFor(1, cardsInDeck:self.deck.size, desiredCardsInDeck:min(self.deck.size, cards), cardsDrawn:self.drawn.count)
        return odds
    }
    
    // MARK: table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.drawn.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "drawCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
            cell!.selectionStyle = .none
        }
        
        let card = self.drawn[indexPath.row]
        cell!.textLabel?.text = card.name
        cell!.textLabel?.textColor = self.played[indexPath.row] ? UIColor.lightGray : UIColor.black
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = self.drawn[indexPath.row]
        
        let rect = self.tableView.rectForRow(at: indexPath)
        
        CardImageViewPopover.show(for: card, from: rect, in:self, subView:self.tableView)
    }
    
    // MARK: collection view
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.drawn.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cardThumb", for: indexPath) as! CardThumbView
        
        let card = self.drawn[indexPath.row]
        cell.card = card
        cell.imageView.layer.opacity = self.played[indexPath.row] ? 0.5 : 1
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 160, height: 119)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let card = self.drawn[indexPath.row]
        let cell = collectionView.cellForItem(at: indexPath)
        let rect = collectionView.convert(cell!.frame, to: collectionView)
        
        CardImageViewPopover.show(for: card, from: rect, in:self, subView:self.collectionView)
    }
    
    // MARK: long press
    
    func longPress(_ gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            var indexPath: IndexPath?
            if self.tableView.isHidden {
                let point = gesture.location(in: self.collectionView)
                indexPath = self.collectionView.indexPathForItem(at: point)
            } else {
                let point = gesture.location(in: self.tableView)
                indexPath = self.tableView.indexPathForRow(at: point)
            }
            
            if let indexPath = indexPath {
                let played = self.played[indexPath.row]
                self.played[indexPath.row] = !played
                let paths = [ indexPath ]
                
                self.tableView.reloadRows(at: paths, with: .none)
                self.collectionView.reloadItems(at: paths)
            }
        }
    }
    
    // MARK: button actions
    
    @IBAction func done(_ sender: UIButton) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func clear(_ sender: UIButton) {
        self.initCards(false)
        self.tableView.reloadData()
        self.collectionView.reloadData()
    }
    
    @IBAction func draw(_ sender: UISegmentedControl) {
        // segments are: 0=1, 1=2, 2=3, 3=4, 4=5, 5=9, 6=All
        var numCards = 0
        switch (sender.selectedSegmentIndex) {
        case 5:
            numCards = 9
        case 6: // all
            numCards = self.deck.size
        default:
            numCards = sender.selectedSegmentIndex + 1
        }
        
        self.drawCards(numCards)
    }
    
    @IBAction func viewModeChange(_ sender: UISegmentedControl) {
        DrawSimulatorViewController.viewMode = sender.selectedSegmentIndex
        self.tableView.isHidden = DrawSimulatorViewController.viewMode == 0
        self.collectionView.isHidden = DrawSimulatorViewController.viewMode == 1
    }
}
