//
//  SettingsViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 09.10.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import InAppSettingsKit
import SVProgressHUD

class SettingsViewController: NSObject, IASKSettingsDelegate {
 
    let iask: IASKAppSettingsViewController
    
    override init() {
        self.iask = IASKAppSettingsViewController(style: .grouped)
        super.init()
        
        self.iask.delegate = self
        self.iask.showDoneButton = false
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.settingsChanged(_:)), name: Notification.Name(kIASKAppSettingChanged), object: nil)
        nc.addObserver(self, selector: #selector(self.cardsLoaded(_:)), name: Notifications.loadCards, object: nil)
        
        self.refresh()
    }
    
    func refresh() {
        var hiddenKeys = Set<String>()
        
        if !CardManager.cardsAvailable || !PackManager.packsAvailable {
            hiddenKeys = Set<String>([ "sets_hide_1", "sets_hide_2", "sets_hide_3", SettingsKeys.BROWSER_PACKS, SettingsKeys.DECKBUILDER_PACKS ])
        }
        if Device.isIphone {
            hiddenKeys.formUnion([ SettingsKeys.AUTO_HISTORY, SettingsKeys.CREATE_DECK_ACTIVE ])
        }
        if Device.isIpad {
            hiddenKeys.formUnion([ "about_hide_1", "about_hide_2" ])
        }
        
        if BuildConfig.release {
            hiddenKeys.formUnion([ SettingsKeys.NRDB_TOKEN_EXPIRY, SettingsKeys.REFRESH_AUTH_NOW, SettingsKeys.LAST_BG_FETCH, SettingsKeys.LAST_REFRESH ])
        }
        
        let settings = UserDefaults.standard
        if !settings.bool(forKey: SettingsKeys.USE_DROPBOX) {
            hiddenKeys.insert(SettingsKeys.AUTO_SAVE_DB)
        }
        
        self.iask.hiddenKeys = hiddenKeys
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
        case SettingsKeys.USE_DROPBOX:
            let useDropbox = value as? Bool ?? false
            
            if useDropbox {
                DropboxWrapper.authorizeFromController(self.iask)
            } else {
                DropboxWrapper.unlinkClient()
            }
            
            NotificationCenter.default.post(name: Notifications.dropboxChanged, object: self)
            self.refresh()
            
        case SettingsKeys.USE_NRDB:
            let useNrdb = value as? Bool ?? false
            if useNrdb {
                self.nrdbLogin()
            } else {
                NRDB.clearSettings()
                NRDBHack.clearCredentials()
            }
            self.refresh()
        case SettingsKeys.USE_JNET:
            let useJnet = value as? Bool ?? false
            if useJnet {
                self.jnetLogin()
            } else {
                JintekiNet.sharedInstance.clearCredentials()
            }
            self.refresh()
        case SettingsKeys.UPDATE_INTERVAL:
            CardManager.setNextDownloadDate()
        case SettingsKeys.LANGUAGE:
            let language = value as? String ?? "n/a"
            Analytics.logEvent("Change Language", attributes: ["Language": language])
        case SettingsKeys.KEEP_NRDB_CREDENTIALS:
            let keep = value as? Bool ?? false
            
            NRDB.sharedInstance.stopAuthorizationRefresh()
            if keep {
                if UserDefaults.standard.bool(forKey: SettingsKeys.USE_NRDB) {
                    self.nrdbLogin()
                }
            } else {
                NRDBHack.clearCredentials()
                UserDefaults.standard.set(false, forKey: SettingsKeys.USE_NRDB)
            }
        default:
            break
        }
    }
    
    func nrdbLogin() {
        let settings = UserDefaults.standard
        
        if !Reachability.online {
            self.showOfflineAlert()
            settings.set(false, forKey: SettingsKeys.USE_NRDB)
            return
        }
        
        if settings.bool(forKey: SettingsKeys.KEEP_NRDB_CREDENTIALS) {
            NRDBHack.sharedInstance.enterNrdbCredentialsAndLogin()
            return
        }
        
        if Device.isIpad {
            NRDBAuthPopupViewController.show(in: self.iask)
        } else {
            NRDBAuthPopupViewController.push(on: self.iask.navigationController!)
        }
    }
    
    func jnetLogin() {
        if !Reachability.online {
            self.showOfflineAlert()
            UserDefaults.standard.set(false, forKey: SettingsKeys.USE_JNET)
            return
        }
        
        JintekiNet.sharedInstance.enterCredentialsAndLogin()
    }
    
    func settingsViewController(_ sender: IASKAppSettingsViewController!, buttonTappedFor specifier: IASKSpecifier!) {
        let key = specifier.key() ?? ""
        switch key {
        case SettingsKeys.DOWNLOAD_DATA_NOW:
            if Reachability.online {
                DataDownload.downloadCardData()
            } else {
                self.showOfflineAlert()
            }
        case SettingsKeys.REFRESH_AUTH_NOW:
            if Reachability.online {
                SVProgressHUD.showInfo(withStatus: "re-authenticating")
                NRDB.sharedInstance.backgroundRefreshAuthentication { result in
                    self.refresh()
                    SVProgressHUD.dismiss()
                }
            } else {
                self.showOfflineAlert()
            }
        case SettingsKeys.DOWNLOAD_IMG_NOW:
            if Reachability.online {
                DataDownload.downloadAllImages()
            } else {
                self.showOfflineAlert()
            }
        case SettingsKeys.DOWNLOAD_MISSING_IMG:
            if Reachability.online {
                DataDownload.downloadMissingImages()
            } else {
                self.showOfflineAlert()
            }
        case SettingsKeys.CLEAR_CACHE:
            let alert = UIAlertController.alert(title: nil, message: "Clear Cache? You will need to re-download all data.".localized())
            alert.addAction(UIAlertAction(title: "No".localized(), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes".localized(), style: .default) { action in
                ImageCache.sharedInstance.clearCache()
                CardManager.removeFiles()
                PackManager.removeFiles()
                PrebuiltManager.removeFiles()
                UserDefaults.standard.set("Never".localized(), forKey: SettingsKeys.LAST_DOWNLOAD)
                UserDefaults.standard.set("Never".localized(), forKey: SettingsKeys.NEXT_DOWNLOAD)
                self.refresh()
                
                NotificationCenter.default.post(name: Notifications.loadCards, object: self)
            })
            
            alert.show()
        case SettingsKeys.TEST_API:
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
        let host = UserDefaults.standard.string(forKey: SettingsKeys.NRDB_HOST) ?? ""
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
