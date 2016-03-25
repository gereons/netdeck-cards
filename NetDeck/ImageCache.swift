//
//  ImageCache.swift
//  NetDeck
//
//  Created by Gereon Steffens on 06.03.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Alamofire
import AlamofireImage

class ImageCache: NSObject {
    static let imagesDirectory = "images"
    static let sharedInstance = ImageCache()
    
    static let trashIcon = UIImage(named: "cardstats_trash")!
    static let strengthIcon = UIImage(named: "cardstats_strength")!
    static let creditIcon = UIImage(named: "cardstats_credit")!
    static let muIcon = UIImage(named: "cardstats_mem")!
    static let apIcon = UIImage(named: "cardstats_points")!
    static let linkIcon = UIImage(named: "cardstats_link")!
    static let cardIcon = UIImage(named: "cardstats_decksize")!
    static let difficultyIcon = UIImage(named: "cardstats_difficulty")!
    static let influenceIcon = UIImage(named: "cardstats_influence")!
    
    static let hexTile = UIImage(named: "hex_background")!

    static let runnerPlaceholder = UIImage(named: "RunnerPlaceholder")!
    static let corpPlaceholder = UIImage(named: "CorpPlaceholder")!
    
    class func placeholderFor(role: NRRole) -> UIImage {
        return role == .Runner ? self.runnerPlaceholder : self.corpPlaceholder
    }

    static let IMAGE_WIDTH = 300
    static let IMAGE_HEIGHT = 418
    
    private static let debugLog = false
    private static let SEC_PER_DAY = 24 * 60 * 60
    private static let SUCCESS_INTERVAL = NSTimeInterval(30 * SEC_PER_DAY)
    private static let ERROR_INTERVAL = NSTimeInterval(1 * SEC_PER_DAY)
    
    private let memCache: NSCache = {
        let c = NSCache()
        c.name = "imgCache"
        return c
    }()
    
    // img keys we know aren't downloadable (yet)
    private var unavailableImages = Set<String>()
    
    // Last-Modified date of each image
    private var lastModifiedDates = [String: String]()  // code -> last-modified
    
    // when to next check if an img was updated
    private var nextCheckDates = [String: NSDate]()     // code -> date
    
    private override init() {
        super.init()
        
        let settings = NSUserDefaults.standardUserDefaults()
        
        if let lastMod = settings.dictionaryForKey(SettingsKeys.LAST_MOD_CACHE) as? [String: String] {
            self.lastModifiedDates = lastMod
        }
        
        if let nextCheck = settings.dictionaryForKey(SettingsKeys.NEXT_CHECK) as? [String: NSDate] {
            self.nextCheckDates = nextCheck
        }
        
        if let imgs = settings.arrayForKey(SettingsKeys.UNAVAILABLE_IMAGES) as? [String] {
            self.unavailableImages.unionInPlace(imgs)
        }
        
        let now = NSDate.timeIntervalSinceReferenceDate()
        let lastCheck = settings.doubleForKey(SettingsKeys.UNAVAIL_IMG_DATE) ?? now + 3600.0
        
        if lastCheck < now {
            unavailableImages.removeAll()
            settings.setDouble(now + 48*3600, forKey:SettingsKeys.UNAVAIL_IMG_DATE)
            settings.setObject(Array(self.unavailableImages), forKey:SettingsKeys.UNAVAILABLE_IMAGES)
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            self.initializeMemCache()
        }
    }
    
    func saveData() {
        let settings = NSUserDefaults.standardUserDefaults()
        
        settings.setObject(self.lastModifiedDates, forKey: SettingsKeys.LAST_MOD_CACHE)
        settings.setObject(self.nextCheckDates, forKey: SettingsKeys.NEXT_CHECK)
        settings.setObject(Array(self.unavailableImages), forKey: SettingsKeys.UNAVAILABLE_IMAGES)
        settings.synchronize()
    }
    
    func getImageFor(card: Card, completion: (Card, UIImage, Bool) -> Void) {
        let key = card.code
        
        if let img = memCache.objectForKey(key) as? UIImage {
            completion(card, img, false)
            return
        }
        
        // if we know we don't (or can't) have an image, return a placeholder immediately
        if card.imageSrc == nil || unavailableImages.contains(key) {
            completion(card, ImageCache.placeholderFor(card.role), true)
            return
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            // get image from our on-disk cache
            if let img = self.getDecodedImageFor(key)
            {
                if Reachability.online() {
                    self.checkForImageUpdate(card, key: key)
                }
                
                self.memCache.setObject(img, forKey: key)
                dispatch_async(dispatch_get_main_queue()) {
                    completion(card, img, false)
                }
            }
            else
            {
                // image is not in on-disk cache
                if Reachability.online() {
                    self.downloadImageFor(card, key: key) { (card, image, placeholder) in
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(card, image, placeholder)
                        }
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(card, ImageCache.placeholderFor(card.role), true)
                    }
                }
            }
        }
    }
    
    func updateMissingImageFor(card: Card, completion: (Bool) -> Void) {
        if let _ = self.getImageFor(card.code) {
            completion(true)
        } else {
            self.updateImageFor(card, completion: completion)
        }
    }
    
    func updateImageFor(card: Card, completion: (Bool) -> Void) {
        guard Reachability.online() else {
            completion(false)
            return
        }
        guard let imgUrl = card.imageSrc, url = NSURL(string: imgUrl) else {
            completion(false)
            return
        }
        
        let key = card.code
        
        let request = NSMutableURLRequest(URL:url, cachePolicy: .ReloadIgnoringCacheData, timeoutInterval: 10)
        let lastModDate = self.lastModifiedDates[key]
        if lastModDate != nil {
            request.setValue(lastModDate, forHTTPHeaderField: "If-Modified-Since")
        }
    
        Alamofire.request(request).responseImage { response in
            if let img = response.result.value {
                let lastModified = response.response?.allHeaderFields["Last-Modified"] as? String
                self.NLOG("up: GOT %@ If-Modified-Since %@: status 200", url, lastModified ?? "n/a");
                self.storeInCache(img, lastModified: lastModified, key: key)
                completion(true)
            } else {
                self.NLOG("up: GOT %@ If-Modified-Since %@: status %ld", url, lastModDate ?? "n/a", response.response?.statusCode ?? 999)
                completion(response.response?.statusCode == 304)
            }
        }
    }
    
    func imageAvailableFor(card: Card) -> Bool {
        let key = card.code
        
        if let _ = self.memCache.objectForKey(key) {
            return true
        }
        
        // if we know we don't (or can't) have an image, return a placeholder immediately
        if card.imageSrc == nil || self.unavailableImages.contains(key) {
            return false
        }
        
        let dir = self.directoryForImages()
        let file = dir.stringByAppendingPathComponent(key)
        
        return NSFileManager.defaultManager().fileExistsAtPath(file)
    }

    func croppedImage(img: UIImage, forCard card: Card) -> UIImage? {
        var scale = 1.0
        if img.size.width * img.scale > 300 {
            scale = 1.436
        }
        let key = String(format: "%@:crop", card.code)
        
        var cropped = self.memCache.objectForKey(key) as? UIImage
        if cropped == nil {
            let rect = CGRect(x: Int(10.0*scale), y: Int(card.cropY*scale), width: Int(280.0*scale), height: Int(209.0*scale))
            let imageRef = CGImageCreateWithImageInRect(img.CGImage, rect)
            cropped = UIImage(CGImage: imageRef!)
            if (cropped != nil) {
                self.memCache.setObject(cropped!, forKey:key)
            }
        }
        return cropped
    }
    
    func clearLastModifiedInfo() {
        let settings = NSUserDefaults.standardUserDefaults()
        self.lastModifiedDates.removeAll()
        self.nextCheckDates.removeAll()
        settings.setObject(self.lastModifiedDates, forKey: SettingsKeys.LAST_MOD_CACHE)
        settings.setObject(self.nextCheckDates, forKey: SettingsKeys.NEXT_CHECK)
        
        self.memCache.removeAllObjects()
    }
    
    func clearCache() {
        self.clearLastModifiedInfo()
        
        self.unavailableImages.removeAll()
        let settings = NSUserDefaults.standardUserDefaults()
        settings.setObject(Array(self.unavailableImages), forKey: SettingsKeys.UNAVAILABLE_IMAGES)
        
        self.removeCacheDirectory()
    }
    
    private func NLOG(format: String, _ args: CVarArgType...) {
        if ImageCache.debugLog {
            let x = String(format: format, arguments: args)
            NSLog(x)
        }
    }
    
    private func storeInCache(img: UIImage, lastModified: String?, key: String) {
        var interval = ImageCache.SUCCESS_INTERVAL
        if lastModified != nil {
            self.lastModifiedDates[key] = lastModified!
        } else {
            interval = ImageCache.ERROR_INTERVAL
        }
        
        self.nextCheckDates[key] = NSDate(timeIntervalSinceNow: interval)
        
        if !self.saveImage(img, key: key) {
            self.lastModifiedDates.removeValueForKey(key)
        }
    }
    
    private func saveImage(image: UIImage, key: String) -> Bool {
        let dir = self.directoryForImages()
        let file = dir.stringByAppendingPathComponent(key)
        
        var img = image
        self.NLOG("save img for %@", key)
        if img.size.width > 300 {
            // rescale image to 300x418 and save the scaled-down version
            
            if let newImg = self.scaleImage(img, toSize:CGSize(width: ImageCache.IMAGE_WIDTH, height: ImageCache.IMAGE_HEIGHT)) {
                img = newImg
            }
        }
        
        self.memCache.setObject(img, forKey:key)
        
        if let data = UIImagePNGRepresentation(img) {
            data.writeToFile(file, atomically: true)
            AppDelegate.excludeFromBackup(file)
            return true
        }
        return false
    }
    
    private func scaleImage(img: UIImage, toSize size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        
        img.drawInRect(CGRectMake(0.0, 0.0, size.width, size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    private func removeCacheDirectory() {
        let paths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)
        let supportDirectory = paths.first!
        
        let directory = supportDirectory.stringByAppendingPathComponent(ImageCache.imagesDirectory)
        
        let _ = try? NSFileManager.defaultManager().removeItemAtPath(directory)
    }
    
    private func initializeMemCache() {
        // NSLog("start initMemCache")
        let dir = self.directoryForImages()
        guard let files = try? NSFileManager.defaultManager().contentsOfDirectoryAtPath(dir) else {
            return
        }
        
        for file in files {
            let imgFile = dir.stringByAppendingPathComponent(file)
            
            if let imgData = NSData(contentsOfFile: imgFile) {
                if let img = self.decodedImage(UIImage(data: imgData)) {
                    self.memCache.setObject(img, forKey:file)
                }
            }
        }
        // NSLog("end initMemCache")
    }
    
    private func getImageFor(key: String) -> UIImage? {
        if let img = self.memCache.objectForKey(key) as? UIImage {
            return img
        }
        
        let img = self.getDecodedImageFor(key)
        if img != nil  {
            memCache.setObject(img!, forKey: key)
        }
        return img
    }
    
    private func getDecodedImageFor(key: String) -> UIImage? {
        let dir = self.directoryForImages()
        let file = dir.stringByAppendingPathComponent(key)
        
        var img: UIImage?
        if let imgData = NSData(contentsOfFile: file) {
            img = self.decodedImage(UIImage(data: imgData))
        }
        
        if img == nil || img?.size.width < 200 {
            // image is broken - remove it
            img = nil
            let _ = try? NSFileManager.defaultManager().removeItemAtPath(file)
            self.lastModifiedDates.removeValueForKey(key)
        }
        
        return img
    }
    
    private func checkForImageUpdate(card: Card, key: String) {
        guard let src = card.imageSrc else {
            return
        }
        
        if let checkDate = self.nextCheckDates[key] {
            let now = NSDate()
            if now.timeIntervalSinceReferenceDate < checkDate.timeIntervalSinceReferenceDate {
                // no need to check
                return
            }
        }
        
        self.NLOG("check for %@", key)
        let url = NSURL(string: src)
        let request = NSMutableURLRequest(URL: url!, cachePolicy: .ReloadIgnoringCacheData, timeoutInterval: 10)
        let lastModDate = self.lastModifiedDates[key]
        if lastModDate != nil {
            request.setValue(lastModDate, forHTTPHeaderField: "If-Modified-Since")
        }
        
        self.NLOG("GET %@ If-Modified-Since %@", src, lastModDate ?? "n/a");
        Alamofire.request(request).responseImage { response in
            if let img = response.result.value {
                self.NLOG("GOT %@ status 200")
                let lastModified = response.response?.allHeaderFields["Last-Modified"] as? String
                self.storeInCache(img, lastModified: lastModified, key: key)
            } else if response.response?.statusCode == 304 {
                self.NLOG("GOT %@ status 304")
                self.nextCheckDates[key] = NSDate(timeIntervalSinceNow: ImageCache.SUCCESS_INTERVAL)
            } else {
                self.NLOG("GOT %@ failure")
                self.nextCheckDates[key] = NSDate(timeIntervalSinceNow: ImageCache.ERROR_INTERVAL)
            }
        }
    }
    
    private func downloadImageFor(card: Card, key: String, completion: (Card, UIImage, Bool) -> Void) {
        guard let src = card.imageSrc else {
            let img = ImageCache.placeholderFor(card.role)
            completion(card, img, true)
            return
        }
        
        Alamofire.request(.GET, src)
            .validate()
            .responseImage { response in
                switch response.result {
                case .Success:
                    self.NLOG("dl: GET %@: status 200", src)
                    if let img = response.result.value {
                        completion(card, img, false)
                        let lastModified = response.response?.allHeaderFields["Last-Modified"] as? String
                        self.storeInCache(img, lastModified: lastModified, key: key)
                        if self.unavailableImages.contains(key) {
                            self.unavailableImages.remove(key)
                        }
                        return
                    }
                    fallthrough
                case .Failure:
                    self.NLOG("dl: GET %@ for %@: error %ld", src, card.name, response.response?.statusCode ?? 999)
                    let img = ImageCache.placeholderFor(card.role)
                    completion(card, img, true)
                    self.unavailableImages.insert(key)
                    self.lastModifiedDates.removeValueForKey(key)
                }
            }
    }
    
    private func directoryForImages() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)
        let supportDirectory = paths.first!
        
        let directory = supportDirectory.stringByAppendingPathComponent(ImageCache.imagesDirectory)
        
        let fileMgr = NSFileManager.defaultManager()
        if !fileMgr.fileExistsAtPath(directory) {
            let _ = try? fileMgr.createDirectoryAtPath(directory, withIntermediateDirectories: true, attributes: nil)
        }
        
        return directory
    }
    
    private func decodedImage(img: UIImage?) -> UIImage? {
        if img == nil {
            return nil
        }
        let imageRef = img!.CGImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Makes system don't need to do extra conversion when displayed.
        let bitmapInfo = CGImageAlphaInfo.PremultipliedFirst.rawValue | CGBitmapInfo.ByteOrder32Little.rawValue
        let width = CGImageGetWidth(imageRef)
        let height = CGImageGetHeight(imageRef)
        
        let context = CGBitmapContextCreate(nil,
            width,
            height,
            8, // bits per component
            width * 4, // Just always return width * 4 will be enough
            colorSpace, // System only supports RGB, set explicitly
            bitmapInfo)

        if context == nil {
            return nil
        }
        
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        CGContextDrawImage(context, rect, imageRef)
        
        if let decompressedImageRef = CGBitmapContextCreateImage(context) {
            return UIImage(CGImage: decompressedImageRef, scale: img!.scale, orientation: img!.imageOrientation)
        }
        return nil
    }
}