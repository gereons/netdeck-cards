//
//  TipJarViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 01.09.17.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import UIKit
import StoreKit
import SVProgressHUD

enum Tip: String {
    case generous = "org.steffens.NRDB.tip.1"
    case massive = "org.steffens.NRDB.tip.2"
    case amazing = "org.steffens.NRDB.tip.3"
    
    static let prefix = "org.steffens.NRDB.tip."
    static let values = [ Tip.generous, .massive, .amazing ]
}

@objc(TipJarViewController) // need for IASK
class TipJarViewController: UIViewController {

    fileprivate var selectedTip = ""
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var topMargin: NSLayoutConstraint!
    @IBOutlet weak var tip1Button: UIButton!
    @IBOutlet weak var tip2Button: UIButton!
    @IBOutlet weak var tip3Button: UIButton!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    fileprivate var tipMap = [Tip: UIButton]()
    fileprivate var productsMap = [Tip: SKProduct]()
    
    private var productsRequest: SKProductsRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Tip Jar".localized()
        
        self.titleLabel.text = "If you find Net Deck useful, please consider supporting its development by leaving a tip in our tip jar.\n\nYour support is greatly appreciated!".localized()
        
        self.tipMap = [
            .generous: tip1Button,
            .massive: tip2Button,
            .amazing: tip3Button
        ]

        self.tipMap.values.forEach {
            $0.setTitle("", for: .normal)
            $0.isHidden = true
        }
        
        if self.canMakePurchases() {
            self.fetchAvailableProducts()
        }
        
        if Device.isIphone {
            self.topMargin.constant = 20
        }

        Analytics.logEvent(.showTipJar)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.productsRequest?.cancel()
    }
    
    @IBAction func tipButtonTapped(_ sender: UIButton) {
        guard
            self.canMakePurchases(),
            let tip = Tip(rawValue: Tip.prefix + "\(sender.tag)"),
            let product = self.productsMap[tip]
        else {
            return
        }
        
        let defaultQueue = SKPaymentQueue.default()
        // add self as the observer
        defaultQueue.add(self)

        let payment = SKPayment(product: product)
        defaultQueue.add(payment)
        
        SVProgressHUD.show(withStatus: "Tipping...".localized())
        Analytics.logEvent(.selectTip, attributes: [ "Tip": tip.rawValue ])
    }

    private func fetchAvailableProducts() {
        let products = Tip.values.map { $0.rawValue }
        self.productsRequest = SKProductsRequest(productIdentifiers: Set(products))
        self.productsRequest?.delegate = self
        self.productsRequest?.start()
    }
    
}

extension TipJarViewController: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.spinner.stopAnimating()
        if response.products.count > 0 {
            response.products.forEach { product in
                // print("found \(product.productIdentifier) \(product.price) \(product.priceLocale)")
                print("\(product.localizedTitle)")
                
                let fmt = NumberFormatter()
                fmt.numberStyle = .currency
                fmt.locale = product.priceLocale
                if
                    let tip = Tip(rawValue: product.productIdentifier),
                    let price = fmt.string(from: product.price),
                    let button = self.tipMap[tip] {
                    let title = product.localizedTitle + ": " + price
                    button.setTitle(title, for: .normal)
                    button.isHidden = false
                    
                    self.productsMap[tip] = product
                }
            }
         } else {
            self.titleLabel.text! += "\n\n" + "Can't get data from the App Store".localized()
        }
    }

    func canMakePurchases() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }

}

extension TipJarViewController: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        SVProgressHUD.dismiss()
        
        for transaction in transactions {
            let id = transaction.payment.productIdentifier
            let state: String
            switch transaction.transactionState {
            case .purchased:
                print("Purchased \(id)")
                state = "purchased"
                SVProgressHUD.showSuccess(withStatus: "Thank you!".localized())
                SKPaymentQueue.default().finishTransaction(transaction)
                if let tip = Tip(rawValue: id), let product = self.productsMap[tip] {
                    Analytics.logPurchase(of: product)
                }
            case .purchasing:
                state = "purchasing"
                print("Purchasing \(id)")
                
            case .restored:
                state = "restored"
                print("restored \(id)")
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .deferred:
                state = "deferred"
                print("deferred \(id)")
                
            case .failed:
                state = "failed"
                print("Failed: \(id) \(String(describing: transaction.error))")
                
            }
            Analytics.logEvent(.tipTransaction, attributes: [ "Tip": id, "State": state])
        }

    }
}

