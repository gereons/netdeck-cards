//
//  AppDelegate.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.05.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Fabric
import Crashlytics
import SVProgressHUD
import SwiftyUserDefaults

// TODO: investigate OOMs - memory warnings?

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CrashlyticsDelegate {
    var window: UIWindow?
    
    var launchShortcutItem: UIApplicationShortcutItem?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        if BuildConfig.useCrashlytics {
            Crashlytics.sharedInstance().delegate = self
            Fabric.with([Crashlytics.self])
        }
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        // make sure the Library/Application Support directory exists
        self.ensureAppSupportDirectoryExists()
        let filesExist = CardManager.fileExists() && PackManager.filesExist()
        let initGroup = DispatchGroup()
        
        if filesExist {
            self.window!.rootViewController = StartupViewController()
            self.window!.makeKeyAndVisible()
        }
        
        self.setBuiltinUserDefaults()
        DispatchQueue.global(qos: .userInteractive).async {
            initGroup.enter()
            self.initializeData()
            initGroup.leave()
        }
        self.waitForInitialization(initGroup)
        
        let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem
        if shortcutItem != nil {
            self.launchShortcutItem = shortcutItem
            return false
        }
        return true
    }
    
    private func waitForInitialization(_ initGroup: DispatchGroup) {
        initGroup.notify(queue: DispatchQueue.main) {
            self.finializeLaunch()
        }
    }
    
    private func initializeData() {
        let language = Defaults[.language]
        var cardsOk = false
        let start = Date.timeIntervalSinceReferenceDate
        let setsOk = PackManager.setupFromFiles(language)
        // print("app start, setsOk=\(setsOk)")
        if setsOk {
            cardsOk = CardManager.setupFromFiles(language)
            // print("app start, cardsOk=\(cardsOk)")
        }
        if setsOk && cardsOk {
            let _ = PrebuiltManager.setupFromFiles(language)
        }

        let _ = DeckManager.decksForRole(.none)
        let end = Date.timeIntervalSinceReferenceDate
        print ("init took \(end-start)s")
    }
    
    private func finializeLaunch() {
        let useNrdb = Defaults[.useNrdb]
        let keepCredentials = Defaults[.keepNrdbCredentials]
        let fetchInterval = useNrdb && !keepCredentials ? UIApplicationBackgroundFetchIntervalMinimum : UIApplicationBackgroundFetchIntervalNever
        UIApplication.shared.setMinimumBackgroundFetchInterval(fetchInterval)
        
        if useNrdb && keepCredentials {
            NRDBHack.sharedInstance.silentlyLoginOnStartup()
        }
        
        DropboxWrapper.setup()
        
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setMinimumDismissTimeInterval(1.0)
        
        CardImageViewPopover.monitorKeyboard()
        
        // just so the initializer gets called
        let _ = ImageCache.sharedInstance
        
        Reachability.start()
        
        let root: UIViewController
        if Device.isIphone {
            let navController = UINavigationController(rootViewController: IphoneStartViewController())
            root = navController
        } else {
            let splitView = UISplitViewController()
            let masterNavigation = UINavigationController(rootViewController: ActionsTableViewController())
            splitView.viewControllers = [ masterNavigation, EmptyDetailViewController() ]
            root = splitView
        }
        UINavigationBar.appearance().barTintColor = .white
        if Device.isIphone {
            UINavigationBar.appearance().isTranslucent = false
        }
        self.replaceRootViewController(with: root)
        
        let cardsOk = CardManager.cardsAvailable && PackManager.packsAvailable
        if cardsOk {
            DeckImport.checkClipboardForDeck()
        }
        
        self.logStartup()
    }
    
    private func replaceRootViewController(with viewController: UIViewController) {
        if self.window!.rootViewController == nil {
            self.window!.rootViewController = viewController
            self.window!.makeKeyAndVisible()
        } else {
            let startup = self.window!.rootViewController as! StartupViewController
            startup.stopSpinner()
            
            let snapshot = self.window!.snapshotView(afterScreenUpdates: true)!
            viewController.view.addSubview(snapshot)
            
            self.window!.rootViewController = viewController
            
            UIView.animate(withDuration: 0.25, animations: { _ in
                snapshot.layer.opacity = 0
                snapshot.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
            }, completion: { _ in
                snapshot.removeFromSuperview()
            })
        }
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

        FIXME("needs testing!")
        if let nav = self.window!.rootViewController as? UINavigationController {
            nav.popToRootViewController(animated: false)
            if let start = nav.viewControllers.first as? IphoneStartViewController {
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
        }

        return false
    }
    
    func setBuiltinUserDefaults() {
        let usingNrdb = Defaults[.useNrdb]
        
        let fmt: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyyMMdd"
            return f
        }()
        let today = fmt.string(from: Date())
        
        // fix PackUsage values from previous version
        [ DefaultsKeys.deckbuilderPacks, DefaultsKeys.browserPacks ].forEach {
            let packs = UserDefaults.standard.integer(forKey: $0._key)
            if PackUsage(rawValue: packs) == nil {
                Defaults[$0] = .all
            }
        }
        
        // MWL v1.1 goes into effect 2016-08-01
        let defaultMWL = today >= "20160801" ? MWL.v1_1 : MWL.v1_0
//        let defaultMWL = today >= "20170201" ? MWL.v1_2 : MWL.v1_1
        
        Defaults.registerDefault(.rotationActive, true)
        
        Defaults.registerDefault(.lastDownload, "never".localized())
        Defaults.registerDefault(.nextDownload, "never".localized())
        
        Defaults.registerDefault(.autoHistory, true)
        Defaults.registerDefault(.keepNrdbCredentials, !usingNrdb)
        Defaults.registerDefault(.nrdbHost, "netrunnerdb.com")
        Defaults.registerDefault(.language, "en")
        Defaults.registerDefault(.updateInterval, 7)
        Defaults.registerDefault(.lastBackgroundFetch, "never".localized())
        Defaults.registerDefault(.lastRefresh, "never".localized())
        
        Defaults.registerDefault(.deckFilterState, DeckState.none)
        Defaults.registerDefault(.deckViewStyle, CardView.largeTable)
        Defaults.registerDefault(.deckViewScale, 1.0)
        Defaults.registerDefault(.deckViewSort, DeckSort.byType)
        Defaults.registerDefault(.deckFilterSort, DeckListSort.byName)
        Defaults.registerDefault(.deckFilterType, Filter.all)
        
        Defaults.registerDefault(.browserViewStyle, CardView.largeTable)
        Defaults.registerDefault(.browserViewScale, 1.0)
        Defaults.registerDefault(.browserViewSort, BrowserSort.byType)
        
        Defaults.registerDefault(.browserPacks, PackUsage.selected)
        Defaults.registerDefault(.deckbuilderPacks, PackUsage.selected)
        
        Defaults.registerDefault(.numCores, 3)
        
        Defaults.registerDefault(.showAllFilters, true)
        Defaults.registerDefault(.identityTable, true)
        
        Defaults.registerDefault(.defaultMwl, defaultMWL)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        NRDB.sharedInstance.stopAuthorizationRefresh()
        ImageCache.sharedInstance.resignActive()
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
            }
            return true
        } else if (scheme?.hasPrefix("db-"))! {
            let ok = DropboxWrapper.handleURL(url)
            Defaults[.useDropbox] = ok
            if ok {
                SVProgressHUD.showSuccess(withStatus: "Successfully connected to your Dropbox account".localized())
            }
            
            return true
        }
        
        return false
    }
    
    private func logStartup() {
        let cardLanguage = Defaults[.language]
        let appLanguage = Locale.preferredLanguages.first ?? ""
        let languageComponents = Locale.components(fromIdentifier: appLanguage)
        let languageFromComponents = languageComponents["foo"] ?? ""
        let attrs = [
            "cardLanguage": cardLanguage,
            "appLanguage": appLanguage,
            "Language": cardLanguage + "/" + languageFromComponents,
            "useNrdb": Defaults[.useNrdb] ? "on" : "off",
            "useDropbox": Defaults[.useDropbox] ? "on" : "off",
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
    
    private func ensureAppSupportDirectoryExists() {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths[0]
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: supportDirectory) {
            print("no app support dir - creating it")
            try? fileManager.createDirectory(atPath: supportDirectory, withIntermediateDirectories: true, attributes: nil)
        }
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
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        Defaults[.lastBackgroundFetch] = formatter.string(from: Date())
        
        NRDB.sharedInstance.backgroundRefreshAuthentication { result in
            // NSLog(@"primary call %ld", (long)result)
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
        
        let alert = UIAlertController.alert(title: "Oops, we crashed :(".localized(), message:msg)
        
        alert.addAction(UIAlertAction(title: "Not now".localized(), handler: nil))
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
