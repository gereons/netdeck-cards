
//
//  DeckDiffViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 28.12.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

private enum DiffMode: Int {
    case full
    case diff
    case intersect
    case overlap
}

class DeckDiffViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deck1Name: UILabel!
    @IBOutlet weak var deck2Name: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var reverseButton: UIButton!
    @IBOutlet weak var diffModeControl: UISegmentedControl!
    
    private var deck1: Deck
    private var deck2: Deck
    private var diffMode: DiffMode
    private var diff: DeckDiff!
    
    static func showForDecks(_ deck1: Deck, deck2: Deck, inViewController: UIViewController) {
        Analytics.logEvent(.compareDecks)
        let ddvc = DeckDiffViewController(deck1: deck1, deck2: deck2)
        
        inViewController.present(ddvc, animated: false, completion: nil)
        ddvc.preferredContentSize = CGSize(width: 768, height: 728)
    }
    
    required  init(deck1: Deck, deck2: Deck) {
        self.deck1 = deck1
        self.deck2 = deck2
        self.diffMode = .diff
        
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .formSheet
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = "Deck Comparison".localized()
        
        self.closeButton.setTitle("Done".localized(), for: .normal)
        self.reverseButton.setTitle("Reverse".localized(), for: .normal)
        
        self.diffModeControl.selectedSegmentIndex = DiffMode.diff.rawValue
        self.diffModeControl.setTitle("Full".localized(), forSegmentAt: DiffMode.full.rawValue)
        self.diffModeControl.setTitle("Diff".localized(), forSegmentAt: DiffMode.diff.rawValue)
        self.diffModeControl.setTitle("Intersect".localized(), forSegmentAt: DiffMode.intersect.rawValue)
        self.diffModeControl.setTitle("Overlap".localized(), forSegmentAt: DiffMode.overlap.rawValue)
        self.diffModeControl.apportionsSegmentWidthsByContent = true
        self.diffModeControl.sizeToFit()
        
        self.setup()
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.register(UINib(nibName: "DeckDiffCell", bundle: nil), forCellReuseIdentifier: "diffCell")
        self.tableView.rowHeight = 44
    }
    
    func setup() {
        self.diff = DeckDiff(deck1: self.deck1, deck2: self.deck2)
        
        self.deck1Name.text = self.deck1.name
        self.deck2Name.text = self.deck2.name
    }
    
    
    // MARK: - buttons
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func reverse(_ sender: Any) {
        swap(&self.deck1, &self.deck2)
        
        self.setup()
        self.tableView.reloadData()
    }
    
    @IBAction func diffMode(_ sender: UISegmentedControl) {
        self.diffMode = DiffMode(rawValue: sender.selectedSegmentIndex) ?? .full
        
        self.tableView.reloadData()
    }
    
    private var sections: [String] {
        switch self.diffMode {
        case .full: return self.diff.fullDiffSections
        case .diff: return self.diff.smallDiffSections
        case .intersect: return self.diff.intersectSections
        case .overlap: return self.diff.overlapSections
        }
    }
    
    private var rows: [[CardDiff]] {
        switch self.diffMode {
        case .full: return self.diff.fullDiffRows
        case .diff: return self.diff.smallDiffRows
        case .intersect: return self.diff.intersectRows
        case .overlap: return self.diff.overlapRows
        }
    }
    
    // MARK: - table view
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section]
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rows[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "diffCell", for: indexPath) as! DeckDiffCell
        let cd = self.rows[indexPath.section][indexPath.row]
        
        cell.vc = self
        cell.tableView = tableView
        cell.card1 = nil
        cell.card2 = nil
        
        cell.deck1Card.textColor = .black
        cell.deck2Card.textColor = .black
        
        if cd.count1 > 0 {
            cell.deck1Card.text = String(format: "%lu× %@", cd.count1, cd.card.name)
            cell.card1 = cd.card
            if cd.count1 > cd.card.owned {
                cell.deck1Card.textColor = .red
            }
        } else {
            cell.deck1Card.text = ""
        }
        
        if cd.count2 > 0 {
            cell.deck2Card.text = String(format: "%lu× %@", cd.count2, cd.card.name)
            cell.card2 = cd.card
            if cd.count2 > cd.card.owned {
                cell.deck2Card.textColor = .red
            }
        } else {
            cell.deck2Card.text = ""
        }
        
        switch self.diffMode {
        case .intersect:
            let diff = cd.count1 + cd.count2 - cd.card.owned
            cell.diff.text = "\(diff)"
            cell.diff.textColor = .black
        case .overlap:
            let diff = min(cd.count1, cd.count2)
            cell.diff.text = "\(diff)"
            cell.diff.textColor = .black
        case .full, .diff:
            let diff = cd.count2 - cd.count1
            if diff != 0 {
                cell.diff.text = String(format: "%+ld", diff)
                cell.diff.textColor = UIColor(rgb: diff > 0 ? 0x177a00 : 0xdb0c0c)
            } else {
                cell.diff.text = ""
            }
        }
        
        return cell
    }

}
