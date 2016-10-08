//
//  CardUpdateCheck.swift
//  NetDeck
//
//  Created by Gereon Steffens on 06.03.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

class CardUpdateCheck: NSObject {
    
    class func checkCardUpdateAvailable(_ vc: UIViewController) -> Bool {
        let next = UserDefaults.standard.string(forKey: SettingsKeys.NEXT_DOWNLOAD)
        
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .none
        
        guard let scheduled = fmt.date(from: next ?? "") else {
            return false
        }

        let now = Date()
        
        if Reachability.online && scheduled.timeIntervalSince1970 < now.timeIntervalSince1970 {
            let msg = "Card data may be out of date. Download now?".localized()
            let alert = UIAlertController.alert(withTitle: "Update cards".localized(), message:msg)
            
            alert.addAction(UIAlertAction(title: "Later".localized()) { (action) -> Void in
                // ask again tomorrow
                let next = Date(timeIntervalSinceNow:24*60*60)
                
                UserDefaults.standard.set(fmt.string(from: next), forKey:SettingsKeys.NEXT_DOWNLOAD)
            })
            
            alert.addAction(UIAlertAction(title:"OK".localized(), style:.cancel) { (action) -> Void in
                DataDownload.downloadCardData()
            })
            
            vc.present(alert, animated:false, completion:nil)
            return true
        }
        
        return false
    }
    
}
