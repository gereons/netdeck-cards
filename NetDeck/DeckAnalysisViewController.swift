//
//  DeckAnalysisViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 28.12.16.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import UIKit

class DeckAnalysisViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var okButton: UIButton!

    private var deck: Deck
    private var errors = [String]()
    private var showSets = false
    private var sets = [String]()
    private var costStats: CostStats!
    private var strengthStats: StrengthStats!
    private var cardTypeStats: CardTypeStats!
    private var iceTypeStats: IceTypeStats!
    private var influenceStats: InfluenceStats!
    private var toggleButton: UIButton!
    
    static func showForDeck(_ deck: Deck, inViewController viewController: UIViewController) {
        let analysis = DeckAnalysisViewController(deck: deck)
        viewController.present(analysis, animated: false, completion: nil)
    }
    
    required init(deck: Deck) {
        self.deck = deck
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .formSheet
        
        self.errors = deck.checkValidity()
        // self.sets = PackManager.packsUsedIn(cards: deck.allCards)
        self.sets = deck.packsUsed()
        
        self.costStats = CostStats(deck: deck)
        self.strengthStats = StrengthStats(deck: deck)
        self.cardTypeStats = CardTypeStats(deck: deck)
        self.influenceStats = InfluenceStats(deck: deck)
        self.iceTypeStats = IceTypeStats(deck: deck)
        
        self.toggleButton = UIButton(type: .system)
        self.toggleButton.frame = CGRect(x: 0, y: 0, width: 50, height: 30)
        self.toggleButton.setImage(UIImage(named: "764-arrow-down"), for: .normal)
        self.toggleButton.addTarget(self, action: #selector(self.toggleSets(_:)), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = "Deck Analysis".localized()
        self.okButton.setTitle("Done".localized(), for: .normal)
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    @IBAction func done(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    // MARK: - table view
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return 44
        case 1: return self.costStats.height
        case 2: return self.strengthStats.height
        case 3: return self.cardTypeStats.height
        case 4: return self.influenceStats.height
        case 5: return self.iceTypeStats.height
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return max(2, self.errors.count + 1) + (self.showSets ? self.sets.count : 0)
        default: return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Deck Validity".localized()
        case 1: return self.costStats.height > 0 ? "Cost Distribution".localized() : nil
        case 2: return self.strengthStats.height > 0 ? "Strength Distribution".localized() : nil
        case 3: return self.cardTypeStats.height > 0 ? "Card Type Distribution".localized() : nil
        case 4: return self.influenceStats.height > 0 ? "Influence Distribution".localized() : nil
        case 5: return self.iceTypeStats.height > 0 ? "ICE Type Distribution".localized() : nil
        default: return nil
        }
    }
    
    @objc func toggleSets(_ sender: Any) {
        self.showSets = !self.showSets
        let arrow = self.showSets ? "763-arrow-up" : "764-arrow-down"
        self.toggleButton.setImage(UIImage(named: arrow), for: .normal)
        
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        guard indexPath.section == 0 else {
            return 0
        }
        
        if self.errors.count > 0 {
            if indexPath.row > self.errors.count {
                return 1
            }
        } else if indexPath.row > 1 {
            return 1
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {        
        let cell = tableView.cellForRow(at: indexPath)
        if cell?.accessoryView != nil {
            return indexPath
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: false)
        self.toggleSets(self)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "analysisCell\(indexPath.section)"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ??
            UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        
        cell.accessoryView = nil
        cell.textLabel?.textColor = .black
        
        switch indexPath.section {
        case 0:
            if self.errors.count > 0 {
                if indexPath.row < self.errors.count {
                    cell.textLabel?.text = self.errors[indexPath.row]
                    cell.textLabel?.textColor = .red
                } else if indexPath.row == self.errors.count {
                    cell.textLabel?.text = String(format: "Cards up to %@".localized(), deck.mostRecentPackUsed())
                    cell.accessoryView = self.toggleButton
                } else if indexPath.row > self.errors.count {
                    cell.textLabel?.text = self.sets[indexPath.row - self.errors.count - 1]
                }
            } else {
                switch indexPath.row {
                case 0:
                    cell.textLabel?.text = "Deck is valid".localized()
                case 1:
                    cell.textLabel?.text = String(format: "Cards up to %@".localized(), deck.mostRecentPackUsed())
                    cell.accessoryView = self.toggleButton
                default:
                    cell.textLabel?.text = self.sets[indexPath.row - 2]
                }
            }
        case 1: cell.contentView.addSubview(self.costStats.hostingView)
        case 2: cell.contentView.addSubview(self.strengthStats.hostingView)
        case 3: cell.contentView.addSubview(self.cardTypeStats.hostingView)
        case 4: cell.contentView.addSubview(self.influenceStats.hostingView)
        case 5: cell.contentView.addSubview(self.iceTypeStats.hostingView)
        default: break
        }
        
        return cell
    }

}
