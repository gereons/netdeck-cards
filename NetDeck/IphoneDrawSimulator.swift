//
//  IphoneDrawSimulator.swift
//  NetDeck
//
//  Created by Gereon Steffens on 04.12.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import UIKit

class DrawTableCell: UITableViewCell {
    fileprivate var card: Card!
    fileprivate var imgView: UIImageView!
}

class IphoneDrawSimulator: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var drawControl: UISegmentedControl!
    @IBOutlet weak var oddsLabel: UILabel!
    
    private var drawn = [Card]()
    private var cards = [Card]()
    private var played = [Bool]()
    var deck: Deck!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.logEvent(.drawSim, attributes: ["Device": "iPhone"])
        assert(self.navigationController?.viewControllers.count == 3, "nav oops")
        
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = .clear
        
        self.title = "Draw Simulator".localized()
        
        self.drawControl.setTitle("All".localized(), forSegmentAt: 6)
        self.drawControl.setTitle("Clear".localized(), forSegmentAt: 7)
        
        self.initCards(drawInitial: true)
        
        self.oddsLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)
    }
    
    @IBAction func drawValueChanged(_ sender: UISegmentedControl) {
        let numCards: Int
        switch sender.selectedSegmentIndex {
        case 5:
            numCards = 9
        case 6:
            numCards = self.deck.size
        case 7:
            self.initCards(drawInitial: false)
            self.tableView.reloadData()
            return
        default:
            numCards = sender.selectedSegmentIndex + 1
        }
        
        self.drawCards(numCards)
    }
    
    func initCards(drawInitial: Bool) {
        self.drawn.removeAll()
        self.cards.removeAll()
        self.played.removeAll()
        
        for cc in self.deck.cards {
            for _ in 0 ..< cc.count {
                self.cards.append(cc.card)
            }
        }
        assert(self.cards.count == self.deck.size, "size mismatch")
        
        self.cards.shuffle()
        
        self.oddsLabel.text = " "
        
        if drawInitial {
            let handsize = self.deck.identity?.code == Card.andromeda ? 9 : 5
            self.drawCards(handsize)
        }
    }
    
    func drawCards(_ numCards: Int) {
        for _ in 0 ..< numCards {
            if self.cards.count > 0 {
                let card = self.cards.removeFirst()
                self.drawn.append(card)
                self.played.append(false)
            }
        }
        
        assert(self.drawn.count == self.played.count, "size mismatch")
        self.tableView.reloadData()
        
        if numCards != self.deck.size && self.drawn.count > 0 {
            let indexPath = IndexPath(row: self.drawn.count - 1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
        
        let odds = String(format: "Odds for a card: 1×%.1f%%  2×%.1f%%  3×%.1f%%".localized(),
                          self.oddsFor(1), self.oddsFor(2), self.oddsFor(3))
        
        self.oddsLabel.text = odds
    }
    
    func oddsFor(_ cards: Int) -> Double {
        return 100.0 * Hypergeometric.getProbabilityFor(1, cardsInDeck: self.deck.size, desiredCardsInDeck: min(self.deck.size, cards), cardsDrawn: self.drawn.count)
    }
    
    // MARK: - table view
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.drawn.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let played = self.played[indexPath.row]
        self.played[indexPath.row] = !played
        
        tableView .reloadRows(at: [indexPath], with: .fade)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "drawCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? DrawTableCell ?? {
            let c = DrawTableCell(style: .default, reuseIdentifier: identifier)
            c.selectionStyle = .none
            c.imgView = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: 60))
            c.accessoryView = c.imgView
            return c
        }()
        
        let card = self.drawn[indexPath.row]
        cell.textLabel?.text = card.name
        cell.textLabel?.textColor = self.played[indexPath.row] ? .lightGray :  .label
        
        cell.card = card
        self.loadImageFor(cell: cell, card: card)
    
        return cell
    }
    
    func loadImageFor(cell: DrawTableCell, card: Card) {
        cell.imgView.image = nil
        
        ImageCache.sharedInstance.getImage(for: card, completion: { card, image, placeHolder in
            if cell.card.code == card.code {
                cell.imgView.image = ImageCache.sharedInstance.croppedImage(image, forCard: card)
            } else {
                self.loadImageFor(cell: cell, card: cell.card)
            }
        })
    }
    
}
