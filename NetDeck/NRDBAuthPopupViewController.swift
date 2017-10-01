//
//  NRDBAuthPopupViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 28.10.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

class NRDBAuthPopupViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var cancelButton: UIButton?  // only on iPad
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    static var popup: NRDBAuthPopupViewController?
    private var navController: UINavigationController?
    
    static func show(in viewController: UIViewController) {
        assert(Device.isIpad, "iPad only!")
        
        let popup = NRDBAuthPopupViewController()
        viewController.present(popup, animated: false, completion: nil)
        popup.preferredContentSize = CGSize(width: 850, height: 466)
        
        NRDBAuthPopupViewController.popup = popup
    }
    
    static func push(on navController: UINavigationController) {
        assert(Device.isIphone, "iPhone only!")
    
        let popup = NRDBAuthPopupViewController()
        popup.navController = navController
        navController.pushViewController(popup, animated: true)
        
        NRDBAuthPopupViewController.popup = popup
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
        if Device.isIpad {
            self.modalPresentationStyle = .formSheet
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView.delegate = self
        self.webView.dataDetectorTypes = []
        
        let url = URL(string: NRDB.authUrl)
        self.webView.loadRequest(URLRequest(url: url!))
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        self.cancelButton?.setTitle("Cancel".localized(), for: .normal)
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        NRDB.clearSettings()
        self.dismiss()
    }
    
    func dismiss() {
        if let nav = self.navController {
            assert(Device.isIphone, "not on iPhone!")
            nav.popViewController(animated: true)
            self.navController = nil
        } else {
            assert(Device.isIpad, "not on iPad!")
            self.dismiss(animated: false, completion: nil)
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        NRDBAuthPopupViewController.popup = nil
    }
    
    // MARK - url handler
    
    static func handleOpenUrl(_ url: URL) {
        // print("NRDB handleOpenUrl")
        guard let popup = NRDBAuthPopupViewController.popup,
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = urlComponents.queryItems else {
            return
        }
        
        if let item = queryItems.filter( { $0.name == "code" } ).first {
            let code = item.value ?? ""
            // print("found code \(code)")
            NRDB.sharedInstance.authorizeWithCode(code) { _ in
                popup.dismiss()
                NRDB.sharedInstance.startAuthorizationRefresh()
            }
        } else {
            NRDB.clearSettings()
            popup.dismiss()
        }
    }
    
    // MARK - webview
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        self.activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        self.webView.endEditing(true)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.activityIndicator.startAnimating()
        
        return true
    }

}
