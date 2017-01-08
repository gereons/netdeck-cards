//
//  SavedDecksList.swift
//  NetDeck
//
//  Created by Gereon Steffens on 08.01.17.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit
import SVProgressHUD

class SavedDecksList: DecksViewController {
    
    private var editButton: UIBarButtonItem!
    private var importButton: UIBarButtonItem!
    private var exportButton: UIBarButtonItem!
    private var addDeckButton: UIBarButtonItem!
    private var diffCancelButton: UIBarButtonItem!
    private var normalRightButtons = [UIBarButtonItem]()
    private var difffRightButtons = [UIBarButtonItem]()
    private var diffSelection = false
    private var diffDeck = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.diffSelection = false
        
        self.editButton = UIBarButtonItem(title: "Edit".localized(), style: .plain, target: self, action: #selector(self.toggleEdit(_:)))
        self.editButton.possibleTitles = Set<String>(["Edit".localized(), "Done".localized()])
        
        self.diffCancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.diffCancel(_:)))
        self.difffRightButtons = [ self.diffCancelButton ]
        
        self.addDeckButton = UIBarButtonItem(barButtonSystemItem: .add, style: .plain, target: self, action: #selector(self.newDeck(_:)))

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
            self.popup.dismiss(animated: false, completion: nil)
            self.popup = nil
            return
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
    
    func importFrom(_ source: NRImportSource) {
        let importDecks = ImportDecksViewController()
        importDecks.source = source
        self.navigationController?.pushViewController(importDecks, animated: false)
        self.popup = nil
    }
    
    func exportDecks(_ sender: UIBarButtonItem) {
        if self.popup != nil {
            self.popup.dismiss(animated: false, completion: nil)
            self.popup = nil
            return
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
                let deck = deck as! Deck
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
                let deck = deck as! Deck
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
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
