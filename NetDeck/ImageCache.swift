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
    static let hexTileLight = UIImage(named: "hex_background_light")!

    static let runnerPlaceholder = UIImage(named: "RunnerPlaceholder")!
    static let corpPlaceholder = UIImage(named: "CorpPlaceholder")!
    
    class func placeholder(for role: NRRole) -> UIImage {
        return role == .runner ? self.runnerPlaceholder : self.corpPlaceholder
    }

    static let width = 300
    static let height = 418
    
    fileprivate static let debugLog = false
    fileprivate static let secondsPerDay = 24 * 60 * 60
    fileprivate static let successInterval = TimeInterval(30 * secondsPerDay)
    fileprivate static let errorInterval = TimeInterval(1 * secondsPerDay)
    
    fileprivate let memCache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.name = "imgCache"
        return c
    }()
    
    // img keys we know aren't downloadable (yet)
    fileprivate var unavailableImages = Set<String>()
    
    // Last-Modified date of each image
    fileprivate var lastModifiedDates = [String: String]()  // code -> last-modified
    
    // when to next check if an img was updated
    fileprivate var nextCheckDates = [String: Date]()       // code -> date

    // log of all current in-flight requests
    typealias ImageCallback = (Card, UIImage, Bool) -> Void
    private var imagesInFlight = [String: [ImageCallback] ]()

    fileprivate override init() {
        super.init()
        
        let settings = UserDefaults.standard
        
        if let lastMod = settings.dictionary(forKey: SettingsKeys.LAST_MOD_CACHE) as? [String: String] {
            self.lastModifiedDates = lastMod
        }
        
        if let nextCheck = settings.dictionary(forKey: SettingsKeys.NEXT_CHECK) as? [String: Date] {
            self.nextCheckDates = nextCheck
        }
        
        if let imgs = settings.array(forKey: SettingsKeys.UNAVAILABLE_IMAGES) as? [String] {
            self.unavailableImages.formUnion(imgs)
        }
        
        let now = Date.timeIntervalSinceReferenceDate
        let lastCheck = settings.object(forKey: SettingsKeys.UNAVAIL_IMG_DATE) as? Double ?? now + 3600.0
        
        if lastCheck < now {
            unavailableImages.removeAll()
            settings.set(now + 48*3600, forKey:SettingsKeys.UNAVAIL_IMG_DATE)
            settings.set(Array(self.unavailableImages), forKey:SettingsKeys.UNAVAILABLE_IMAGES)
        }
        
        DispatchQueue.global(qos: .background).async {
            self.initializeMemCache()
        }
    }
    
    func saveData() {
        let settings = UserDefaults.standard
        
        settings.set(self.lastModifiedDates, forKey: SettingsKeys.LAST_MOD_CACHE)
        settings.set(self.nextCheckDates, forKey: SettingsKeys.NEXT_CHECK)
        settings.set(Array(self.unavailableImages), forKey: SettingsKeys.UNAVAILABLE_IMAGES)
        settings.synchronize()
    }
    
    func getImage(for card: Card, completion: @escaping (Card, UIImage, Bool) -> Void) {
        let key = card.code
        
        if let img = memCache.object(forKey: key as NSString) {
            completion(card, img, false)
            return
        }
        
        // if we know we don't (or can't) have an image, return a placeholder immediately
        if unavailableImages.contains(key) {
            completion(card, ImageCache.placeholder(for: card.role), true)
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            // get image from our on-disk cache
            if let img = self.decodedImage(for: key)
            {
                if Reachability.online {
                    self.checkForImageUpdate(for: card, key: key)
                }
                
                self.memCache.setObject(img, forKey: key as NSString)
                DispatchQueue.main.async {
                    completion(card, img, false)
                }
            }
            else
            {
                // image is not in on-disk cache
                if Reachability.online {
                    
                    // check if the request is currently in-flight, and if so, add its completion block to our list of callbacks
                    objc_sync_enter(self)
                    if self.imagesInFlight[key] != nil {
                        self.imagesInFlight[key]?.append(completion)
                        objc_sync_exit(self)
                        return
                    }
                    
                    // not in flight - store in list
                    self.imagesInFlight[key] = [completion]
                    objc_sync_exit(self)
                    self.downloadImage(for: card, key: key) { (card, image, placeholder) in
                        DispatchQueue.main.async {
                            // call all pending callbacks for this image
                            objc_sync_enter(self)
                            if let callbacks = self.imagesInFlight[key] {
                                for callback in callbacks {
                                    callback(card, image, placeholder)
                                }
                            } else {
                                assert(false, "no queue for \(key)")
                            }
                            self.imagesInFlight.removeValue(forKey: key)
                            objc_sync_exit(self)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(card, ImageCache.placeholder(for: card.role), true)
                    }
                }
            }
        }
    }
    
    func updateMissingImage(for card: Card, completion: @escaping (Bool) -> Void) {
        if let _ = self.getImage(for: card.code) {
            completion(true)
        } else {
            self.updateImage(for: card, completion: completion)
        }
    }
    
    func updateImage(for card: Card, completion: @escaping (Bool) -> Void) {
        guard Reachability.online else {
            completion(false)
            return
        }
        guard let url = URL(string: card.imageSrc) else {
            completion(false)
            return
        }
        
        let key = card.code
        
        var request = URLRequest(url:url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 10)
        let lastModDate = self.lastModifiedDates[key]
        if lastModDate != nil {
            request.setValue(lastModDate, forHTTPHeaderField: "If-Modified-Since")
        }
    
        Alamofire
            .request(request)
            .validate()
            .responseImage(imageScale: 1.0) { response in
                if let img = response.result.value {
                    let lastModified = response.response?.allHeaderFields["Last-Modified"] as? String
                    self.NLOG("up: GOT %@ If-Modified-Since %@: status 200", url.absoluteString, lastModified ?? "n/a");
                    self.storeInCache(img, lastModified: lastModified, key: key)
                    completion(true)
                } else {
                    self.NLOG("up: GOT %@ If-Modified-Since %@: status %ld", url.absoluteString, lastModDate ?? "n/a", response.response?.statusCode ?? 999)
                    completion(response.response?.statusCode == 304)
                }
            }
    }
    
    func imageAvailable(for card: Card) -> Bool {
        let key = card.code
        
        if let _ = self.memCache.object(forKey: key as NSString) {
            return true
        }
        
        // if we know we don't (or can't) have an image, return a placeholder immediately
        if self.unavailableImages.contains(key) {
            return false
        }
        
        let dir = self.directoryForImages()
        let file = dir.appendPathComponent(key)
        
        return FileManager.default.fileExists(atPath: file)
    }

    func croppedImage(_ image: UIImage, forCard card: Card) -> UIImage? {
        let key = "\(card.code):crop"
        
        if let cropped = self.memCache.object(forKey: key as NSString) {
            return cropped
        }
        
        let rect = CGRect(x: 10.0, y: card.cropY, width: 280.0, height: 209.0)
        if let imageRef = image.cgImage?.cropping(to: rect) {
            let cropped = UIImage(cgImage: imageRef)
            self.memCache.setObject(cropped, forKey:key as NSString)
            return cropped
        }
        return nil
    }
    
    func clearLastModifiedInfo() {
        let settings = UserDefaults.standard
        self.lastModifiedDates.removeAll()
        self.nextCheckDates.removeAll()
        settings.set(self.lastModifiedDates, forKey: SettingsKeys.LAST_MOD_CACHE)
        settings.set(self.nextCheckDates, forKey: SettingsKeys.NEXT_CHECK)
        
        self.memCache.removeAllObjects()
    }
    
    func clearCache() {
        self.clearLastModifiedInfo()
        
        self.unavailableImages.removeAll()
        let settings = UserDefaults.standard
        settings.set(Array(self.unavailableImages), forKey: SettingsKeys.UNAVAILABLE_IMAGES)
        
        self.removeCacheDirectory()
    }
    
    fileprivate func NLOG(_ format: String, _ args: CVarArg...) {
        if ImageCache.debugLog {
            let x = String(format: format, arguments: args)
            NSLog(x)
        }
    }
    
    fileprivate func storeInCache(_ img: UIImage, lastModified: String?, key: String) {
        var interval = ImageCache.successInterval
        if lastModified != nil {
            self.lastModifiedDates[key] = lastModified!
        } else {
            interval = ImageCache.errorInterval
        }
        
        self.nextCheckDates[key] = Date(timeIntervalSinceNow: interval)
        
        if !self.save(image: img, forKey: key) {
            self.lastModifiedDates.removeValue(forKey: key)
        }
    }
    
    fileprivate func save(image: UIImage, forKey key: String) -> Bool {
        let dir = self.directoryForImages()
        let file = dir.appendPathComponent(key)
        
        var img = image
        self.NLOG("save img for %@", key)
        if img.size.width > CGFloat(ImageCache.width) {
            // rescale image to 300x418 and save the scaled-down version
            if let newImg = self.scale(image: img, toSize: CGSize(width: ImageCache.width, height: ImageCache.height)) {
                img = newImg
            }
        }
        
        self.memCache.setObject(img, forKey: key as NSString)
        
        if let data = UIImagePNGRepresentation(img) {
            try? data.write(to: URL(fileURLWithPath: file), options: [.atomic])
            AppDelegate.excludeFromBackup(file)
            return true
        }
        return false
    }
    
    fileprivate func scale(image: UIImage, toSize size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        
        image.draw(in: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    fileprivate func removeCacheDirectory() {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths.first!
        
        let directory = supportDirectory.appendPathComponent(ImageCache.imagesDirectory)
        
        let _ = try? FileManager.default.removeItem(atPath: directory)
    }
    
    fileprivate func initializeMemCache() {
        // NSLog("start initMemCache")
        let dir = self.directoryForImages()
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir) else {
            return
        }
        
        for file in files {
            let imgFile = dir.appendPathComponent(file)
            
            if let imgData = try? Data(contentsOf: URL(fileURLWithPath: imgFile)) {
                if let img = self.decode(image: UIImage(data: imgData)) {
                    self.memCache.setObject(img, forKey: file as NSString)
                }
            }
        }
        // NSLog("end initMemCache")
    }
    
    fileprivate func getImage(for key: String) -> UIImage? {
        if let img = self.memCache.object(forKey: key as NSString) {
            return img
        }
        
        let img = self.decodedImage(for: key)
        if img != nil  {
            memCache.setObject(img!, forKey: key as NSString)
        }
        return img
    }
    
    fileprivate func decodedImage(for key: String) -> UIImage? {
        let dir = self.directoryForImages()
        let file = dir.appendPathComponent(key)
        
        var img: UIImage?
        if let imgData = try? Data(contentsOf: URL(fileURLWithPath: file)) {
            img = self.decode(image: UIImage(data: imgData))
        }
        
        let width = img?.size.width ?? 0.0
        if img == nil || width < CGFloat(ImageCache.width) {
            // image is broken - remove it
            img = nil
            let _ = try? FileManager.default.removeItem(atPath: file)
            self.lastModifiedDates.removeValue(forKey: key)
        }
        
        return img
    }
    
    fileprivate func checkForImageUpdate(for card: Card, key: String) {
        if let checkDate = self.nextCheckDates[key] {
            let now = Date()
            if now.timeIntervalSinceReferenceDate < checkDate.timeIntervalSinceReferenceDate {
                // no need to check
                return
            }
        }
        
        self.NLOG("check for %@", key)
        let url = URL(string: card.imageSrc)
        var request = URLRequest(url: url!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 10)
        let lastModDate = self.lastModifiedDates[key]
        if lastModDate != nil {
            request.setValue(lastModDate, forHTTPHeaderField: "If-Modified-Since")
        }
        
        self.NLOG("GET %@ If-Modified-Since %@", card.imageSrc, lastModDate ?? "n/a");
        Alamofire
            .request(request)
            .validate()
            .responseImage(imageScale: 1.0) { response in
                if let img = response.result.value {
                    self.NLOG("GOT %@ status 200", card.imageSrc)
                    let lastModified = response.response?.allHeaderFields["Last-Modified"] as? String
                    self.storeInCache(img, lastModified: lastModified, key: key)
                } else if response.response?.statusCode == 304 {
                    self.NLOG("GOT %@ status 304", card.imageSrc)
                    self.nextCheckDates[key] = Date(timeIntervalSinceNow: ImageCache.successInterval)
                } else {
                    self.NLOG("GOT %@ failure", card.imageSrc)
                    self.nextCheckDates[key] = Date(timeIntervalSinceNow: ImageCache.errorInterval)
                }
            }
    }
    
    fileprivate func downloadImage(for card: Card, key: String, completion: @escaping (Card, UIImage, Bool) -> Void) {
        let src = card.imageSrc
        Alamofire
            .request(src)
            .validate()
            .responseImage(imageScale: 1.0) { response in
                switch response.result {
                case .success:
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
                case .failure:
                    self.NLOG("dl: GET %@ for %@: error %ld", src, card.name, response.response?.statusCode ?? 999)
                    let img = ImageCache.placeholder(for: card.role)
                    completion(card, img, true)
                    self.unavailableImages.insert(key)
                    self.lastModifiedDates.removeValue(forKey: key)
                }
            }
    }
    
    fileprivate func directoryForImages() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths.first!
        
        let directory = supportDirectory.appendPathComponent(ImageCache.imagesDirectory)
        
        let fileMgr = FileManager.default
        if !fileMgr.fileExists(atPath: directory) {
            let _ = try? fileMgr.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        }
        
        return directory
    }
    
    fileprivate func decode(image: UIImage?) -> UIImage? {
        guard let img = image, let imgRef = img.cgImage else {
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let width = imgRef.width
        let height = imgRef.height
        if let context = CGContext(data: nil,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8, // bits per component
                                    bytesPerRow: width * 4, // Just always return width * 4 will be enough
                                    space: colorSpace, // System only supports RGB, set explicitly
                                    bitmapInfo: bitmapInfo) {

            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            context.draw(imgRef, in: rect)
        
            if let decompressedImageRef = context.makeImage() {
                return UIImage(cgImage: decompressedImageRef, scale: img.scale, orientation: img.imageOrientation)
            }
        }
        return nil
    }
}
