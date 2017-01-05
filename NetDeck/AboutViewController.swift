//
//  AboutViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 05.01.17.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit
import MessageUI

class AboutViewController: UIViewController, UIWebViewDelegate, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    
    private var backButton: UIBarButtonItem!
    private var mailer: MFMailComposeViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.backButton = UIBarButtonItem(title: "◁", style: .plain, target: self, action: #selector(self.goBack(_:)))
        
        self.webView.delegate = self
        self.webView.dataDetectorTypes = []
        
        if let path = Bundle.main.path(forResource: "About", ofType: "html") {
            let url = URL(fileURLWithPath: path)
            self.webView.loadRequest(URLRequest(url: url))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let fmt = Device.isIphone ? "Net Deck %@" : "About Net Deck %@"
        let title = String(format: fmt.localized(), AppDelegate.appVersion())
        
        self.title = title
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let topItem = self.navigationController?.navigationBar.topItem
        topItem?.rightBarButtonItem = UIBarButtonItem(title: "Feedback".localized(), style: .plain, target: self, action: #selector(self.leaveFeedback(_:)))
    }
    
    func goBack(_ sender: Any) {
        self.webView.goBack()
        self.navigationController?.navigationBar.topItem?.leftBarButtonItem = nil
    }
    
    func leaveFeedback(_ sender: Any) {
        let msg = "We'd love to know how we can make Net Deck even better - and would really appreciate if you left a review on the App Store.".localized()
        
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Write a Review".localized()) { action in
            self.rateApp()
        })
        alert.addAction(UIAlertAction(title: "Contact Developers".localized()) { action in
            self.sendEmail()
        })
        alert.addAction(UIAlertAction.alertCancel(nil))
        
        self.present(alert, animated: false, completion: nil)
        
    }
    
    func rateApp() {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id865963530") {
            UIApplication.shared.openURL(url)
        }
    }
    
    func sendEmail() {
        guard MFMailComposeViewController.canSendMail() else {
            return
        }
        self.mailer = MFMailComposeViewController()
        if self.mailer != nil {
            self.mailer.mailComposeDelegate = self
            self.mailer.setToRecipients([ "netdeck@steffens.org" ])
            let subject = "Net Deck Feedback ".localized() + AppDelegate.appVersion()
            self.mailer.setSubject(subject)
            self.present(self.mailer, animated: false, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.mailer.dismiss(animated: false, completion: nil)
        self.mailer = nil
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        if navigationType == .linkClicked {
            let scheme = request.url?.scheme ?? ""
            
            switch scheme {
            case "mailto":
                self.sendEmail()
            case "itms-apps":
                self.rateApp()
            case "file":
                if let path = Bundle.main.path(forResource: "Acknowledgements", ofType: "html") {
                    let url = URL(fileURLWithPath: path)
                    self.webView.loadRequest(URLRequest(url: url))
                    self.navigationController?.navigationBar.topItem?.leftBarButtonItem = self.backButton
                    return true
                }
            default:
                if let url = request.url {
                    UIApplication.shared.openURL(url)
                }
            }
            return false
        }
        return true
    }
}
