//
//  ImageCache.swift
//  NetDeck
//
//  Created by Gereon Steffens on 06.03.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Alamofire
import AlamofireImage
import SwiftyUserDefaults

private func synchronized<T>(_ lock: Any, closure: ()->T) -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return closure()
}

private class ImageMemCache {
    private var memory = [String: UIImage]()
    
    func set(_ img: UIImage, forKey key: String) {
        synchronized(self) {
            memory[key] = img
        }
    }
    
    func object(forKey key: String) -> UIImage? {
        return synchronized(self) {
            return memory[key]
        }
    }
    
    func removeAll() {
        synchronized(self) {
            memory.removeAll()
        }
    }
}

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
    
    static func placeholder(for role: Role) -> UIImage {
        return role == .runner ? self.runnerPlaceholder : self.corpPlaceholder
    }

    static let width: CGFloat = 300
    static let height: CGFloat = 418
    
    private static let debugLog = BuildConfig.debug && false
    private static let secondsPerDay = 24 * 60 * 60
    private static let successInterval = TimeInterval(30 * secondsPerDay)
    private static let errorInterval = TimeInterval(1 * secondsPerDay)
    
    private let memCache = ImageMemCache()
    
    // img keys we know aren't downloadable (yet)
    private var unavailableImages = Set<String>()
    
    // Last-Modified date of each image
    private var lastModifiedDates = [String: String]()  // code -> last-modified
    
    // when to next check if an img was updated
    private var nextCheckDates = [String: Date]()       // code -> date

    // log of all current in-flight requests
    typealias ImageCallback = (Card, UIImage, Bool) -> Void
    private var imagesInFlight = [String: [ImageCallback] ]()

    private override init() {
        super.init()
    
        if let lastMod = Defaults[.lastModifiedCache] {
            self.lastModifiedDates = lastMod
        }
        
        if let nextCheck = Defaults[.nextCheck] {
            self.nextCheckDates = nextCheck
        }
        
        if let imgs = Defaults[.unavailableImages] {
            self.unavailableImages.formUnion(imgs)
        }
        
        let now = Date.timeIntervalSinceReferenceDate
        let lastCheck = Defaults[.unavailableImagesDate] ?? now + 3600.0
        
        if lastCheck < now {
            self.unavailableImages.removeAll()
            Defaults[.unavailableImagesDate] = now + 48 * 3600
            Defaults[.unavailableImages] = Array(self.unavailableImages)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.clearMemoryCache(_:)), name: Notification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
    }
    
    /// called when we move to the background
    func resignActive() {
        Defaults[.lastModifiedCache] = self.lastModifiedDates
        Defaults[.nextCheck] = self.nextCheckDates
        Defaults[.unavailableImages] = Array(self.unavailableImages)
        
        self.memCache.removeAll()
    }
    
    func clearMemoryCache(_ notification: Notification) {
        self.memCache.removeAll()
    }
    
    func getImage(for card: Card, completion: @escaping (Card, UIImage, Bool) -> Void) {
        // uncomment to fake "no image available" for all cards
//        if true {
//            completion(card, ImageCache.placeholder(for: card.role), true)
//            return
//        }
        
        let key = card.code
        if let img = memCache.object(forKey: key) {
            completion(card, img, false)
            if Reachability.online {
                self.checkForImageUpdate(for: card, key: key)
            }
            return
        }
        
        // if we know we don't (or can't) have an image, return a placeholder immediately
        if unavailableImages.contains(key) {
            completion(card, ImageCache.placeholder(for: card.role), true)
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            // get image from our on-disk cache
            if let img = self.decodedImage(for: key) {
                if Reachability.online {
                    self.checkForImageUpdate(for: card, key: key)
                }
                
                self.memCache.set(img, forKey: key)
                DispatchQueue.main.async {
                    completion(card, img, false)
                }
            } else {
                // image is not in on-disk cache
                if Reachability.online {
                    
                    let requestInFlight: Bool = synchronized(self) {
                        // check if the request is currently in-flight, and if so, add its completion block to our list of callbacks
                        if self.imagesInFlight[key] != nil {
                            self.imagesInFlight[key]?.append(completion)
                            return true
                        } else {
                            // not in flight - store in list
                            self.imagesInFlight[key] = [completion]
                            return false
                        }
                    }
                    if requestInFlight {
                        return
                    }
                    
                    self.downloadImage(for: card, key: key) { (card, image, placeholder) in
                        DispatchQueue.main.async {
                            // call all pending callbacks for this image
                            synchronized(self) {
                                if let callbacks = self.imagesInFlight[key] {
                                    for callback in callbacks {
                                        callback(card, image, placeholder)
                                    }
                                } else {
                                    assert(false, "no queue for \(key)")
                                }
                                self.imagesInFlight.removeValue(forKey: key)
                            }
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
                    self.NLOG("up: GOT %@ If-Modified-Since %@: status 200", url.absoluteString, lastModified ?? "n/a")
                    self.storeInCache(img, lastModified: lastModified, key: key)
                    completion(true)
                } else {
                    self.NLOG("up: GOT %@ If-Modified-Since %@: status %ld", url.absoluteString, lastModDate ?? "n/a", response.response?.statusCode ?? 999)
                    completion(response.response?.statusCode == 304)
                    if response.response?.statusCode != 304 {
                        self.unavailableImages.insert(card.code)
                    }
                }
            }
    }
    
    func imageAvailable(for card: Card) -> Bool {
        let key = card.code
        
        if let _ = self.memCache.object(forKey: key) {
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
        
        if let cropped = self.memCache.object(forKey: key) {
            return cropped
        }
        
        let rect = CGRect(x: 10.0, y: card.cropY, width: 280.0, height: 209.0)
        if let imageRef = image.cgImage?.cropping(to: rect) {
            let cropped = UIImage(cgImage: imageRef)
            self.memCache.set(cropped, forKey:key)
            return cropped
        }
        return nil
    }
    
    func clearCache() {
        self.lastModifiedDates.removeAll()
        self.nextCheckDates.removeAll()
        self.unavailableImages.removeAll()
        
        Defaults[.lastModifiedCache] = self.lastModifiedDates
        Defaults[.nextCheck] = self.nextCheckDates
        Defaults[.unavailableImages] = Array(self.unavailableImages)
        
        self.removeCacheDirectory()
        self.memCache.removeAll()
    }
    
    private func NLOG(_ format: String, _ args: CVarArg...) {
        if ImageCache.debugLog {
            let x = String(format: format, arguments: args)
            NSLog(x)
        }
    }
    
    private func storeInCache(_ img: UIImage, lastModified: String?, key: String) {
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
    
    private func save(image: UIImage, forKey key: String) -> Bool {
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
        
        self.memCache.set(img, forKey: key)
        
        if let data = UIImagePNGRepresentation(img) {
            try? data.write(to: URL(fileURLWithPath: file), options: [.atomic])
            AppDelegate.excludeFromBackup(file)
            return true
        }
        return false
    }
    
    private func scale(image: UIImage, toSize size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        
        image.draw(in: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    private func removeCacheDirectory() {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths.first!
        
        let directory = supportDirectory.appendPathComponent(ImageCache.imagesDirectory)
        
        let _ = try? FileManager.default.removeItem(atPath: directory)
    }
    
    private func getImage(for key: String) -> UIImage? {
        if let img = self.memCache.object(forKey: key) {
            return img
        }
        
        let img = self.decodedImage(for: key)
        if img != nil {
            memCache.set(img!, forKey: key)
        }
        return img
    }
    
    private func decodedImage(for key: String) -> UIImage? {
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
    
    private func checkForImageUpdate(for card: Card, key: String) {
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
        
        self.NLOG("GET %@ If-Modified-Since %@", card.imageSrc, lastModDate ?? "n/a")
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
    
    private func downloadImage(for card: Card, key: String, completion: @escaping (Card, UIImage, Bool) -> Void) {
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
    
    private func directoryForImages() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths.first!
        
        let directory = supportDirectory.appendPathComponent(ImageCache.imagesDirectory)
        
        let fileMgr = FileManager.default
        if !fileMgr.fileExists(atPath: directory) {
            let _ = try? fileMgr.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        }
        
        return directory
    }
    
    private func decode(image: UIImage?) -> UIImage? {
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
