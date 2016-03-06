//
//  CardUpdateCheck.swift
//  NetDeck
//
//  Created by Gereon Steffens on 06.03.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

class CardUpdateCheck: NSObject {
    class func checkCardsAvailable(vc: UIViewController) {

        // check if card data is available at all, and if so, if it maybe needs an update
        if !CardManager.cardsAvailable() || !CardSets.setsAvailable() {
            let msg = "To use this app, you must first download card data.".localized()
            let alert = UIAlertController.alertWithTitle("No Card Data".localized(), message:msg)
            
            alert.addAction(UIAlertAction(title:"Not now".localized(), style:.Default, handler:nil))
            alert.addAction(UIAlertAction(title:"Download".localized(), style:.Cancel) { (action) -> Void in
                DataDownload.downloadCardData()
            })
    
            vc.presentViewController(alert, animated:false, completion:nil)
        } else {
            CardUpdateCheck.checkCardUpdate(vc)
        }
    }

    private class func checkCardUpdate(vc: UIViewController) {
        let next = NSUserDefaults.standardUserDefaults().stringForKey(SettingsKeys.NEXT_DOWNLOAD)
        
        let fmt = NSDateFormatter()
        fmt.dateStyle = .ShortStyle
        fmt.timeStyle = .NoStyle
        
        guard let scheduled = fmt.dateFromString(next ?? "") else {
            return
        }

        let now = NSDate()
        
        if AppDelegate.online() && scheduled.timeIntervalSince1970 < now.timeIntervalSince1970 {
            let msg = "Card data may be out of date. Download now?".localized()
            let alert = UIAlertController.alertWithTitle("Update cards".localized(), message:msg)
            
            alert.addAction(UIAlertAction(title: "Later".localized()) { (action) -> Void in
                // ask again tomorrow
                let next = NSDate(timeIntervalSinceNow:24*60*60)
                
                NSUserDefaults.standardUserDefaults().setObject(fmt.stringFromDate(next), forKey:SettingsKeys.NEXT_DOWNLOAD)
            })
            
            alert.addAction(UIAlertAction(title:"OK".localized(), style:.Cancel) { (action) -> Void in
                DataDownload.downloadCardData()
            })
            
            vc.presentViewController(alert, animated:false, completion:nil)
        }
    }
}
