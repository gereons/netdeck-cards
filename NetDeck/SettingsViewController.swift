//
//  SettingsViewController.swift
//  NetDeck
//
//  Created by Gereon Steffens on 09.10.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import InAppSettingsKit
import SVProgressHUD
import SwiftyUserDefaults

class Settings {
    static var viewController: IASKAppSettingsViewController = {
        let iask = Settings.iask
        delegate = SettingsDelegate()
        iask.delegate = delegate
        iask.hiddenKeys = delegate.hiddenKeys()
        return iask
    }()

    private static var iask: IASKAppSettingsViewController = {
        let iask = IASKAppSettingsViewController(style: .grouped)
        iask.showDoneButton = false

        // workaround for iOS 11 change in UITableView
        iask.tableView.estimatedRowHeight = 0
        iask.tableView.estimatedSectionHeaderHeight = 0
        iask.tableView.estimatedSectionFooterHeight = 0
        return iask
    }()

    private static var delegate: SettingsDelegate!
}

class SettingsDelegate: NSObject, IASKSettingsDelegate {

    override init() {
        super.init()

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.settingsChanged(_:)), name: .IASKSettingChanged, object: nil)
        nc.addObserver(self, selector: #selector(self.cardsLoaded(_:)), name: Notifications.loadCards, object: nil)

        // self.setHiddenKeys()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func hiddenKeys() -> Set<String> {
        var hiddenKeys = Set<String>()

        if !CardManager.cardsAvailable {
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
        
        if !BuildConfig.debug {
            hiddenKeys.formUnion([
                DefaultsKeys.nrdbTokenExpiry._key, DefaultsKeys.lastBackgroundFetch._key, DefaultsKeys.lastRefresh._key,
                IASKButtons.refreshAuthNow, IASKButtons.clearImageCache, IASKButtons.downloadImagesNow
            ])
        }

        if !Defaults[.useDropbox] {
            hiddenKeys.insert(DefaultsKeys.autoSaveDropbox._key)
        }
        
        if !Defaults[.rotationActive] {
            hiddenKeys.insert(DefaultsKeys.convertCore._key)
            hiddenKeys.insert(DefaultsKeys.rotationIndex._key)
        }

        return hiddenKeys
    }

    @objc func cardsLoaded(_ notification: Notification) {
        if let success = notification.userInfo?["success"] as? Bool, success {
            Settings.viewController.hiddenKeys = self.hiddenKeys()
            DeckManager.flushCache()
        }
    }
    
    @objc func settingsChanged(_ notification: Notification) {
        guard
            let key = notification.userInfo?.keys.first as? String else {
            return
        }
        let value = notification.userInfo?[key]

        // print("settings changed: \(key) = \(value)")

        switch key {
        case DefaultsKeys.useDropbox._key:
            let useDropbox = value as? Bool ?? false
            
            if useDropbox {
                Dropbox.authorizeFromController(Settings.viewController)
            } else {
                Dropbox.unlinkClient()
            }
            
        case DefaultsKeys.useNrdb._key:
            let useNrdb = value as? Bool ?? false
            if useNrdb {
                self.nrdbLogin()
            } else {
                NRDB.clearSettings(setUseNrdb: true)
                NRDBHack.clearCredentials()
            }
            
        case DefaultsKeys.useJintekiNet._key:
            let useJnet = value as? Bool ?? false
            if useJnet {
                self.jnetLogin()
            } else {
                JintekiNet.sharedInstance.clearCredentials()
            }
            
        case DefaultsKeys.updateInterval._key:
            CardManager.setNextDownloadDate()
            
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
                Defaults[.nrdbLoggedin] = false
            }
        
        case DefaultsKeys.rotationActive._key:
            break

        case DefaultsKeys.rotationIndex._key:
            self.reinitializeData()

        default:
            break
        }

        Settings.viewController.hiddenKeys = self.hiddenKeys()
    }

    @objc func settingsViewController(_ sender: IASKAppSettingsViewController, valuesFor specifier: IASKSpecifier) -> [Any] {
        guard let key = specifier.key else {
            return []
        }

        if key == DefaultsKeys.defaultMWL._key {
            return MWLManager.settingsValues()
        } else if key == DefaultsKeys.rotationIndex._key {
            return RotationManager.settingsValues
        }
        
        return []
    }

    @objc func settingsViewController(_ sender: IASKAppSettingsViewController, titlesFor specifier: IASKSpecifier) -> [Any] {
        guard let key = specifier.key else {
            return []
        }

        if key == DefaultsKeys.defaultMWL._key {
            return MWLManager.settingsTitles()
        } else if key == DefaultsKeys.rotationIndex._key {
            return RotationManager.settingsTitles
        }

        return []
    }

    private func reinitializeData() {
        _ = PackManager.setupFromFiles()
        _ = CardManager.setupFromFiles()
        _ = MWLManager.setupFromFiles()
    }

    private func nrdbLogin() {
        if !Reachability.online {
            self.showOfflineAlert()
            Defaults[.nrdbLoggedin] = false
            return
        }
        
        if Defaults[.keepNrdbCredentials] {
            NRDBHack.sharedInstance.enterNrdbCredentialsAndLogin()
            return
        }
        
        if Device.isIpad {
            NRDBAuthPopupViewController.show(in: Settings.viewController)
        } else {
            NRDBAuthPopupViewController.push(on: Settings.viewController.navigationController!)
        }
    }
    
    private func jnetLogin() {
        if !Reachability.online {
            self.showOfflineAlert()
            Defaults[.useJintekiNet] = false
            return
        }
        
        JintekiNet.sharedInstance.enterCredentialsAndLogin()
    }

    private func testApiSettings() {
        let host = Defaults[.nrdbHost]
        if host.count == 0 {
            UIAlertController.alert(withTitle: nil, message: "Please enter a Server Name".localized(), button: "OK".localized())
            return
        }
        
        SVProgressHUD.show(withStatus: "Testing...".localized())
        
        let nrdbUrl = "https://\(host)/api/2.0/public/card/01001"
        DataDownload.checkNrdbApi(nrdbUrl) { ok in
            self.finishApiTests(ok)
        }
    }
    
    private func finishApiTests(_ ok: Bool) {
        SVProgressHUD.dismiss()
        
        let msg = ok ? "NetrunnerDB is OK".localized() : "NetrunnerDB is invalid".localized()
        UIAlertController.alert(withTitle: nil, message: msg, button: "OK".localized())
    }
    
    private func showOfflineAlert() {
        UIAlertController.alert(withTitle: nil, message: "An Internet connection is required".localized(), button: "OK".localized())
    }

    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController) {
        // nop
    }

    func settingsViewController(_ sender: IASKAppSettingsViewController, buttonTappedFor specifier: IASKSpecifier) {
        let key = specifier.key ?? ""
        switch key {
        case IASKButtons.downloadDataNow:
            if Reachability.online {
                DataDownload.downloadCardData()
                ImageCache.sharedInstance.resetUnavailableImages()
            } else {
                self.showOfflineAlert()
            }
        case IASKButtons.refreshAuthNow:
            if Reachability.online {
                SVProgressHUD.showInfo(withStatus: "re-authenticating")
                NRDB.sharedInstance.backgroundRefreshAuthentication { result in
                    Settings.viewController.hiddenKeys = self.hiddenKeys()
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
                CardManager.removeFiles()
                PackManager.removeFiles()
                Defaults[.lastDownload] = "Never".localized()
                Defaults[.nextDownload] = "Never".localized()
                Settings.viewController.hiddenKeys = self.hiddenKeys()

                NotificationCenter.default.post(name: Notifications.loadCards, object: self)
            })

            alert.show()
        case IASKButtons.clearImageCache:
            let alert = UIAlertController.alert(title: nil, message: "Clear Image Cache? You will need to re-download all images.".localized())
            alert.addAction(UIAlertAction(title: "No".localized(), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes".localized(), style: .default) { action in
                ImageCache.sharedInstance.clearCache()
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
}
