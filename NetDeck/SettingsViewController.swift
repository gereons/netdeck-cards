//
//  SettingsViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 09.10.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import InAppSettingsKit
import SVProgressHUD
import SwiftyUserDefaults

class SettingsViewController: IASKAppSettingsViewController, IASKSettingsDelegate {
 
    required init() {
        super.init(style: .grouped)
        
        self.delegate = self
        self.showDoneButton = false
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.settingsChanged(_:)), name: Notification.Name(kIASKAppSettingChanged), object: nil)
        nc.addObserver(self, selector: #selector(self.cardsLoaded(_:)), name: Notifications.loadCards, object: nil)
        
        self.refresh()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refresh() {
        var hiddenKeys = Set<String>()
        
        if !CardManager.cardsAvailable || !PackManager.packsAvailable {
            hiddenKeys = Set([
                "sets_hide_1", "sets_hide_2", "sets_hide_3",
                DefaultsKeys.browserPacks._key, DefaultsKeys.deckbuilderPacks._key
            ])
        }
        if Device.isIphone {
            hiddenKeys.formUnion([ DefaultsKeys.autoHistory._key, DefaultsKeys.createDeckActive._key ])
        }
        if Device.isIpad {
            hiddenKeys.formUnion([ "about_hide_1", "about_hide_2" ])
        }
        
        if BuildConfig.release {
            hiddenKeys.formUnion([
                DefaultsKeys.nrdbTokenExpiry._key, DefaultsKeys.lastBackgroundFetch._key, DefaultsKeys.lastRefresh._key,
                IASKButtons.refreshAuthNow
            ])
        }

        if !Defaults[.useDropbox] {
            hiddenKeys.insert(DefaultsKeys.autoSaveDropbox._key)
        }
        
        self.hiddenKeys = hiddenKeys
    }
    
    func cardsLoaded(_ notification: Notification) {
        if let success = notification.userInfo?["success"] as? Bool, success {
            self.refresh()
            DeckManager.flushCache()
        }
    }
    
    func settingsChanged(_ notification: Notification) {
        guard
            let key = notification.userInfo?.keys.first as? String else {
            return
        }
        let value = notification.userInfo?[key]
        
        switch key {
        case DefaultsKeys.useDropbox._key:
            let useDropbox = value as? Bool ?? false
            
            if useDropbox {
                DropboxWrapper.authorizeFromController(self)
            } else {
                DropboxWrapper.unlinkClient()
            }
            
            NotificationCenter.default.post(name: Notifications.dropboxChanged, object: self)
            self.refresh()
            
        case DefaultsKeys.useNrdb._key:
            let useNrdb = value as? Bool ?? false
            if useNrdb {
                self.nrdbLogin()
            } else {
                NRDB.clearSettings()
                NRDBHack.clearCredentials()
            }
            self.refresh()
        case DefaultsKeys.useJintekiNet._key:
            let useJnet = value as? Bool ?? false
            if useJnet {
                self.jnetLogin()
            } else {
                JintekiNet.sharedInstance.clearCredentials()
            }
            self.refresh()
        case DefaultsKeys.updateInterval._key:
            CardManager.setNextDownloadDate()
        case DefaultsKeys.language._key:
            let language = value as? String ?? "n/a"
            Analytics.logEvent("Change Language", attributes: ["Language": language])
        case DefaultsKeys.keepNrdbCredentials._key:
            let keep = value as? Bool ?? false
            
            NRDB.sharedInstance.stopAuthorizationRefresh()
            if keep {
                if Defaults[.useNrdb] {
                    self.nrdbLogin()
                }
            } else {
                NRDBHack.clearCredentials()
                Defaults[.useNrdb] = false
            }
        default:
            break
        }
    }
    
    func nrdbLogin() {
        if !Reachability.online {
            self.showOfflineAlert()
            Defaults[.useNrdb] = false
            return
        }
        
        if Defaults[.keepNrdbCredentials] {
            NRDBHack.sharedInstance.enterNrdbCredentialsAndLogin()
            return
        }
        
        if Device.isIpad {
            NRDBAuthPopupViewController.show(in: self)
        } else {
            NRDBAuthPopupViewController.push(on: self.navigationController!)
        }
    }
    
    func jnetLogin() {
        if !Reachability.online {
            self.showOfflineAlert()
            Defaults[.useJintekiNet] = false
            return
        }
        
        JintekiNet.sharedInstance.enterCredentialsAndLogin()
    }
    
    func settingsViewController(_ sender: IASKAppSettingsViewController!, buttonTappedFor specifier: IASKSpecifier!) {
        let key = specifier.key() ?? ""
        switch key {
        case IASKButtons.downloadDataNow:
            if Reachability.online {
                DataDownload.downloadCardData()
            } else {
                self.showOfflineAlert()
            }
        case IASKButtons.refreshAuthNow:
            if Reachability.online {
                SVProgressHUD.showInfo(withStatus: "re-authenticating")
                NRDB.sharedInstance.backgroundRefreshAuthentication { result in
                    self.refresh()
                    SVProgressHUD.dismiss()
                }
            } else {
                self.showOfflineAlert()
            }
        case IASKButtons.downloadImagesNow:
            if Reachability.online {
                DataDownload.downloadAllImages()
            } else {
                self.showOfflineAlert()
            }
        case IASKButtons.downloadMissingImages:
            if Reachability.online {
                DataDownload.downloadMissingImages()
            } else {
                self.showOfflineAlert()
            }
        case IASKButtons.clearCache:
            let alert = UIAlertController.alert(title: nil, message: "Clear Cache? You will need to re-download all data.".localized())
            alert.addAction(UIAlertAction(title: "No".localized(), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes".localized(), style: .default) { action in
                ImageCache.sharedInstance.clearCache()
                CardManager.removeFiles()
                PackManager.removeFiles()
                PrebuiltManager.removeFiles()
                Defaults[.lastDownload] = "Never".localized()
                Defaults[.nextDownload] = "Never".localized()
                self.refresh()
                
                NotificationCenter.default.post(name: Notifications.loadCards, object: self)
            })
            
            alert.show()
        case IASKButtons.testAPI:
            if Reachability.online {
                self.testApiSettings()
            } else {
                self.showOfflineAlert()
            }
        default:
            break
        }
    }
    
    func testApiSettings() {
        let host = Defaults[.nrdbHost]
        if host.length == 0 {
            UIAlertController.alert(withTitle: nil, message: "Please enter a Server Name".localized(), button: "OK".localized())
            return
        }
        
        SVProgressHUD.show(withStatus: "Testing...".localized())
        
        let nrdbUrl = "https://\(host)/api/2.0/public/card/01001"
        DataDownload.checkNrdbApi(nrdbUrl) { ok in
            self.finishApiTests(ok)
        }
    }
    
    func finishApiTests(_ ok: Bool) {
        SVProgressHUD.dismiss()
        
        let msg = ok ? "NetrunnerDB is OK".localized() : "NetrunnerDB is invalid".localized()
        UIAlertController.alert(withTitle: nil, message: msg, button: "OK".localized())
    }
    
    func showOfflineAlert() {
        UIAlertController.alert(withTitle: nil, message: "An Internet connection is required".localized(), button: "OK".localized())
    }
    
    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController!) {
        // nop
    }
}
