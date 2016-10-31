//
//  DeckEmail.swift
//  NetDeck
//
//  Created by Gereon Steffens on 15.02.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import UIKit
import MessageUI

class DeckEmail: NSObject, MFMailComposeViewControllerDelegate {
    private var viewController: UIViewController!
    private static let instance = DeckEmail()
    
    class func canSendMail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
    
    class func emailDeck(_ deck: Deck, fromViewController: UIViewController) {
        instance.sendAsEmail(deck, fromViewController: fromViewController)
    }
    
    func sendAsEmail(_ deck: Deck, fromViewController: UIViewController) {
        guard DeckEmail.canSendMail() else { return }
        let mailer = MFMailComposeViewController()
        
        mailer.mailComposeDelegate = self
        let emailBody = DeckExport.asPlaintextString(deck)
        mailer.setMessageBody(emailBody, isHTML:false)
    
        mailer.setSubject(deck.name)
        self.viewController = fromViewController
        self.viewController.present(mailer, animated:false, completion:nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.viewController.dismiss(animated: false, completion: nil)
        self.viewController = nil
    }
}
