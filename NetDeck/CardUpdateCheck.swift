//
//  CardUpdateCheck.swift
//  NetDeck
//
//  Created by Gereon Steffens on 06.03.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class CardUpdateCheck {
    
    static func checkCardUpdateAvailable(_ vc: UIViewController) -> Bool {
        let next = Defaults[.nextDownload]
        
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .none
        
        guard let scheduled = fmt.date(from: next) else {
            return false
        }

        let now = Date()
        
        if Reachability.online && scheduled.timeIntervalSince1970 < now.timeIntervalSince1970 {
            let msg = "Card data may be out of date. Download now?".localized()
            let alert = UIAlertController.alert(title: "Update cards".localized(), message:msg)
            
            alert.addAction(UIAlertAction(title: "Later".localized()) { action in
                // ask again tomorrow
                let next = Date(timeIntervalSinceNow: 24*60*60)
                
                Defaults[.nextDownload] = fmt.string(from: next)
            })
            
            alert.addAction(UIAlertAction(title:"OK".localized(), style:.cancel) { action in
                DataDownload.downloadCardData()
            })
            
            vc.present(alert, animated:false, completion:nil)
            return true
        }
        
        return false
    }
    
}
