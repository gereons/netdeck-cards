
//
//  DeckDiffViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 28.12.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit

enum DiffMode: Int {
    case full
    case diff
    case intersect
    case overlap
}

struct CardDiff {
    var card: Card
    var count1: Int
    var count2: Int
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
    
    private var fullDiffSections = [String]()
    private var smallDiffSections = [String]()
    private var intersectSections = [String]()
    private var overlapSections = [String]()
    private var fullDiffRows = [[CardDiff]]()
    private var smallDiffRows = [[CardDiff]]()
    private var intersectRows = [[CardDiff]]()
    private var overlapRows = [[CardDiff]]()
    
    class func showForDecks(_ deck1: Deck, deck2: Deck, inViewController: UIViewController) {
        Analytics.logEvent("Compare Decks", attributes: nil)
        let ddvc = DeckDiffViewController(deck1: deck1, deck2: deck2)
        
        inViewController.present(ddvc, animated: false, completion: nil)
        ddvc.preferredContentSize = CGSize(width: 768, height: 728)
    }
    
    init(deck1: Deck, deck2: Deck) {
        self.deck1 = deck1
        self.deck2 = deck2
        self.diffMode = .diff
        super.init(nibName: "DeckDiffViewController", bundle: nil)
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
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.register(UINib(nibName: "DeckDiffCell", bundle: nil), forCellReuseIdentifier: "diffCell")
        self.tableView.rowHeight = 44
        
        self.setup()
    }
    
    func setup() {
        self.calcDiff()
        self.deck1Name.text = self.deck1.name
        self.deck2Name.text = self.deck2.name
    }
    
    func calcDiff() {
        let data1 = self.deck1.dataForTableView(.byType)
        let data2 = self.deck2.dataForTableView(.byType)
        
        let types1 = data1.sections as! [String]
        let cards1 = data1.values as! [[CardCounter]]
        
        let types2 = data2.sections as! [String]
        let cards2 = data2.values as! [[CardCounter]]
        
        let typesInDecks = Set<String>(types1 + types2)
        
        self.fullDiffSections = [String]()
        self.intersectSections = [String]()
        self.overlapSections = [String]()
        
        // all possible types for this role
        var allTypes = CardType.typesFor(role: self.deck1.role)
        allTypes[0] = CardType.name(for: .identity)
        // remove "ICE" / "Program"
        allTypes.removeLast()
        
        // find every type that is not already in allTypes - i.e. the ice subtypes
        var additionalTypes = [String]()
        for t in typesInDecks {
            if !allTypes.contains(t) {
                additionalTypes.append(t)
            }
        }
        
        // sort iceTypes and append to allTypes
        allTypes.append(contentsOf: additionalTypes.sorted())
        
        for t in allTypes {
            if typesInDecks .contains(t) {
                self.fullDiffSections.append(t)
                self.intersectSections.append(t)
                self.overlapSections.append(t)
            }
        }
        
        // create arrays for each section
        self.fullDiffRows = [[CardDiff]]()
        self.intersectRows = [[CardDiff]]()
        self.overlapRows = [[CardDiff]]()
        
        for _ in 0 ..< self.fullDiffSections.count {
            self.fullDiffRows.append([CardDiff]())
            self.intersectRows.append([CardDiff]())
            self.overlapRows.append([CardDiff]())
        }
        
        // for each type, find cards in each deck
        for i in 0 ..< self.fullDiffSections.count {
            let type = self.fullDiffSections[i]
            let idx1 = self.findValues(data: data1, forSection: type)
            let idx2 = self.findValues(data: data2, forSection: type)
            
            var cards = [String: CardDiff]()
            if idx1 != -1 {
                for cc in cards1[idx1] {
                    if cc.isNull {
                        continue
                    }
                    
                    var cd = CardDiff(card: cc.card, count1: cc.count, count2: 0)
                    var count2 = 0
                    if idx2 != -1 {
                        for cc2 in cards2[idx2] {
                            if cc.isNull {
                                continue
                            }
                            if cc2.card.code == cc.card.code {
                                count2 = cc2.count
                                break
                            }
                        }
                    }
                    cd.count2 = count2
                    cards[cd.card.code] = cd
                }
            }
            
            // for each card in deck2 that is not already in `cards´, create a CardDiff object
            if idx2 != -1 {
                for cc in cards2[idx2] {
                    if cc.isNull {
                        continue
                    }
                    
                    let cdx = cards[cc.card.code]
                    if cdx != nil {
                        continue
                    }
                    
                    let cd = CardDiff(card: cc.card, count1: 0, count2: cc.count)
                    cards[cd.card.code] = cd
                }
            }
            
            // sort diffs by card name
            let sortedCards = cards.values.sorted { $0.card.name < $1.card.name }
            self.fullDiffRows[i].append(contentsOf: sortedCards)
            
            // fill intersection and overlap - card is in both decks, and the total count is more than we own (for intersect)
            
            for cd in self.fullDiffRows[i] {
                if cd.count1 > 0 && cd.count2 > 0 {
                    self.overlapRows[i].append(cd)
                    
                    if cd.count1 + cd.count2 > cd.card.owned {
                        self.intersectRows[i].append(cd)
                    }
                }
            }
        }
        
        assert(self.intersectSections.count == self.intersectRows.count, "count mismatch");
        assert(self.overlapSections.count == self.overlapRows.count, "count mismatch");
        
        // remove empty intersecion sections
        for i in (0 ..< self.intersectRows.count).reversed() {
            if self.intersectRows[i].count == 0 {
                self.intersectSections.remove(at: i)
                self.intersectRows.remove(at: i)
            }
        }
        assert(self.intersectSections.count == self.intersectRows.count, "count mismatch");
        
        // remove empty overlap sections
        for i in (0 ..< self.overlapRows.count).reversed() {
            if self.overlapRows[i].count == 0 {
                self.overlapSections.remove(at: i)
                self.overlapRows.remove(at: i)
            }
        }
        assert(self.overlapSections.count == self.overlapRows.count, "count mismatch");
        
        // from the full diff, create the (potentially) smaller diff-only arrays
        self.smallDiffRows = [[CardDiff]]()
        for i in 0 ..< self.fullDiffRows.count {
            var arr = [CardDiff]()
            let diff = self.fullDiffRows[i]
            for j in 0 ..< diff.count {
                let cd = diff[j]
                if cd.count1 != cd.count2 {
                    arr.append(cd)
                }
            }
            self.smallDiffRows.append(arr)
        }
        assert(self.smallDiffRows.count == self.fullDiffRows.count, "count mismatch");
        
        self.smallDiffSections = [String]()
        for i in (0 ..< self.smallDiffRows.count).reversed() {
            let arr = self.smallDiffRows[i]
            if arr.count > 0 {
                let section = self.fullDiffSections[i]
                self.smallDiffSections.insert(section, at: 0)
            } else {
                self.smallDiffRows.remove(at: i)
            }
        }
        
        assert(self.smallDiffRows.count == self.smallDiffSections.count, "count mismatch");
    }
    
    func findValues(data: TableData, forSection type: String) -> Int {
        let sections = data.sections as! [String]
        for i in 0 ..< sections.count {
            if sections[i] == type {
                return i
            }
        }
        return -1
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
    
    // MARK: - table view
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch self.diffMode {
        case .full: return self.fullDiffSections[section]
        case .diff: return self.smallDiffSections[section]
        case .intersect: return self.intersectSections[section]
        case .overlap: return self.overlapSections[section]
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        switch self.diffMode {
        case .full: return self.fullDiffSections.count
        case .diff: return self.smallDiffSections.count
        case .intersect: return self.intersectSections.count
        case .overlap: return self.overlapSections.count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let arr: [Any]
        switch self.diffMode {
        case .full: arr = self.fullDiffRows[section]
        case .diff: arr = self.smallDiffRows[section]
        case .intersect: arr = self.intersectRows[section]
        case .overlap: arr = self.overlapRows[section]
        }
        return arr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "diffCell", for: indexPath) as! DeckDiffCell
        let arr: [CardDiff]
        switch self.diffMode {
        case .full: arr = self.fullDiffRows[indexPath.section]
        case .diff: arr = self.smallDiffRows[indexPath.section]
        case .intersect: arr = self.intersectRows[indexPath.section]
        case .overlap: arr = self.overlapRows[indexPath.section]
        }
        let cd = arr[indexPath.row]
        
        cell.vc = self
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
