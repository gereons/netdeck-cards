//
//  SavedDecksList.swift
//  NetDeck
//
//  Created by Gereon Steffens on 08.01.17.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit
import SVProgressHUD
import MessageUI

class SavedDecksList: DecksViewController {
    
    private var editButton: UIBarButtonItem!
    private var importButton: UIBarButtonItem!
    private var exportButton: UIBarButtonItem!
    private var addDeckButton: UIBarButtonItem!
    private var diffCancelButton: UIBarButtonItem!
    private var normalRightButtons = [UIBarButtonItem]()
    private var diffRightButtons = [UIBarButtonItem]()
    private var diffSelection = false
    private var diffDeck: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.diffSelection = false
        
        self.editButton = UIBarButtonItem(title: "Edit".localized(), style: .plain, target: self, action: #selector(self.toggleEdit(_:)))
        self.editButton.possibleTitles = Set<String>(["Edit".localized(), "Done".localized()])
        
        self.diffCancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.diffCancel(_:)))
        self.diffRightButtons = [ self.diffCancelButton ]
        
        self.addDeckButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.newDeck(_:)))

        self.importButton = UIBarButtonItem(image: UIImage(named: "702-import"), style: .plain, target: self, action: #selector(self.importDecks(_:)))
        self.exportButton = UIBarButtonItem(image: UIImage(named: "702-share"), style: .plain, target: self, action: #selector(self.exportDecks(_:)))
        
        let topItem = self.navigationController?.navigationBar.topItem
        self.normalRightButtons = [ self.addDeckButton, self.exportButton, self.importButton, self.editButton ]
        topItem?.rightBarButtonItems = self.normalRightButtons
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress(_:)))
        self.tableView.addGestureRecognizer(longPress)
        
        self.toolBarHeight.constant = 0
    }
    
    // WTF is this necessary? if we don't do this, the import/export/add buttons will appear inactive after we return here from
    // the import view
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let topItem = self.navigationController?.navigationBar.topItem
        topItem?.rightBarButtonItems = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let topItem = self.navigationController?.navigationBar.topItem
        topItem?.rightBarButtonItems = self.normalRightButtons
    }
    
    func importDecks(_ sender: UIBarButtonItem) {
        if self.popup != nil {
            return self.dismissPopup()
        }
        
        let settings = UserDefaults.standard
        let useDropbox = settings.bool(forKey: SettingsKeys.USE_DROPBOX)
        let useNetrunnerDb = settings.bool(forKey: SettingsKeys.USE_NRDB)
        
        if !useDropbox && !useNetrunnerDb {
            UIAlertController.alert(withTitle: "Import Decks".localized(), message: "Connect to your Dropbox and/or NetrunnerDB.com account first.".localized()
                , button: "OK".localized())
            return
        }
        
        if useDropbox && useNetrunnerDb {
            self.popup = UIAlertController.actionSheet(title: "Import Decks".localized(), message: nil)
            self.popup.addAction(UIAlertAction.action(title: "Import from Dropbox".localized()) { action in
                self.importFrom(.dropbox)
            })
            self.popup.addAction(UIAlertAction.action(title: "Import from NetrunnerDB.com".localized()) { action in
                self.importFrom(.netrunnerDb)
            })
            self.popup.addAction(UIAlertAction.actionSheetCancel{ action in
                self.popup = nil
            })
            
            let popover = self.popup.popoverPresentationController
            popover?.barButtonItem = sender
            popover?.sourceView = self.view
            popover?.permittedArrowDirections = .any
            self.popup.view.layoutIfNeeded()
            
            self.present(self.popup, animated: false, completion: nil)
        } else {
            self.importFrom(useDropbox ? .dropbox : .netrunnerDb)
        }
    }
    
    func importFrom(_ source: ImportSource) {
        let importDecks = ImportDecksViewController()
        importDecks.source = source
        self.navigationController?.pushViewController(importDecks, animated: false)
        self.popup = nil
    }
    
    func exportDecks(_ sender: UIBarButtonItem) {
        if self.popup != nil {
            return self.dismissPopup()
        }
        
        let settings = UserDefaults.standard
        let useDropbox = settings.bool(forKey: SettingsKeys.USE_DROPBOX)
        let useNetrunnerDb = settings.bool(forKey: SettingsKeys.USE_NRDB)
        
        if !useDropbox && !useNetrunnerDb {
            UIAlertController.alert(withTitle: "Export Decks".localized(), message: "Connect to your Dropbox and/or NetrunnerDB.com account first.".localized()
                , button: "OK".localized())
            return
        }
        
        self.popup = UIAlertController.actionSheet(title: "Export Decks".localized(), message: "Export all currently visible decks".localized())
        
        if useDropbox {
            self.popup.addAction(UIAlertAction.action(title: "To Dropbox".localized()) { action in
                SVProgressHUD.show(withStatus: "Exporting Decks...".localized())
                self.popup = nil
                self.perform(#selector(self.exportAllToDropbox), with: nil, afterDelay: 0.0)

            })
        }
        if useNetrunnerDb {
            self.popup.addAction(UIAlertAction.action(title: "To NetrunnerDB.com".localized()) { action in
                SVProgressHUD.show(withStatus: "Exporting Decks...".localized())
                self.popup = nil
                self.perform(#selector(self.exportAllToNetrunnerDB), with: nil, afterDelay: 0.0)
            })
        }
        
        self.popup.addAction(UIAlertAction.actionSheetCancel{ action in
            self.popup = nil
        })
        
        let popover = self.popup.popoverPresentationController
        popover?.barButtonItem = sender
        popover?.sourceView = self.view
        popover?.permittedArrowDirections = .any
        self.popup.view.layoutIfNeeded()
        
        self.present(self.popup, animated: false, completion: nil)
    }
    
    func exportAllToDropbox() {
        for arr in self.decks {
            for deck in arr {
                if deck.identity != nil {
                    DeckExport.asOctgn(deck, autoSave: true)
                }
            }
        }
        
        SVProgressHUD.dismiss()
    }
    
    func exportAllToNetrunnerDB() {
        var decks = [Deck]()
        for arr in self.decks {
            for deck in arr {
                decks.append(deck)
            }
        }
        
        self.exportToNetrunnerDB(decks, index: 0)
    }
    
    func exportToNetrunnerDB(_ decks: [Deck], index: Int) {
        if index < decks.count {
            let deck = decks[index]
            NRDB.sharedInstance.saveDeck(deck) { ok, deckId, msg in
                if ok && deckId != nil {
                    deck.netrunnerDbId = deckId
                    deck.saveToDisk()
                }
                self.exportToNetrunnerDB(decks, index: index + 1)
            }
        } else {
            SVProgressHUD.dismiss()
            self.updateDecks()
        }
    }
    
    func statePopup(_ sender: UIButton) {
        let row = sender.tag / 10
        let section = sender.tag & 1
        let indexPath = IndexPath(row: row, section: section)
        
        let deck = self.decks[section][row]
        
        let cell = self.tableView.cellForRow(at: indexPath)
    
        self.popup = UIAlertController.actionSheet(title: "Status".localized(), message: nil)
        self.popup.addAction(UIAlertAction(title: "Active".localized().checked(deck.state == .active)) { action in
            self.changeState(of: deck, to: .active)
        })
        self.popup.addAction(UIAlertAction(title: "Testing".localized().checked(deck.state == .testing)) { action in
            self.changeState(of: deck, to: .testing)
        })
        self.popup.addAction(UIAlertAction(title: "Retired".localized().checked(deck.state == .retired)) { action in
            self.changeState(of: deck, to: .retired)
        })
        self.popup.addAction(UIAlertAction.actionSheetCancel() { action in
            self.popup = nil
        })
        
        let frame = cell?.contentView.convert(sender.frame, to: self.view) ?? CGRect.zero
        
        let popover = self.popup.popoverPresentationController
        popover?.sourceView = self.view
        popover?.sourceRect = frame
        popover?.permittedArrowDirections = [.left, .right]
        self.popup.view.layoutIfNeeded()
        
        self.present(self.popup, animated: false, completion: nil)
    }
    
    func changeState(of deck: Deck, to state: DeckState) {
        if deck.state != state {
            deck.state = state
            deck.updateOnDisk()
            self.updateDecks()
        }
        self.popup = nil
    }
    
    func newDeck(_ sender: Any) {
        if self.popup != nil {
            return self.dismissPopup()
        }

        var role = Role.none
        if self.filterType == .runner {
            role = .runner
        } else if self.filterType == .corp {
            role = .corp
        }
        
        if role != .none {
            NotificationCenter.default.post(name: Notifications.newDeck, object: self, userInfo: [ "role": role.rawValue ])
            return
        }
        
        self.popup = UIAlertController.actionSheet(title: "New Deck".localized(), message: nil)
        self.popup.addAction(UIAlertAction(title: "New Runner Deck".localized()) { action in
            NotificationCenter.default.post(name: Notifications.newDeck, object: self, userInfo: [ "role": Role.runner.rawValue ])
            self.popup = nil
        })
        self.popup.addAction(UIAlertAction(title: "New Corp Deck".localized()) { action in
            NotificationCenter.default.post(name: Notifications.newDeck, object: self, userInfo: [ "role": Role.corp.rawValue ])
            self.popup = nil
        })
        self.popup.addAction(UIAlertAction.actionSheetCancel() { action in
            self.popup = nil
        })
        
        let popover = self.popup.popoverPresentationController
        if let barButton = sender as? UIBarButtonItem {
            popover?.barButtonItem = barButton
            popover?.sourceView = self.view
            popover?.permittedArrowDirections = .any
        } else if let button = sender as? UIButton {
            popover?.sourceRect = button.superview!.convert(button.frame, to: self.tableView)
            popover?.sourceView = self.tableView
            popover?.permittedArrowDirections = .up
        }
        
        self.popup.view.layoutIfNeeded()
        self.present(self.popup, animated: false, completion: nil)
    }
    
    func longPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else {
            return
        }
        
        let point = gesture.location(in: self.tableView)
        guard
            let indexPath = self.tableView.indexPathForRow(at: point),
            let cell = self.tableView.cellForRow(at: indexPath)
        else {
            return
        }
        
        let deck = self.decks[indexPath.section][indexPath.row]
        
        self.popup = UIAlertController.actionSheet(title: nil, message: nil)
        self.popup.addAction(UIAlertAction(title: "Duplicate".localized()) { action in
            let newDeck = deck.duplicate()
            newDeck.saveToDisk()
            
            let settings = UserDefaults.standard
            if settings.bool(forKey: SettingsKeys.USE_DROPBOX) && settings.bool(forKey: SettingsKeys.AUTO_SAVE_DB) {
                if newDeck.identity != nil && newDeck.cards.count > 0 {
                    DeckExport.asOctgn(deck, autoSave: true)
                }
            }
            self.updateDecks()
            self.popup = nil
        })
        
        self.popup.addAction(UIAlertAction(title: "Rename".localized()) { action in
            let searchBarActive = self.searchBar.isFirstResponder
            if searchBarActive {
                self.searchBar.resignFirstResponder()
            }
            
            let nameAlert = UIAlertController.alert(title: "Enter Name".localized(), message: nil)
            nameAlert.addTextField() { textField in
                textField.placeholder = "Deck Name".localized()
                textField.text = deck.name
                textField.autocapitalizationType = .words
                textField.clearButtonMode = .always
                textField.returnKeyType = .done
            }
            nameAlert.addAction(UIAlertAction.alertCancel() { action in
                if searchBarActive {
                    self.searchBar.becomeFirstResponder()
                }
            })
            
            nameAlert.addAction(UIAlertAction(title: "OK".localized()) { action in
                deck.name = nameAlert.textFields?[0].text ?? deck.name
                deck.saveToDisk()
                self.updateDecks()
                
                if searchBarActive {
                    self.searchBar.becomeFirstResponder()
                }
            })
            
            nameAlert.show()
            self.popup = nil
        })
        
        if MFMailComposeViewController.canSendMail() {
            self.popup.addAction(UIAlertAction(title: "Send via Email".localized()) { action in
                DeckEmail.emailDeck(deck, fromViewController: self)
                self.popup = nil
            })
        }
        
        self.popup.addAction(UIAlertAction(title: "Compare to ...".localized()) { action in
            self.diffDeck = deck.filename
            self.diffSelection = true
            
            self.navigationController?.navigationBar.topItem?.rightBarButtonItems = self.diffRightButtons
            self.tableView.reloadData()
            self.popup = nil
        })
        
        self.popup.addAction(UIAlertAction.actionSheetCancel() { action in
            self.popup = nil
        })
        
        let popover = self.popup.popoverPresentationController
        popover?.sourceRect = cell.frame
        popover?.sourceView = self.tableView
        popover?.permittedArrowDirections = self.searchBar.isFirstResponder ? .any : [.up, .down]
        self.popup.view.layoutIfNeeded()
        self.present(self.popup, animated: false, completion: nil)
    }
    
    // MARK: - edit toggle
    func toggleEdit(_ sender: UIButton) {
        if self.popup != nil {
            return self.dismissPopup()
        }
        
        let editing = !self.tableView.isEditing
        self.editButton.title = editing ? "Done".localized() : "Edit".localized()
        self.tableView.isEditing = editing
        
        self.sortButton.isEnabled = !editing
        self.sideFilterButton.isEnabled = !editing
        self.stateFilterButton.isEnabled = !editing
        self.importButton.isEnabled = !editing
        self.exportButton.isEnabled = !editing
        self.addDeckButton.isEnabled = !editing
    }
    
    // MARK: deck diff
    func diffCancel(_ sender: UIButton) {
        assert(self.diffSelection, "not in diff mode")
        self.diffSelection = false
        self.diffDeck = nil
        self.tableView.reloadData()
        
        self.navigationController?.navigationBar.topItem?.rightBarButtonItems = self.normalRightButtons
    }
    
    // MARK: - table view
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath) as! DeckCell
        
        cell.infoButton?.isHidden = false
        cell.infoButton?.tag = indexPath.row * 10 + indexPath.section
        cell.infoButton?.addTarget(self, action: #selector(self.statePopup(_:)), for: .touchUpInside)
        
        let deck = self.decks[indexPath.section][indexPath.row] 
        
        let icon: String
        switch deck.state {
        case .active: icon = "active"
        case .retired: icon = "retired"
        case .testing, .none: icon = "testing"
        }
        let img = UIImage(named: icon)?.withRenderingMode(.alwaysTemplate)
        cell.infoButton?.setImage(img, for: .normal)
        
        cell.nameLabel.textColor = .black
        if self.diffDeck == deck.filename {
            cell.nameLabel.textColor = .blue
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let deck = self.decks[indexPath.section][indexPath.row]
        
        if self.diffSelection {
            assert(self.diffDeck != nil, "no diff deck")
            let d = DeckManager.loadDeckFromPath(self.diffDeck!)
            if d!.role != deck.role {
                UIAlertController.alert(withTitle: "Both decks must be for the same side.".localized(), button: "OK".localized())
                return
            }
            
            DeckDiffViewController.showForDecks(d!, deck2: deck, inViewController: self)
        } else {
            let userInfo: [String: Any] = [ "filename": deck.filename!, "role": deck.role.rawValue ]
            NotificationCenter.default.post(name: Notifications.loadDeck, object: self, userInfo: userInfo)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let deck = self.decks[indexPath.section][indexPath.row]
            
            self.decks[indexPath.section].remove(at: indexPath.row)
            
            NRDB.sharedInstance.deleteDeck(deck.netrunnerDbId)
            if let filename = deck.filename {
                DeckManager.removeFile(filename)
            }
            
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [indexPath], with: .left)
            self.tableView.endUpdates()
            
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    // MARK: - empty set
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        if self.filterText.length > 0 {
            return nil
        }
        
        let color = self.tableView.tintColor ?? .blue
        let attrs: [String: Any] = [ NSFontAttributeName: UIFont.systemFont(ofSize: 17), NSForegroundColorAttributeName: color ]
        return NSAttributedString(string: "New Deck".localized(), attributes: attrs)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        self.newDeck(button)
    }
    
}
