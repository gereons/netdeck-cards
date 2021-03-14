//
//  DeckNotesPopup.swift
//  NetDeck
//
//  Created by Gereon Steffens on 01.01.17.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import UIKit

final class DeckNotesPopup: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var textView: UITextView!

    var deck: Deck
    
    static func showFor(deck: Deck, in viewController: UIViewController) {
        let popup = DeckNotesPopup(deck: deck)
        
        viewController.present(popup, animated: false, completion: nil)
        popup.preferredContentSize = CGSize(width: 540, height: 300)
        Analytics.logEvent(.deckNotes)
    }

    required init(deck: Deck) {
        self.deck = deck
        super.init(nibName: nil, bundle: nil)

        self.modalPresentationStyle = .formSheet
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cancelButton.setTitle("Cancel".localized(), for: .normal)
        self.okButton.setTitle("OK".localized(), for: .normal)
        
        self.textView.text = self.deck.notes
        self.titleLabel.text = self.deck.name
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.textView.becomeFirstResponder()
    }
    
    @IBAction func okClicked(_ sender: Any) {
        self.deck.notes = self.textView.text
        
        NotificationCenter.default.post(name: Notifications.notesChanged, object: self)
        self.cancelClicked(sender)
    }
    
    @IBAction func cancelClicked(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
}
