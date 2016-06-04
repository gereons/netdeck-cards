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

// TODO: browser: allow all know sets?
// TODO: use icon font for special symbols, including rendererd html text
// TODO: prepare for nrdb api changes?
// TODO: improve startup time
// TODO: make TableData type-safe (ie, rewrite all users in Swift)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CrashlyticsDelegate {
    var window: UIWindow?
    
    // root controller on ipad
    @IBOutlet var splitViewController: UISplitViewController?
    @IBOutlet var detailViewManager: DetailViewManager?
    
    // root controller on iphone
    @IBOutlet var navigationController: UINavigationController?
    
    var launchShortcutItem: UIApplicationShortcutItem?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        if BuildConfig.useCrashlytics {
            Crashlytics.sharedInstance().delegate = self
            Fabric.with([Crashlytics.self]);
        }
        
        self.setBuiltinUserDefaults()
        
        var setsOk = false
        var cardsOk = false
        
        let language = NSUserDefaults.standardUserDefaults().stringForKey(SettingsKeys.LANGUAGE) ?? "en"
        setsOk = PackManager.setupFromFiles(language)
        print("app start, setsOk=\(setsOk)")
        if setsOk {
            cardsOk = CardManager.setupFromFiles(language)
            print("app start, cardsOk=\(cardsOk)")
        }
        
        if !setsOk || !cardsOk {
            PackManager.removeFiles()
            CardManager.removeFiles()
        }
        
        let settings = NSUserDefaults.standardUserDefaults()
        let useNrdb = settings.boolForKey(SettingsKeys.USE_NRDB)
        let keepCredentials = settings.boolForKey(SettingsKeys.KEEP_NRDB_CREDENTIALS)
        let fetchInterval = useNrdb && !keepCredentials ? UIApplicationBackgroundFetchIntervalMinimum : UIApplicationBackgroundFetchIntervalNever;
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(fetchInterval)
        
        if useNrdb && keepCredentials {
            NRDBHack.sharedInstance.silentlyLoginOnStartup()
        }
        
        DropboxWrapper.setup()
        
        SVProgressHUD.setBackgroundColor(UIColor(white: 0.9, alpha: 1.0))
        SVProgressHUD.setDefaultMaskType(.Black)
        SVProgressHUD.setMinimumDismissTimeInterval(2.0)
        
        CardImageViewPopover.monitorKeyboard()
        
        // just so the initializer gets called
        let _ = ImageCache.sharedInstance
        
        Reachability.start()
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
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
        
        let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem
        if shortcutItem != nil {
            self.launchShortcutItem = shortcutItem
            return false
        }
        
        return true
    }
    
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        let ok = self.handleShortcutItem(shortcutItem)
        completionHandler(ok)
    }
    
    func handleShortcutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
    
        let cardsOk = CardManager.cardsAvailable() && PackManager.packsAvailable()
        if !cardsOk || !Device.isIphone {
            return false
        }
        
        if let start = self.navigationController as? IphoneStartViewController {
            start.popToRootViewControllerAnimated(false)
            
            switch shortcutItem.type {
            case "org.steffens.NRDB.newRunner":
                start.addNewDeck(NRRole.Runner.rawValue)
                return true
            case "org.steffens.NRDB.newCorp":
                start.addNewDeck(NRRole.Corp.rawValue)
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
        let usingNrdb = NSUserDefaults.standardUserDefaults().boolForKey(SettingsKeys.USE_NRDB)
        let defaults: [String: AnyObject] = [
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
            
            SettingsKeys.DECK_FILTER_STATE: NRDeckState.None.rawValue,
            SettingsKeys.DECK_VIEW_STYLE: NRCardView.LargeTable.rawValue,
            SettingsKeys.DECK_VIEW_SCALE: 1.0,
            SettingsKeys.DECK_VIEW_SORT: NRDeckSort.ByType.rawValue,
            SettingsKeys.DECK_FILTER_SORT: NRDeckListSort.ByName.rawValue,
            SettingsKeys.DECK_FILTER_TYPE: NRFilter.All.rawValue,
            
            SettingsKeys.CREATE_DECK_ACTIVE: false,
            
            SettingsKeys.BROWSER_VIEW_STYLE: NRCardView.LargeTable.rawValue,
            SettingsKeys.BROWSER_VIEW_SCALE: 1.0,
            SettingsKeys.BROWSER_SORT_TYPE: NRBrowserSort.ByType.rawValue,
            
            SettingsKeys.NUM_CORES: 3,
            
            SettingsKeys.SHOW_ALL_FILTERS: true,
            SettingsKeys.IDENTITY_TABLE: true,
            
            SettingsKeys.USE_NAPD_MWL: true
        ]
        
        NSUserDefaults.standardUserDefaults().registerDefaults(defaults)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        NRDB.sharedInstance.stopAuthorizationRefresh()
        ImageCache.sharedInstance.saveData()
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        DeckImport.checkClipboardForDeck()
        NRDB.sharedInstance.startAuthorizationRefresh()
        
        self.logStartup()
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if let shortCut = self.launchShortcutItem {
            self.handleShortcutItem(shortCut)
            self.launchShortcutItem = nil
        }
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        let scheme = url.scheme
        
        if scheme == "netdeck" {
            if url.host == "oauth2" {
                NRDBAuthPopupViewController.handleOpenURL(url)
            } else if url.host == "load" {
                DeckImport.importDeckFromLocalUrl(url)
            }
            return true
        } else if scheme.hasPrefix("db-") {
            let ok = DropboxWrapper.handleURL(url)
            NSUserDefaults.standardUserDefaults().setBool(ok, forKey:SettingsKeys.USE_DROPBOX)
            
            if ok {
                SVProgressHUD.showSuccessWithStatus("Successfully connected to your Dropbox account".localized())
            }
            
            return true
        }
        
        return false
    }
    
    private func logStartup() {
        let settings = NSUserDefaults.standardUserDefaults()
        
        let cardLanguage = settings.stringForKey(SettingsKeys.LANGUAGE) ?? ""
        let appLanguage = NSLocale.preferredLanguages().first ?? ""
        let languageComponents = NSLocale.componentsFromLocaleIdentifier(appLanguage)
        let languageFromComponents = languageComponents[NSLocaleLanguageCode] ?? ""
        let attrs = [
            "cardLanguage": cardLanguage,
            "appLanguage": appLanguage,
            "Language": cardLanguage + "/" + languageFromComponents,
            "useNrdb": settings.boolForKey(SettingsKeys.USE_NRDB) ? "on" : "off",
            "useDropbox": settings.boolForKey(SettingsKeys.USE_DROPBOX) ? "on" : "off",
            "device": UIDevice.currentDevice().model,
            "os": UIDevice.currentDevice().systemVersion
        ]
        Analytics.logEvent("Start", attributes: attrs)
    }
    
    class func appVersion() -> String {
        var version = ""
        if let bundleInfo = NSBundle.mainBundle().infoDictionary {
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
    class func excludeFromBackup(path: String) {
        let url = NSURL(fileURLWithPath:path)
        do {
            try url.setResourceValue(true, forKey:NSURLIsExcludedFromBackupKey)
        } catch let error {
            NSLog("setResource error=\(error)")
        }
    }

    // MARK: - bg fetch
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: SettingsKeys.LAST_BG_FETCH)
        
        NRDB.sharedInstance.backgroundRefreshAuthentication { result in
            // NSLog(@"primary call %ld", (long)result);
            completionHandler(result)
        }
    }
    
    // MARK: - crashlytics delegate 
    func crashlyticsDidDetectReportForLastExecution(report: CLSReport, completionHandler: (Bool) -> Void) {
        dispatch_async(dispatch_get_main_queue()) {
            completionHandler(true)
        }
        self.performSelector(#selector(AppDelegate.showAlert), withObject: nil, afterDelay: 0.15)
    }
    
    func showAlert() {
        let msg = "Sorry, that shouldn't have happened.\nIf you can reproduce the bug, please tell the developers about it.".localized()
        
        let alert = UIAlertController.alertWithTitle("Oops, we crashed :(".localized(), message:msg)
        
        alert.addAction(UIAlertAction(title: "Not now".localized(), handler:nil))
        alert.addAction(UIAlertAction(title: "OK".localized()) { action in
            let subject = "Bug in Net Deck " + AppDelegate.appVersion()
            let body = "If possible, please describe what caused the crash. Thanks!"
            
            var mailto = "mailto:netdeck@steffens.org?subject="
            mailto += subject.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) ?? ""
            mailto += "&body="
            mailto += body.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) ?? ""
            
            UIApplication.sharedApplication().openURL(NSURL(string:mailto)!)
        })
        
        self.window?.rootViewController?.presentViewController(alert, animated:false, completion:nil)
    }
    
}
