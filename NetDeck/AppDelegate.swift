//
//  AppDelegate.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.05.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Fabric
import Crashlytics
import SVProgressHUD

// TODO: investigate OOMs - memory warnings?
// TODO: make TableData type-safe (ie, rewrite all users in Swift)
// TODO: ImageCache: when Haneke is at Swift 3, test it as a replacement

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CrashlyticsDelegate {
    var window: UIWindow?
    
    // root controller on ipad
    @IBOutlet var splitViewController: UISplitViewController?
    @IBOutlet var detailViewManager: DetailViewManager?
    
    // root controller on iphone
    @IBOutlet var navigationController: UINavigationController?
    
    var launchShortcutItem: UIApplicationShortcutItem?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if BuildConfig.useCrashlytics {
            Crashlytics.sharedInstance().delegate = self
            Fabric.with([Crashlytics.self]);
        }
        
        FIXME("test deck imports: dropbox, meteor, nrdb, clipboard")
        
        self.setBuiltinUserDefaults()
        
        var setsOk = false
        var cardsOk = false
        
        let language = UserDefaults.standard.string(forKey: SettingsKeys.LANGUAGE) ?? "en"
        setsOk = PackManager.setupFromFiles(language)
        // print("app start, setsOk=\(setsOk)")
        if setsOk {
            cardsOk = CardManager.setupFromFiles(language)
            // print("app start, cardsOk=\(cardsOk)")
        }
        if setsOk && cardsOk {
            let _ = PrebuiltManager.setupFromFiles(language)
        }
                
        let settings = UserDefaults.standard
        let useNrdb = settings.bool(forKey: SettingsKeys.USE_NRDB)
        let keepCredentials = settings.bool(forKey: SettingsKeys.KEEP_NRDB_CREDENTIALS)
        let fetchInterval = useNrdb && !keepCredentials ? UIApplicationBackgroundFetchIntervalMinimum : UIApplicationBackgroundFetchIntervalNever;
        UIApplication.shared.setMinimumBackgroundFetchInterval(fetchInterval)
        
        if useNrdb && keepCredentials {
            NRDBHack.sharedInstance.silentlyLoginOnStartup()
        }
        
        DropboxWrapper.setup()
        
        SVProgressHUD.setBackgroundColor(UIColor(white: 0.9, alpha: 1.0))
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setMinimumDismissTimeInterval(1.0)
        
        CardImageViewPopover.monitorKeyboard()
        
        // just so the initializer gets called
        let _ = ImageCache.sharedInstance
        
        Reachability.start()
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        if (Device.isIphone) {
            self.window!.rootViewController = self.navigationController
        } else {
            self.window!.rootViewController = self.splitViewController
        }
        self.window!.makeKeyAndVisible()
        
        if cardsOk {
            DeckImport.checkClipboardForDeck()
        }
        
        self.logStartup()
        
        let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem
        if shortcutItem != nil {
            self.launchShortcutItem = shortcutItem
            return false
        }
        
        return true
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let ok = self.handleShortcutItem(shortcutItem)
        completionHandler(ok)
    }
    
    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        let cardsOk = CardManager.cardsAvailable && PackManager.packsAvailable
        if !cardsOk || !Device.isIphone {
            return false
        }
        
        if let start = self.navigationController as? IphoneStartViewController {
            start.popToRootViewController(animated: false)
            
            switch shortcutItem.type {
            case "org.steffens.NRDB.newRunner":
                start.addNewDeck(.runner)
                return true
            case "org.steffens.NRDB.newCorp":
                start.addNewDeck(.corp)
                return true
            case "org.steffens.NRDB.cardBrowswer":
                start.openBrowser()
                return true
            default:
                return false
            }
        }
        return false
    }
    
    func setBuiltinUserDefaults() {
        let usingNrdb = UserDefaults.standard.bool(forKey: SettingsKeys.USE_NRDB)
        
        let fmt: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyyMMdd"
            return f
        }()
        let today = fmt.string(from: Date())
        
        // MWL v1.1 goes into effect 2016-08-01
        let defaultMWL = today >= "20160801" ? NRMWL.v1_1 : NRMWL.v1_0;
        
        let defaults: [String: Any] = [
            SettingsKeys.LAST_DOWNLOAD: "never".localized(),
            SettingsKeys.NEXT_DOWNLOAD: "never".localized(),
            
            SettingsKeys.USE_DRAFT: false,
            SettingsKeys.AUTO_SAVE: false,
            SettingsKeys.AUTO_HISTORY: true,
            SettingsKeys.USE_DROPBOX: false,
            SettingsKeys.AUTO_SAVE_DB: false,
            SettingsKeys.USE_NRDB: false,
            SettingsKeys.KEEP_NRDB_CREDENTIALS: !usingNrdb,
            SettingsKeys.NRDB_AUTOSAVE: false,
            SettingsKeys.NRDB_HOST: "netrunnerdb.com",
            SettingsKeys.LANGUAGE: "en",
            SettingsKeys.UPDATE_INTERVAL: 7,
            SettingsKeys.LAST_BG_FETCH: "never".localized(),
            SettingsKeys.LAST_REFRESH: "never".localized(),
            
            SettingsKeys.DECK_FILTER_STATE: NRDeckState.none.rawValue,
            SettingsKeys.DECK_VIEW_STYLE: NRCardView.largeTable.rawValue,
            SettingsKeys.DECK_VIEW_SCALE: 1.0,
            SettingsKeys.DECK_VIEW_SORT: NRDeckSort.byType.rawValue,
            SettingsKeys.DECK_FILTER_SORT: NRDeckListSort.byName.rawValue,
            SettingsKeys.DECK_FILTER_TYPE: NRFilter.all.rawValue,
            
            SettingsKeys.CREATE_DECK_ACTIVE: false,
            
            SettingsKeys.BROWSER_VIEW_STYLE: NRCardView.largeTable.rawValue,
            SettingsKeys.BROWSER_VIEW_SCALE: 1.0,
            SettingsKeys.BROWSER_SORT_TYPE: NRBrowserSort.byType.rawValue,
            
            SettingsKeys.BROWSER_PACKS: NRPackUsage.selected.rawValue,
            SettingsKeys.DECKBUILDER_PACKS: NRPackUsage.selected.rawValue,
            
            SettingsKeys.NUM_CORES: 3,
            
            SettingsKeys.SHOW_ALL_FILTERS: true,
            SettingsKeys.IDENTITY_TABLE: true,
            
            SettingsKeys.MWL_VERSION: defaultMWL.rawValue
        ]
        
        UserDefaults.standard.register(defaults: defaults)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        NRDB.sharedInstance.stopAuthorizationRefresh()
        ImageCache.sharedInstance.saveData()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        DeckImport.checkClipboardForDeck()
        NRDB.sharedInstance.startAuthorizationRefresh()
        
        self.logStartup()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if let shortCut = self.launchShortcutItem {
            let _ = self.handleShortcutItem(shortCut)
            self.launchShortcutItem = nil
        }
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        print("got mem warning")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        let scheme = url.scheme
        
        if scheme == "netdeck" {
            if url.host == "oauth2" {
                NRDBAuthPopupViewController.handleOpen(url: url)
            } else if url.host == "load" {
                DeckImport.importDeckFromLocalUrl(url)
            }
            return true
        } else if (scheme?.hasPrefix("db-"))! {
            let ok = DropboxWrapper.handleURL(url)
            UserDefaults.standard.set(ok, forKey:SettingsKeys.USE_DROPBOX)
            
            if ok {
                SVProgressHUD.showSuccess(withStatus: "Successfully connected to your Dropbox account".localized())
            }
            
            return true
        }
        
        return false
    }
    
    private func logStartup() {
        let settings = UserDefaults.standard
        
        let cardLanguage = settings.string(forKey: SettingsKeys.LANGUAGE) ?? ""
        let appLanguage = Locale.preferredLanguages.first ?? ""
        let languageComponents = Locale.components(fromIdentifier: appLanguage)
        let languageFromComponents = languageComponents["foo"] ?? ""
        let attrs = [
            "cardLanguage": cardLanguage,
            "appLanguage": appLanguage,
            "Language": cardLanguage + "/" + languageFromComponents,
            "useNrdb": settings.bool(forKey: SettingsKeys.USE_NRDB) ? "on" : "off",
            "useDropbox": settings.bool(forKey: SettingsKeys.USE_DROPBOX) ? "on" : "off",
            "device": UIDevice.current.model,
            "os": UIDevice.current.systemVersion
        ]
        Analytics.logEvent("Start", attributes: attrs)
    }
    
    class func appVersion() -> String {
        var version = ""
        if let bundleInfo = Bundle.main.infoDictionary {
            // CFBundleShortVersionString contains the main version
            let shortVersion = (bundleInfo["CFBundleShortVersionString"] as? String) ?? ""
            version = "v" + shortVersion
            
            if BuildConfig.debug {
                // CFBundleVersion contains the git rev-parse output
                let bundleVersion = (bundleInfo["CFBundleVersion"] as? String) ?? ""
                version += "-" + bundleVersion
            }
        }
        return version
    }
    
    // utility method: set the excludeFromBackup flag on the specified path
    class func excludeFromBackup(_ path: String) {
        let url = NSURL(fileURLWithPath:path)
        do {
            try url.setResourceValue(true, forKey:URLResourceKey.isExcludedFromBackupKey)
        } catch let error {
            NSLog("setResource error=\(error)")
        }
    }
    
    // MARK: - bg fetch
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        UserDefaults.standard.set(Date(), forKey: SettingsKeys.LAST_BG_FETCH)
        
        NRDB.sharedInstance.backgroundRefreshAuthentication { result in
            // NSLog(@"primary call %ld", (long)result);
            completionHandler(result)
        }
    }
    
    // MARK: - crashlytics delegate 
    func crashlyticsDidDetectReport(forLastExecution report: CLSReport, completionHandler: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            completionHandler(true)
        }
        self.perform(#selector(AppDelegate.showAlert), with: nil, afterDelay: 0.15)
    }
    
    func showAlert() {
        let msg = "Sorry, that shouldn't have happened.\nIf you can reproduce the bug, please tell the developers about it.".localized()
        
        let alert = UIAlertController.alert(withTitle: "Oops, we crashed :(".localized(), message:msg)
        
        alert.addAction(UIAlertAction(title: "Not now".localized(), handler:nil))
        alert.addAction(UIAlertAction(title: "OK".localized()) { action in
            let subject = "Bug in Net Deck " + AppDelegate.appVersion()
            let body = "If possible, please describe what caused the crash. Thanks!"
            
            var mailto = "mailto:netdeck@steffens.org?subject="
            mailto += subject.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
            mailto += "&body="
            mailto += body.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
            
            UIApplication.shared.openURL(URL(string:mailto)!)
        })
        
        self.window?.rootViewController?.present(alert, animated:false, completion:nil)
    }
    
}
