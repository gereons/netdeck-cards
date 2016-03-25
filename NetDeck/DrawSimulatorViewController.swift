//
//  DrawSimulatorViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 13.12.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

class DrawSimulatorViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var viewModeControl: UISegmentedControl!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: DrawSimulatorCollectionView!
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
    
    class func showForDeck(deck: Deck, inViewController vc: UIViewController) {
        let dvw = DrawSimulatorViewController()
        dvw.deck = deck
        dvw.modalPresentationStyle = .FormSheet
        vc.presentViewController(dvw, animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initCards(true)
        
        self.titleLabel.text = "Draw Simulator".localized()
        self.clearButton.setTitle("Clear".localized(), forState: .Normal)
        self.doneButton.setTitle("Done".localized(), forState: .Normal)
        
        self.selector.setTitle("All".localized(), forSegmentAtIndex:6)
        self.selector.apportionsSegmentWidthsByContent = true
        
        self.viewModeControl.selectedSegmentIndex = DrawSimulatorViewController.viewMode
        
        self.tableView.tableFooterView = UIView(frame:CGRectZero)
        self.tableView.hidden = DrawSimulatorViewController.viewMode == 0
        
        self.collectionView.registerNib(UINib(nibName:"CardThumbView", bundle:nil),forCellWithReuseIdentifier:"cardThumb")
        self.collectionView.hidden = DrawSimulatorViewController.viewMode == 1
        
        // each view needs its own long press recognizer
        self.tableView.addGestureRecognizer(UILongPressGestureRecognizer(target:self, action:#selector(DrawSimulatorViewController.longPress(_:))))
        self.collectionView.addGestureRecognizer(UILongPressGestureRecognizer(target:self, action:#selector(DrawSimulatorViewController.longPress(_:))))
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        self.oddsLabel.font = UIFont.monospacedDigitSystemFontOfSize(17, weight: UIFontWeightRegular)
        self.drawnLabel.font = UIFont.monospacedDigitSystemFontOfSize(15, weight: UIFontWeightRegular)
    }
    
    func initCards(drawInitialHand: Bool) {
        self.drawn = [Card]()
        self.cards = [Card]()
        self.played = [Bool]()
        
        for cc in self.deck.cards {
            for _ in 0 ..< cc.count {
                cards.append(cc.card)
            }
        }
        
        assert(self.cards.count == self.deck.size, "oops")
        
        self.cards.shuffleInPlace()
        
        self.oddsLabel.text = ""
        self.drawnLabel.text = ""
        
        if drawInitialHand {
            var handSize = 5
            if self.deck.identity?.code == Card.ANDROMEDA {
                handSize = 9
            }
            self.drawCards(handSize)
        }
    }
    
    func drawCards(numCards: Int) {
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
            let indexPath = NSIndexPath(forRow: self.drawn.count-1, inSection: 0)
            self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: false)
            self.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: false)
        }
        
        // calculate drawing odds
        let odds = String(format: "Odds to draw a card: 1×%.1f%%  2×%.1f%%  3×%.1f%%".localized(),
            self.oddsFor(1), self.oddsFor(2), self.oddsFor(3))
        self.oddsLabel.text = odds
    }
    
    func oddsFor(cards: Int) -> Double {
        return 100.0 * Hypergeometric.getProbabilityFor(1, cardsInDeck:self.deck.size, desiredCardsInDeck:min(self.deck.size, cards), cardsDrawn:self.drawn.count)
    }
    
    // MARK: table view
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.drawn.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "drawCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
            cell!.selectionStyle = .None
        }
        
        let card = self.drawn[indexPath.row]
        cell!.textLabel?.text = card.name
        cell!.textLabel?.textColor = self.played[indexPath.row] ? UIColor.lightGrayColor() : UIColor.blackColor()
        
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let card = self.drawn[indexPath.row]
        
        let rect = self.tableView.rectForRowAtIndexPath(indexPath)
        
        CardImageViewPopover.showForCard(card, fromRect: rect, inViewController:self, subView:self.tableView)
    }
    
    // MARK: collection view
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.drawn.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cardThumb", forIndexPath: indexPath) as! CardThumbView
        
        let card = self.drawn[indexPath.row]
        cell.card = card
        cell.imageView.layer.opacity = self.played[indexPath.row] ? 0.5 : 1
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(160, 119)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let card = self.drawn[indexPath.row]
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        let rect = collectionView.convertRect(cell!.frame, toView: collectionView)
        
        CardImageViewPopover.showForCard(card, fromRect: rect, inViewController:self, subView:self.collectionView)
    }
    
    // MARK: long press
    
    func longPress(gesture: UIGestureRecognizer) {
        if gesture.state == .Began {
            var indexPath: NSIndexPath?
            if self.tableView.hidden {
                let point = gesture.locationInView(self.collectionView)
                indexPath = self.collectionView.indexPathForItemAtPoint(point)
            } else {
                let point = gesture.locationInView(self.tableView)
                indexPath = self.tableView.indexPathForRowAtPoint(point)
            }
            
            if indexPath != nil {
                let played = self.played[indexPath!.row]
                self.played[indexPath!.row] = !played
                let paths = [ indexPath! ]
                
                self.tableView.reloadRowsAtIndexPaths(paths, withRowAnimation: .None)
                self.collectionView.reloadItemsAtIndexPaths(paths)
            }
        }
    }
    
    // MARK: button actions
    
    @IBAction func done(sender: UIButton) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func clear(sender: UIButton) {
        self.initCards(false)
        self.tableView.reloadData()
        self.collectionView.reloadData()
    }
    
    @IBAction func draw(sender: UISegmentedControl) {
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
    
    @IBAction func viewModeChange(sender: UISegmentedControl) {
        DrawSimulatorViewController.viewMode = sender.selectedSegmentIndex
        self.tableView.hidden = DrawSimulatorViewController.viewMode == 0
        self.collectionView.hidden = DrawSimulatorViewController.viewMode == 1
    }
}