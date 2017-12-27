//
//  IphoneIdentityViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 31.10.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class IphoneIdentityViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var okButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!

    @IBOutlet weak var toolbar: UIToolbar!
    
    var role = Role.none
    var deck: Deck?
    
    fileprivate var selectedIdentity: Card?
    fileprivate var selectedIndexPath: IndexPath?
    fileprivate var identities = [[Card]]()
    fileprivate var factionNames = [String]()
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor(patternImage: ImageCache.hexTile)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = .clear
        
        let tableTap = UITapGestureRecognizer(target: self, action: #selector(self.doubleTap(_:)))
        tableTap.numberOfTapsRequired = 2
        self.tableView.addGestureRecognizer(tableTap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress(_:)))
        self.tableView.addGestureRecognizer(longPress)
        
        self.title = "Choose Identity".localized()
        
        self.cancelButton.title = "Cancel".localized()
        if self.deck == nil {
            if var barButtons = self.toolbar.items, let index = barButtons.index(where: { $0 == self.cancelButton }) {
                barButtons.remove(at: index)
                self.toolbar.items = barButtons
            }
        }
        
        self.selectedIdentity = self.deck?.identity

        let packUsage = Defaults[.deckbuilderPacks]
        let identities = CardManager.identitiesForSelection(self.role, packUsage: packUsage)
        self.factionNames = identities.sections 
        self.identities = identities.values
        
        self.selectedIndexPath = nil
        for i in 0 ..< self.identities.count {
            for j in 0 ..< self.identities[i].count {
                let card = self.identities[i][j]
                if self.selectedIdentity?.code == card.code {
                    self.selectedIndexPath = IndexPath(row: j, section: i)
                    break
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.okButton.isEnabled = self.deck != nil && self.deck?.identity != nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let selected = self.selectedIndexPath {
            self.tableView.selectRow(at: selected, animated: false, scrollPosition: .middle)
        }
    }

    @IBAction func okTapped(_ sender: UIBarButtonItem) {
        self.closeAndSetIdentity()
    }
    
    func closeAndSetIdentity() {
        guard let identity = self.selectedIdentity else { return }
        if let deck = self.deck {
            deck.addCard(identity, copies: 1)
            self.close()
        } else {
            let deck = Deck(role: self.role)
            deck.addCard(identity, copies: 1)
            
            let edit = EditDeckViewController()
            edit.deck = deck
            
            if var controllers = self.navigationController?.viewControllers {
                controllers.removeLast()
                controllers.append(edit)
                self.navigationController?.setViewControllers(controllers, animated: false)
            }
        }
    }
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        assert(self.deck != nil, "no deck")
        self.close()
    }
    
    func close() {
        let _ = self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - tableview delegate & datasource

extension IphoneIdentityViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.factionNames.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.identities[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.factionNames[section]
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
        cell.backgroundColor = .white
        if indexPath == self.selectedIndexPath {
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
            cell.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        }
    }
 
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = self.identities[indexPath.section][indexPath.row]
        self.selectedIdentity = card
        
        var reload = [indexPath]
        if let prev = self.selectedIndexPath {
            reload.append(prev)
        }
        self.selectedIndexPath = indexPath
        tableView.reloadRows(at: reload, with: .none)
        
        self.okButton.isEnabled = true
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "idCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? {
            let c = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
            c.selectionStyle = .none
            return c
        }()
        
        let card = self.identities[indexPath.section][indexPath.row]
        cell.textLabel?.text = card.name
        cell.textLabel?.textColor = card.factionColor
        
        let influence = card.influenceLimit == -1 ? "∞" : "\(card.influenceLimit)"
        if self.role == .runner {
            cell.detailTextLabel?.text = "\(card.minimumDecksize)/\(influence) · \(card.baseLink) Link"
        } else {
            cell.detailTextLabel?.text = "\(card.minimumDecksize)/\(influence)"
        }
        return cell
    }
    
}

// MARK: - gesture recognizers

extension IphoneIdentityViewController {
    
    @objc func doubleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        let point = gesture.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: point)
        if indexPath == nil || self.selectedIdentity == nil {
            return
        }
        
        self.closeAndSetIdentity()
    }
    
    @objc func longPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let point = gesture.location(in: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: point) {
            let card = self.identities[indexPath.section][indexPath.row]
            
            let imageView = ModalCardImageViewController()
            let presenter = ModalViewPresenter(with: imageView)
            
            imageView.modalPresenter = presenter
            imageView.card = card
            presenter.present(on: self)
        }

    }
}